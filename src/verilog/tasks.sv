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

      // ob_mem_data_i       = '0;
      // ib_mem_data_i       = '0;
      // wb_mem_data_i       = '0;
      // ps_mem_data_i       = '0;

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
      mem_trans output_trans;

      input_trans = new("input_trans");
      weight_trans = new("weight_trans");

      input_trans.read_mem_file("inputs/systolic_in_2_input.hex");
      weight_trans.read_mem_file("inputs/systolic_in_2_weight.hex");

      reset_signals();
      // clear up only for 1 cycle
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
      w_rows_i             = ROW;
      w_cols_i             = COL;
      i_rows_i             = ROW;
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
      ext_en_i             <= '1;
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
         forever @(negedge clk_i) begin
            if (ext_valid_o)
               $display("@%0t: ext_result_o = %x", $realtime, ext_result_o);
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
      ext_en_i <= '0;
      ext_valid_en_i <= '0;
   end
endtask

task memory_mode();
   begin
      reset_signals();
      // clear up only for 1 cycle
      @(posedge clk_i);

      // SET CONTROL SIGNALS

      // back to normal state
      rstn_async_i = '1;
      // wait 2 more cycles for async_nreset_synchronizer to correctly sample
      // when rstn_async_i is asserted as high
      repeat(2) @(posedge clk_i);

      // LOAD MEMORIES

      @(negedge clk_i);
      start_i  = '1;
      @(negedge clk_i);
      start_i  = '0;
      @(posedge done_o);

      // COMPARE RESULTS

    end
endtask

task bist_mode();
   begin
      reset_signals();
      // clear up only for 1 cycle
      @(posedge clk_i);

      // SET CONTROL SIGNALS

      rstn_async_i =  1'b1;
      // wait 2 more cycles for async_nreset_synchronizer to correctly sample
      // when rstn_async_i is asserted as high
      repeat(2) @(posedge clk_i);

      // LOAD WEIGHT BUFFERS WITH EXTERNAL MODE

      rstn_async_i =  1'b0;
      // clear up only for 1 cycle
      @(posedge clk_i);

      // SET CONTROL SIGNALS
      // SET STOP CODE
      
      rstn_async_i =  1'b1;
      // wait 2 more cycles for async_nreset_synchronizer to correctly sample
      // when rstn_async_i is asserted as high
      repeat(2) @(posedge clk_i);

      // CHECK RESULTS

    end
endtask
