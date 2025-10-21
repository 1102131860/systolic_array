class mem_trans;
   rand bit [COL*WIDTH-1:0] data[$];         // store memory data
   string name;                              // memory transaction's name

   // Constructor
   function new(string mem_name="");
      name = mem_name;
   endfunction

   // read data from file
   function void read_mem_file(string file_path);
      int fd;
      bit [COL*WIDTH-1:0] tmp;
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

      ext_en_i            = '0;
      ext_input_i         = '0;
      ext_weight_i        = '0;
      ext_psum_i          = '0;
      ext_valid_en_i      = '0;
      ext_weight_en_i     = '0;
   
      bypass_i            = '1;
      mode_i              = '1;
      driver_valid_i      = '0;
      driver_stop_code_i  = '0;
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

      input_trans.read_mem_file("inputs/systolic_in_2_input.hex");
      weight_trans.read_mem_file("inputs/systolic_in_2_weight.hex");

      reset_signals();
      @(posedge clk_i);

      // SET CONTROL SIGNALS
      // mode_i[0]: Driver should be 1, External Input
      // mode_i[1]: Mointor shoule be 1, Direct Output
      // bypass_i[0]: drive_bypass_w should be 1 (bypass)
      // bypass_i[1]: dut_bypass_w should be 0 (not bypass)
      // bypass_i[2]: sa_bypass_w should be 1 (bypass)
      mode_i               = 2'b11;
      bypass_i             = 3'b101;
      driver_valid_i       = '0;
      driver_stop_code_i   = '0;

      start_i              = '0;
      en_i                 = '1;
      w_rows_i             = ROW - 1;
      w_cols_i             = COL - 1;
      i_rows_i             = w_rows_i;
      w_offset             = '0;
      i_offset             = '0;
      psum_offset_r        = '0;
      o_offset_w           = '0;
      accum_enb_i          = '0;

      // back to normal state
      rstn_async_i = '1;
      // wait 2 more cycles for async_nreset_synchronizer to correctly sample
      // when rstn_async_i is asserted as high
      repeat(2) @(posedge clk_i);
      
      // Assert ext_en_i
      ext_en_i              = '1;

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
   end
endtask

task memory_mode();
   begin
      mem_trans input_trans;
      mem_trans weight_trans;

      input_trans = new("input_trans");
      weight_trans = new("weight_trans");

      input_trans.read_mem_file("inputs/systolic_in_1_input.hex");
      weight_trans.read_mem_file("inputs/systolic_in_1_weight.hex");

      reset_signals();
      @(posedge clk_i);

      ///////////////////////////////////////////
      // SET CONTROL SIGNALS
      ///////////////////////////////////////////
      w_rows_i            = ROW - 1;
      w_cols_i            = COL - 1;
      i_rows_i            = w_rows_i;
      w_offset            = '0;
      i_offset            = '0;
      psum_offset_r       = '0;
      o_offset_w          = '0;
      accum_enb_i         = '0;

      // back to normal state
      rstn_async_i        = '1;
      repeat(2) @(posedge clk_i);

      ///////////////////////////////////////////
      // LOAD MEMORIES
      ///////////////////////////////////////////
      // enable external mode to load input and weight
      ext_en_i            = '1;
      foreach(input_trans.data[i]) begin
         ib_mem_cenb_ext_i <= '0;
         ib_mem_wenb_ext_i <= '0;
         ib_mem_addr_ext_i <= i;
         ib_mem_d_i_r      <= input_trans.data[i];
         @(posedge clk_i);
      end
      // not select ib_mem any more
      ib_mem_cenb_ext_i   = '1;
      foreach(weight_trans.data[i]) begin
         wb_mem_cenb_ext_i <= '0;
         wb_mem_wenb_ext_i <= '0;
         wb_mem_addr_ext_i <= i;
         wb_mem_d_i_r      <= weight_trans.data[i];
         @(posedge clk_i);
      end
      // not select wb_mem any more
      wb_mem_cenb_ext_i   = '1;
      // clear up output memory with O_SIZE data as well
      foreach(input_trans.data[i]) begin
         ob_mem_cenb_ext_i <= '0;
         ob_mem_wenb_ext_i <= '0;
         ob_mem_addr_ext_i <= i;
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
         $write("%x ", ib_mem.data[i]);
      $display("");
      $write("@%0t: wb_mem.data: ", $realtime);
      foreach(weight_trans.data[i])
         $write("%x ", wb_mem.data[i]);
      $display("");
      $write("@%0t: ob_mem.data: ", $realtime);
      foreach(input_trans.data[i])
         $write("%x ", ob_mem.data[i]);
      $display("");

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
      foreach(input_trans.data[i])
         $write("%x ", ob_mem.data[i]);
      $display("");
      $writememh(f, ob_mem.data);
   end
endtask

task bist_mode();
   begin
      mem_trans weight_trans;
      weight_trans = new("weight_trans");
      weight_trans.read_mem_file("inputs/systolic_in_1_weight.hex");

      // Clear all the signals
      reset_signals();
      @(posedge clk_i);

      ///////////////////////////////////////////
      // SET CONTROL SIGNALS
      ///////////////////////////////////////////
      driver_valid_i       = '0;
      // set lsfr stop code here
      driver_stop_code_i   = 64'h0000000123456789;
      // set lsfr and signature analyzer seeds here
      {ext_input_i, ext_psum_i} = 64'h7865342144441234;
      mode_i               = 2'b11;
      bypass_i             = 3'b101;
      
      // data configuration
      start_i              = '0;
      en_i                 = '1;
      w_rows_i             = ROW - 1;
      w_cols_i             = COL - 1;
      i_rows_i             = w_rows_i;
      w_offset             = '0;
      i_offset             = '0;
      psum_offset_r        = '0;
      o_offset_w           = '0;
      accum_enb_i          = '0;
      
      // reset to set lsfr and signature analyzer's stop code and seeds
      rstn_async_i         = 1'b0;
      // clear signals for 1 cycle
      @(posedge clk_i);
      // back to noraml state by asserting rstn_async_i
      rstn_async_i         =  1'b1;
      // wait 2 cycles for the asynchronous reset synchronizer sample
      repeat(2) @(posedge clk_i);

      ///////////////////////////////////////////
      // LOAD WEIGHT BUFFERS WITH EXTERNAL MODE
      ///////////////////////////////////////////
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
      bypass_i             = 3'b000;
      mode_i               = 2'b00;
      driver_valid_i       = '1;
      // enable input activation as well
      ext_valid_en_i       = '1;
      
      ///////////////////////////////////////////
      // COMPARE RESULTS
      ///////////////////////////////////////////
      fork
         forever @(posedge clk_i) begin
            if (ext_valid_o) begin
               $display("@%0t: ext_valid_o is asserted, ext_result_o = %x", $realtime, ext_result_o);
               $fwrite(f, "%x\n", ext_result_o);
            end
            if (matrix_mult_0.sa_dut_valid_w) begin
               $display("@%0t: matrix_mult_0.sa_dut_valid_w is asserted, ext_result_o = %x", $realtime, ext_result_o);
            end
         end
      join_none
   end
endtask
