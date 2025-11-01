class mem_trans;
   rand bit [WEIGHT_DATA_WIDTH-1:0] data[$]; // store memory data
   string name;                              // memory transaction's name

   // Constructor
   function new(string mem_name="");
      name = mem_name;
   endfunction

   // read data from file
   function void read_mem_file(string file_path);
      int fd;
      bit [WEIGHT_DATA_WIDTH-1:0] tmp;
      string line;

      fd = $fopen(file_path, "r");
      if (fd == 0)
         $fatal("@%0t, Cannot open memory file: %s", $realtime, file_path);

      // clear data
      data.delete();
      while (!$feof(fd)) begin
         void'($fgets(line, fd));
         if (line != "") begin
            $sscanf(line, "%x", tmp);
            data.push_back(tmp);
         end
      end
      $fclose(fd);
      display();
   endfunction

   // Print
   function void display();
      $write("@%0t: mem %s: ", $realtime, name);
      foreach(data[i]) $write("%x ", data[i]);
      $display("");
   endfunction
endclass

task initialize_signals();
   begin
      #OFFSET;
      rstn_async_i        = 1'b0;
      start_i             = '0;
      en_i                = '1;
      w_rows_i            = '0;
      w_cols_i            = '0;
      i_rows_i            = '0;
      w_offset            = '0;
      i_offset            = '0;
      psum_offset_r       = '0;
      o_offset_w          = '0;
      accum_enb_i         = '0;
      extra_config_i      = '0;

      bypass_i            = '1;
      mode_i              = '1;
      driver_valid_i      = '0;
      driver_stop_code_i  = '0;

      // avoid setup/hold violation for ext_result_o_reg
      #OFFSET;
      ext_en_i            = '0;
      ext_input_i         = '0;
      ext_weight_i        = '0;
      ext_psum_i          = '0;
      ext_valid_en_i      = '0;
      ext_weight_en_i     = '0;
   end
endtask

task reset_signals();
   begin
      repeat (10) @(posedge clk_i);
      initialize_signals();
   end
endtask

task external_mode();
   begin
      mem_trans input_trans;
      mem_trans weight_trans;

      input_trans = new("input_trans");
      weight_trans = new("weight_trans");

      input_trans.read_mem_file("inputs/INPUTS.txt");
      weight_trans.read_mem_file("inputs/WEIGHTS.txt");

      fork
         // wb_data_muxed: %x, \
         // sys_array.north_i[0:3]: %x%x%x%x, \   
         // ib_data_muxed: %x, \
         // sys_array.west_i[0:3]: %x%x%x%x, \
         // matrix_mult_wrapper_0.matrix_mult_group3.wb_data_muxed,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_3__u_pe.north_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_2__u_pe.north_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_1__u_pe.north_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_0__u_pe.north_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.ib_data_muxed,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_3__sys_COL_0__u_pe.west_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_2__sys_COL_0__u_pe.west_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_1__sys_COL_0__u_pe.west_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_0__u_pe.west_i,
         $fmonitor(f, "@%0t: wb_data_muxed: %x, \
            ctrl_load_muxed: %x, \
            ib_data_muxed: %x, \
            ctrl_sum_out_muxed: %x, \
            sys_array.south_o: %x, \
            ext_result_o: %x",
            $realtime,
            matrix_mult_wrapper_0.matrix_mult_group3.wb_data_muxed,
            matrix_mult_wrapper_0.matrix_mult_group3.ctrl_load_muxed,
            matrix_mult_wrapper_0.matrix_mult_group3.ib_data_muxed,
            matrix_mult_wrapper_0.matrix_mult_group3.ctrl_sum_out_muxed,
            matrix_mult_wrapper_0.matrix_mult_group3.sys_array.south_o,
            matrix_mult_wrapper_0.matrix_mult_group3.ext_result_o
         );
      join_none

      reset_signals();
      @(posedge clk_i);

      // back to normal state
      rstn_async_i         = '1;
      // wait 2 more cycles for async_nreset_synchronizer to correctly sample
      // when rstn_async_i is asserted as high
      repeat(2) @(posedge clk_i);
      
      // SET CONTROL SIGNALS
      // mode_i[0]: Driver should be 1, External Input
      // mode_i[1]: Mointor shoule be 1, Direct Output
      // bypass_i[0]: drive_bypass_w should be 1 (bypass)
      // bypass_i[1]: dut_bypass_w should be 0 (not bypass)
      // bypass_i[2]: sa_bypass_w should be 1 (bypass)
      mode_i               = 2'b11;
      bypass_i             = 3'b101;
      // Assert ext_en_i
      ext_en_i             = '1;

      // LOAD WEIGHTS
      foreach(weight_trans.data[i]) begin
         ext_input_i       <= '0;
         ext_weight_i      <= weight_trans.data[i];
         ext_valid_en_i    <= '0;
         ext_weight_en_i   <= '1;
         ext_psum_i        <= '0;
         @(posedge clk_i);
      end

      // COMPARE RESULTS
      fork
         forever @(posedge clk_i) begin
            // avoid 1 more cycle sampling
            #OFFSET;
            if (ext_valid_o) begin
               $display("@%0t: ext_result_o = %x", $realtime, ext_result_o);
               $fwrite(f, "%x\n", ext_result_o);
            end
         end
      join_none

      // STREAM INPUTS AND PARTIAL SUMS
      foreach(input_trans.data[i]) begin
         ext_input_i       <= input_trans.data[i];
         ext_weight_i      <= '0;
         ext_valid_en_i    <= '1;
         ext_weight_en_i   <= '0;
         ext_psum_i        <= '0;
         @(posedge clk_i);
      end
      // extra cycles for pipeline flush
      repeat (ROW) begin
         ext_input_i       <= '0;
         ext_weight_i      <= '0;
         ext_valid_en_i    <= '1;
         ext_weight_en_i   <= '0;
         ext_psum_i        <= '0;
         @(posedge clk_i);
      end

      // Deassert ext_en_i
      ext_en_i = '0;
      ext_valid_en_i = '0;
      disable fork;
   end
