module tb_matrix_mult_wrapper;

   parameter real CLOCK_PERIOD   = 10;  // the highest clk frequency, 143MHz (7ns) for wc; 500MHz (2ns) for bc
   parameter real DUTY_CYCLE     = 0.5;
   parameter real OFFSET         = 2.5;
   parameter real MEM_DELAY      = 1.00;

   localparam WIDTH              = matrix_mult_pkg::WIDTH;
   localparam ROW                = matrix_mult_pkg::ROW;
   localparam COL                = matrix_mult_pkg::COL;
   localparam W_SIZE             = matrix_mult_pkg::W_SIZE;
   localparam I_SIZE             = matrix_mult_pkg::I_SIZE;
   localparam O_SIZE             = matrix_mult_pkg::O_SIZE;
   localparam DRIVER_WIDTH       = matrix_mult_pkg::DRIVER_WIDTH;

   localparam MAX_ROW            = matrix_mult_pkg::MAX_ROW;
   localparam MAX_COL            = matrix_mult_pkg::MAX_COL;
   localparam EXTRA_BITS         = matrix_mult_pkg::EXTRA_BITS;

   localparam INPUT_DATA_WIDTH   = matrix_mult_pkg::INPUT_DATA_WIDTH;
   localparam WEIGHT_DATA_WIDTH  = matrix_mult_pkg::WEIGHT_DATA_WIDTH;

   supply1 VDD;
   supply0 VSS;

   logic                         clk_i;
   logic                         rstn_async_i;
   logic                         start_i;
   logic                         en_i;                               // gate clocking enable, active high

   // test config
   logic [2:0]                   bypass_i;
   logic [1:0]                   mode_i;
   logic                         driver_valid_i;
   logic [DRIVER_WIDTH-1:0]      driver_stop_code_i;
   test_config_struct            test_config_i;

   // data config
   logic [$clog2(MAX_ROW)-1:0]   w_rows_i;
   logic [$clog2(MAX_COL)-1:0]   w_cols_i;
   logic [$clog2(I_SIZE)-1:0]    i_rows_i;
   logic [$clog2(W_SIZE)-1:0]    w_offset;
   logic [$clog2(I_SIZE)-1:0]    i_offset;
   logic [$clog2(O_SIZE)-1:0]    psum_offset_r;
   logic [$clog2(O_SIZE)-1:0]    o_offset_w;
   logic                         accum_enb_i;
   logic [EXTRA_BITS-1:0]        extra_config_i;                     // extra configuration bits for grad students
   data_config_struct            data_config_i;

   // output buffer memory
   logic                         ob_mem_cenb_o;
   logic                         ob_mem_wenb_o;
   logic [$clog2(O_SIZE)-1:0]    ob_mem_addr_o;
   logic [COL-1:0][WIDTH-1:0]    ob_mem_data_i;
   logic [COL-1:0][WIDTH-1:0]    ob_mem_data_o;
   // input buffer memory
   logic                         ib_mem_cenb_o;
   logic                         ib_mem_wenb_o;
   logic [$clog2(I_SIZE)-1:0]    ib_mem_addr_o;
   logic [ROW-1:0][WIDTH-1:0]    ib_mem_data_i;
   // weights buffer memory
   logic                         wb_mem_cenb_o;
   logic                         wb_mem_wenb_o;
   logic [$clog2(W_SIZE)-1:0]    wb_mem_addr_o;
   logic [COL-1:0][WIDTH-1:0]    wb_mem_data_i;
   // partial sum buffer memory
   logic                         ps_mem_cenb_o;
   logic                         ps_mem_wenb_o;
   logic [$clog2(W_SIZE)-1:0]    ps_mem_addr_o;
   logic [COL-1:0][WIDTH-1:0]    ps_mem_data_i;
   logic [COL-1:0][WIDTH-1:0]    ps_mem_data_o;

   // external config
   logic                         ext_en_i;
   logic [ROW-1:0][WIDTH-1:0]    ext_input_i;
   logic [COL-1:0][WIDTH-1:0]    ext_weight_i;
   logic [COL-1:0][WIDTH-1:0]    ext_psum_i;
   logic                         ext_valid_en_i;
   logic                         ext_weight_en_i;
   external_inputs_struct        ext_inputs_i;
   logic [DRIVER_WIDTH-1:0]      ext_result_o;
   logic                         ext_valid_o;

   logic                         sample_clk_o;
   logic                         done_o;

   // input Memory ports
   logic                         ib_mem_cenb_r;
   logic                         ib_mem_wenb_r;
   logic [$clog2(I_SIZE)-1:0]    ib_mem_addr_r;
   logic [INPUT_DATA_WIDTH-1:0]  ib_mem_d_i_r;
   logic [INPUT_DATA_WIDTH-1:0]  ib_mem_q_o_r;

   // external input memory control
   logic                         ib_mem_cenb_ext_i;
   logic                         ib_mem_wenb_ext_i;
   logic [$clog2(I_SIZE)-1:0]    ib_mem_addr_ext_i;

   // weight Memory ports
   logic                         wb_mem_cenb_r;
   logic                         wb_mem_wenb_r;
   logic [$clog2(W_SIZE)-1:0]    wb_mem_addr_r;
   logic [WEIGHT_DATA_WIDTH-1:0] wb_mem_d_i_r;
   logic [WEIGHT_DATA_WIDTH-1:0] wb_mem_q_o_r;

   // external weight memory control
   logic                         wb_mem_cenb_ext_i;
   logic                         wb_mem_wenb_ext_i;
   logic [$clog2(I_SIZE)-1:0]    wb_mem_addr_ext_i;

   // outputs memory ports
   logic                         ob_mem_cenb_w;
   logic                         ob_mem_wenb_w;
   logic [$clog2(O_SIZE)-1:0]    ob_mem_addr_w;
   logic [WEIGHT_DATA_WIDTH-1:0] ob_mem_d_i_w;
   logic [WEIGHT_DATA_WIDTH-1:0] ob_mem_q_o_w;

   // external output memory control
   logic                         ob_mem_cenb_ext_i;
   logic                         ob_mem_wenb_ext_i;
   logic [$clog2(I_SIZE)-1:0]    ob_mem_addr_ext_i;
   logic [WEIGHT_DATA_WIDTH-1:0] ob_mem_d_i_ext_i;

   assign test_config_i.bypass                 = bypass_i;
   assign test_config_i.mode                   = mode_i;
   assign test_config_i.driver_valid           = driver_valid_i;
   assign test_config_i.driver_stop_code       = driver_stop_code_i;

   assign data_config_i.w_rows                 = w_rows_i;
   assign data_config_i.w_cols                 = w_cols_i;
   assign data_config_i.i_rows                 = i_rows_i;
   assign data_config_i.w_offset               = w_offset;
   assign data_config_i.i_offset               = i_offset;
   assign data_config_i.psum_offset            = psum_offset_r;
   assign data_config_i.o_offset_w             = o_offset_w;
   assign data_config_i.accum_en               = accum_enb_i;
   assign data_config_i.extra_config           = extra_config_i;

   assign ext_inputs_i.ext_input               = ext_input_i;
   assign ext_inputs_i.ext_weight              = ext_weight_i;
   assign ext_inputs_i.ext_psum                = ext_psum_i;
   assign ext_inputs_i.ext_valid               = ext_valid_en_i;
   assign ext_inputs_i.ext_weight_en           = ext_weight_en_i;
   
   assign ib_mem_cenb_r                        = ext_en_i ? ib_mem_cenb_ext_i : ib_mem_cenb_o;
   assign ib_mem_wenb_r                        = ext_en_i ? ib_mem_wenb_ext_i : ib_mem_wenb_o;
   assign ib_mem_addr_r                        = ext_en_i ? ib_mem_addr_ext_i : ib_mem_addr_o;
   assign #MEM_DELAY ib_mem_data_i                        = ib_mem_q_o_r;

   assign wb_mem_cenb_r                        = ext_en_i ? wb_mem_cenb_ext_i : wb_mem_cenb_o;
   assign wb_mem_wenb_r                        = ext_en_i ? wb_mem_wenb_ext_i : wb_mem_wenb_o;
   assign wb_mem_addr_r                        = ext_en_i ? wb_mem_addr_ext_i : wb_mem_addr_o;
   assign #MEM_DELAY wb_mem_data_i                        = wb_mem_q_o_r;

   assign ob_mem_cenb_w                        = ext_en_i ? ob_mem_cenb_ext_i : ob_mem_cenb_o;
   assign ob_mem_wenb_w                        = ext_en_i ? ob_mem_wenb_ext_i : ob_mem_wenb_o;
   assign ob_mem_addr_w                        = ext_en_i ? ob_mem_addr_ext_i : ob_mem_addr_o;
   assign ob_mem_d_i_w                         = ext_en_i ? ob_mem_d_i_ext_i  : ob_mem_data_o;
   assign ob_mem_data_i                        = ob_mem_q_o_w;

   logic [1000:0] testname;
   integer        returnval;
   string         filename;
   integer        f;
   
   initial begin
      #OFFSET;
      forever begin
        clk_i = 1'b0;
        #(CLOCK_PERIOD-(CLOCK_PERIOD*DUTY_CYCLE)) clk_i = 1'b1;
        #(CLOCK_PERIOD*DUTY_CYCLE);
      end
   end

   matrix_mult_wrapper_03 #(
      .WIDTH   (WIDTH   ),
      .ROW     (ROW     ),
      .COL     (COL     ),
      .W_SIZE  (W_SIZE  ),
      .I_SIZE  (I_SIZE  ),
      .O_SIZE  (O_SIZE  )
   ) matrix_mult_wrapper_0 (.*); //it should be good IG

   mem_emulator #(.WIDTH(INPUT_DATA_WIDTH), .SIZE(I_SIZE))
      ib_mem (
        .clk_i   (clk_i            ),
        .cenb_i  (ib_mem_cenb_r    ),
        .wenb_i  (ib_mem_wenb_r    ),
        .addr_i  (ib_mem_addr_r    ),
        .d_i     (ib_mem_d_i_r     ),
        .q_o     (ib_mem_q_o_r     )
   );

   mem_emulator #(.WIDTH(WEIGHT_DATA_WIDTH), .SIZE(W_SIZE))
      wb_mem (
        .clk_i   (clk_i            ),
        .cenb_i  (wb_mem_cenb_r    ),
        .wenb_i  (wb_mem_wenb_r    ),
        .addr_i  (wb_mem_addr_r    ),
        .d_i     (wb_mem_d_i_r     ),
        .q_o     (wb_mem_q_o_r     )
   );

   mem_emulator #(.WIDTH(WEIGHT_DATA_WIDTH), .SIZE(O_SIZE))
      ob_mem (
        .clk_i   (clk_i            ),
        .cenb_i  (ob_mem_cenb_w    ),
        .wenb_i  (ob_mem_wenb_w    ),
        .addr_i  (ob_mem_addr_w    ),
        .d_i     (ob_mem_d_i_w     ),
        .q_o     (ob_mem_q_o_w     )
   );

   initial begin : TEST_CASE
         $fsdbDumpfile("matrix_mult_wrapper_postapr.fsdb");
         $fsdbDumpon;
         $fsdbDumpvars(0, matrix_mult_wrapper_0, "+mda", "+all", "+trace_process");
	      $fsdbDumpvars(0, ib_mem, "+mda", "+all", "+trace_process");
	      $fsdbDumpvars(0, wb_mem, "+mda", "+all", "+trace_process");
	      $fsdbDumpvars(0, ob_mem, "+mda", "+all", "+trace_process");
        `ifdef SDF 
            $sdf_annotate("./matrix_mult_wrapper_03.wc.sdf", matrix_mult_wrapper_0, "./sdf.max.cfg");
            // $sdf_annotate("./matrix_mult_wrapper_03.bc.sdf", matrix_mult_wrapper_0, "./sdf.min.cfg");
        `endif

        returnval = $value$plusargs("testname=%s", testname);
        $display("@%0t: testname = %0s", $realtime, testname);

        filename = $sformatf("./golden_log/%0s.log", testname);
        f = $fopen(filename, "w");
        if (f == 0)
            $fatal("@%0t: Cannot open %s for writing", $realtime, filename);
        
        initialize_signals();
        repeat (10) @(posedge clk_i);	
        
        case(testname)
            "external":   external_mode();
            "memory":     memory_mode();
            "bist":       bist_mode();
            "output_stat":memory_mode(1);
            "dut_bypass": bist_mode_DUT_bypass();
            "lfsr_bypass": bist_mode_LFSR_bypass();
            "sa_bypass": bist_mode_SA_bypass();
            default:      run_all();
        endcase
        #1000 
        $fclose(f);
        $finish;
   end

`include "./tasks.sv"
endmodule 


