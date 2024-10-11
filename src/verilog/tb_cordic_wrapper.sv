module tb_cordic_wrapper;

   parameter      NUM_MICRO_ROTATION = 12;
   parameter      INPUT_DATA_WIDTH   = 49;
   parameter      OUTPUT_DATA_WIDTH  = 54;
   parameter      DATA_WIDTH         = 56;
 
   parameter      PERIODCLK2         = 10;
   parameter real DUTY_CYCLE         = 0.5;
   parameter real OFFSET_SAMPLE      = 0;
   parameter real OFFSET             = 0.1;  //2.5
   parameter real ASYNC_RST_OFFSET   = 2.5;
   
   logic                             i_clk;
   logic                             i_async_rst;
   
   logic                             i_en;
   logic [1:0]                       i_mode;
   logic [2:0]                       i_bypass;
   logic [INPUT_DATA_WIDTH-1:0]      i_stop_code;
   
   logic                             i_vld;
   logic [DATA_WIDTH-1:0]            i_data;
   logic                             o_vld;
   logic [DATA_WIDTH-1:0]            o_data;
   
   logic                             o_sample_clk;
   
   logic [1000:0] testname;
   integer        returnval;
   string         filename;
   integer        f;
   
   initial begin
      #OFFSET;
      i_en = 1'b1;
      forever begin
         i_clk = 1'b0;
         #(PERIODCLK2-(PERIODCLK2*DUTY_CYCLE)) i_clk = 1'b1;
         #(PERIODCLK2*DUTY_CYCLE);
      end
   end

   cordic_wrapper #(
      .NUM_MICRO_ROTATION  (NUM_MICRO_ROTATION),
      .INPUT_DATA_WIDTH    (INPUT_DATA_WIDTH),
      .OUTPUT_DATA_WIDTH   (OUTPUT_DATA_WIDTH),
      .DATA_WIDTH          (DATA_WIDTH)
   ) cordic_wrapper_0 (.*);

   initial begin : TEST_CASE
      $fsdbDumpfile("cordic_wrapper.fsdb");
      $fsdbDumpon;
      $fsdbDumpvars(0, cordic_wrapper_0, "+mda", "+all", "+trace_process");
      `ifdef SDF 
         $sdf_annotate("./cordic_wrapper.sdf", cordic_wrapper_0);
      `endif
      returnval = $value$plusargs("testname=%s", testname);
      
      initialize_signals();
      repeat (10) @(posedge i_clk);	
      
      case(testname)
      	 "simple":               simple();
      	 default:                simple();
      endcase
      #1000 
      //$fclose(f);
      $finish;
   end

`include "./tasks.sv"
endmodule 