endtask

task memory_mode(input bit en_output_sat=0);
   begin
      mem_trans input_trans;
      mem_trans weight_trans;
      int w_rows_int, w_cols_int, i_rows_int, w_offset_int, i_offset_int, o_offset_int;

      input_trans = new("input_trans");
      weight_trans = new("weight_trans");
      input_trans.read_mem_file("inputs/INPUTS.txt");
      weight_trans.read_mem_file("inputs/WEIGHTS.txt");

      w_rows_int = weight_trans.data.size();
      w_cols_int = COL;
      i_rows_int = input_trans.data.size();
      w_offset_int = $urandom_range(W_SIZE - w_rows_i - 1);
      i_offset_int = $urandom_range(I_SIZE - i_rows_i - 1);
      o_offset_int = $urandom_range(O_SIZE - i_rows_i - 1);

      fork
         // wb_data_muxed: %x, \
         // sys_array.north_i[0:3]: %x%x%x%x, \
         // ib_data_muxed: %x, \
         // sys_array.west_i[0:3]: %x%x%x%x, \
         // sys_ctrl.ctrl_ps_in_o: %x, \
         // sys_ctrl.ctrl_ps_valid_o: %x, \
         // sys_array[0][0:3]: %x%x%x%x,
         // matrix_mult_wrapper_0.matrix_mult_group3.wb_data_muxed,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_3__u_pe.north_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_2__u_pe.north_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_1__u_pe.north_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_0__u_pe.north_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.ib_data_muxed,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_3__sys_COL_0__u_pe.west_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_2__sys_COL_0__u_pe.west_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_1__sys_COL_0__u_pe.west_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_0__u_pe.west_i,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_ctrl.ctrl_ps_in_o,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_ctrl.ctrl_ps_valid_o,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_3__u_pe.weight_o,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_2__u_pe.weight_o,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_1__u_pe.weight_o,
         // matrix_mult_wrapper_0.matrix_mult_group3.sys_array.sys_ROW_0__sys_COL_0__u_pe.weight_o
         $fmonitor(f, "@%0t: wb_mem_data_i: %x, \
            ib_mem_data_i: %x, \
            sys_ctrl.ctrl_load_o: %x, \
            sys_ctrl.ctrl_sum_out_o: %x, \
            sys_array.south_o: %x, \
            ob_mem_data_o: %x, \
            ob_mem_cenb_o: %x, \
            done_o: %x",
            $realtime,
            matrix_mult_wrapper_0.matrix_mult_group3.wb_mem_data_i,
            matrix_mult_wrapper_0.matrix_mult_group3.ib_mem_data_i,
            matrix_mult_wrapper_0.matrix_mult_group3.sys_ctrl.ctrl_load_o,
            matrix_mult_wrapper_0.matrix_mult_group3.sys_ctrl.ctrl_sum_out_o,
            matrix_mult_wrapper_0.matrix_mult_group3.sys_array.south_o,
            matrix_mult_wrapper_0.matrix_mult_group3.ob_mem_data_o,
            matrix_mult_wrapper_0.matrix_mult_group3.ob_mem_cenb_o,
            matrix_mult_wrapper_0.matrix_mult_group3.done_o
         );
      join_none

      reset_signals();
      @(posedge clk_i);

      // back to normal state
      rstn_async_i        = '1;
      repeat(2) @(posedge clk_i);

      ///////////////////////////////////////////
      // LOAD MEMORIES
      ///////////////////////////////////////////
      // enable external mode to load input and weight
      ext_en_i            = '1;
      for (int i = 0; i < i_rows_int; i++) begin
         ib_mem_cenb_ext_i <= '0;
         ib_mem_wenb_ext_i <= '0;
         ib_mem_addr_ext_i <= i + i_offset_int;
         ib_mem_d_i_r      <= input_trans.data[i];
         @(posedge clk_i);
      end
      // not select ib_mem any more
      ib_mem_cenb_ext_i   = '1;
      for (int i = 0; i < w_rows_int; i++) begin
         wb_mem_cenb_ext_i <= '0;
         wb_mem_wenb_ext_i <= '0;
         wb_mem_addr_ext_i <= i + w_offset_int;
         wb_mem_d_i_r      <= weight_trans.data[i];
         @(posedge clk_i);
      end
      // not select wb_mem any more
      wb_mem_cenb_ext_i   = '1;
      // clear up output memory with O_SIZE data as well
      if (en_output_sat)
         for (int i = 0; i < ROW; i++) begin
            ob_mem_cenb_ext_i <= '0;
            ob_mem_wenb_ext_i <= '0;
            ob_mem_addr_ext_i <= i + o_offset_int;
            ob_mem_d_i_ext_i  <= '0;
            @(posedge clk_i);
         end
      else
         for (int i = 0; i < i_rows_int; i++) begin
            ob_mem_cenb_ext_i <= '0;
            ob_mem_wenb_ext_i <= '0;
            ob_mem_addr_ext_i <= i + o_offset_int;
            ob_mem_d_i_ext_i  <= '0;
            @(posedge clk_i);
         end
      // not select ob_mem any more
      ob_mem_cenb_ext_i   = '1;
      // exits external mode
      ext_en_i            = '0;
      @(posedge clk_i);

      // display initialized memory
      $display("==========Initial Memory==========");
      $write("@%0t: ib_mem.data: ", $realtime);
      foreach(input_trans.data[i])
         $write("%0d: %x ", i + i_offset_int, ib_mem.data[i + i_offset_int]);
      $display("");
      $write("@%0t: wb_mem.data: ", $realtime);
      foreach(weight_trans.data[i])
         $write("%0d: %x ", i + w_offset_int, wb_mem.data[i + w_offset_int]);
      $display("");
      $write("@%0t: ob_mem.data: ", $realtime);
      if (en_output_sat)
         for (int i = 0; i < ROW; i++)
            $write("%0d: %x ", i + o_offset_int, ob_mem.data[i + o_offset_int]);
      else
         foreach(input_trans.data[i])
            $write("%0d: %x ", i + o_offset_int, ob_mem.data[i + o_offset_int]);
      $display("");

      ///////////////////////////////////////////
      // SET CONTROL SIGNALS just before start_i (not in rst_n)
      ///////////////////////////////////////////
      // data config
      w_rows_i            = w_rows_int;
      w_cols_i            = w_cols_int;
      i_rows_i            = i_rows_int;
      w_offset            = w_offset_int;
      i_offset            = i_offset_int;
      o_offset_w          = o_offset_int;
      psum_offset_r       = '0;
      accum_enb_i         = '0;
      extra_config_i[0]   = en_output_sat; // weight stationary mode (0) or output stationary mode(1)

      ///////////////////////////////////////////
      // Start Computing
      ///////////////////////////////////////////
      $display("==========Start Computing==========");
      @(negedge clk_i);
      start_i  = '1;
      @(negedge clk_i);
      start_i  = '0;
      // wait for done_o to be high
      @(posedge done_o);

      ///////////////////////////////////////////
      // COMPARE RESULTS
      ///////////////////////////////////////////
      $display("==========Computation Finished==========");
      $write("@%0t: ob_mem.data: ", $realtime);
      if (en_output_sat)
         for (int i = 0; i < ROW; i++) begin
            $write("%0d: %x ", i + o_offset_int, ob_mem.data[i + o_offset_int]);
            $fwrite(f, "%x\n", ob_mem.data[i + o_offset_int]);
         end
      else
         foreach(input_trans.data[i]) begin
            $write("%0d: %x ", i + o_offset_int, ob_mem.data[i + o_offset_int]);
            $fwrite(f, "%x\n", ob_mem.data[i + o_offset_int]);
         end
      $display("");
   end
endtask

task bist_mode();
   begin
      mem_trans weight_trans;
      weight_trans = new("weight_trans");
      weight_trans.read_mem_file("inputs/WEIGHTS.txt");

      // Clear all the signals
      reset_signals();
      @(posedge clk_i);

      ///////////////////////////////////////////
      // SET CONTROL SIGNALS
      ///////////////////////////////////////////
      // mode_i[0]: Driver should be 1, External Input
      // mode_i[1]: Mointor shoule be 1, Direct Output
      // bypass_i[0]: drive_bypass_w should be 1 (bypass)
      // bypass_i[1]: dut_bypass_w should be 0 (not bypass)
      // bypass_i[2]: sa_bypass_w should be 1 (bypass)
      mode_i               = 2'b11;
      bypass_i             = 3'b101;
      driver_valid_i       = '0;
      // set lsfr stop code here
      driver_stop_code_i   = 64'h6534214444123481;
      // set lsfr and signature analyzer seeds here
      {ext_input_i, ext_psum_i} = 64'h7865342144441234;

      // clear signals for 1 cycle
      @(posedge clk_i);
      // back to noraml state by asserting rstn_async_i
      rstn_async_i         =  1'b1;
      // wait 2 cycles for the asynchronous reset synchronizer sample
      repeat(2) @(posedge clk_i);

      ///////////////////////////////////////////
      // LOAD WEIGHT BUFFERS WITH EXTERNAL MODE
      ///////////////////////////////////////////
      // keep on external mode
      ext_en_i             = '1;
      // LOAD WEIGHTS
      foreach(weight_trans.data[i]) begin
         ext_input_i       <= '0;
         ext_weight_i      <= weight_trans.data[i];
         ext_valid_en_i    <= '0;
         ext_weight_en_i   <= '1;
         ext_psum_i        <= '0;
         @(posedge clk_i);
      end
      ext_weight_en_i      = '0;
      ext_weight_i         = '0;

      ///////////////////////////////////////////
      // STREAM INPUTS AND PARTIAL SUMS
      ///////////////////////////////////////////
      // set LSFR and Signature Analyzer Mode
      // mode_i[0]: Driver should be 0, LSFR 
      // mode_i[1]: Mointor shoule be 0, Signature Analyzer
      // bypass_i[0]: drive_bypass_w should be 0 (not bypass)
      // bypass_i[1]: dut_bypass_w should be 0 (not bypass)
      // bypass_i[2]: sa_bypass_w should be 0 (not bypass)
      mode_i               = 2'b00;
      bypass_i             = 3'b000;
      driver_valid_i       = '1;
      // enable input activation as well
      ext_valid_en_i       = '1;

      ///////////////////////////////////////////
      // COMPARE RESULTS
      ///////////////////////////////////////////
      fork
         forever @(posedge clk_i) begin
            if (!ext_valid_o && matrix_mult_wrapper_0.driver_valid_o_w)
               $display("@%0t: tracking driver_data_w = %x", $realtime, matrix_mult_wrapper_0.driver_data_w);
         end
      join_none;

      @(posedge ext_valid_o);
      $display("@%0t: ext_valid_o is asserted, ext_result_o = %x", $realtime, ext_result_o);
      $fwrite(f, "%x\n", ext_result_o);
      disable fork;
   end
endtask

task run_all();
   $display("@%0t===============Memory Mode==================", $realtime);
   memory_mode();

   $display("@%0t===============External Mode==================", $realtime);
   external_mode();

   $display("@%0t===============BiST Mode==================", $realtime);
   bist_mode();
endtask