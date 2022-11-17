`include "cordic_wrapper_pkg.sv"

module cordic_wrapper
#(
   parameter   NUM_MICRO_ROTATION = 12,
   parameter   INPUT_DATA_WIDTH   = 49,
   parameter   OUTPUT_DATA_WIDTH  = 54,
   parameter   DATA_WIDTH         = 56
)
(
   input  logic                           i_clk,
   input  logic                           i_async_rst,

   input  logic [1:0]                     i_mode,
   input  logic [2:0]                     i_bypass,
   input  logic [INPUT_DATA_WIDTH-1:0]    i_stop_code,
   
   input  logic                           i_vld,
   input  logic [DATA_WIDTH-1:0]          i_data,  //[INPUT_DATA_WIDTH-1:0]
   output logic                           o_vld,
   output logic [DATA_WIDTH-1:0]          o_data,  //[OUTPUT_DATA_WIDTH-1:0] 
   
   output logic                           o_sample_clk
);

   st_cordic_in   cordic_in,   driver_in,  driver_out;
   st_cordic_out  cordic_out, monitor_in, monitor_out;

   logic          driver_bypass, cordic_bypass, monitor_bypass;
   logic          driver_mode, monitor_mode;
   logic          stop_code_hit;
   logic          sync_rst;
   logic          [OUTPUT_DATA_WIDTH-1:0]       pre_o_data;
   
   assign o_sample_clk   = i_clk;
   
   assign driver_mode    = i_mode[1];    // 0=external   1=internal lfsr
   assign monitor_mode   = i_mode[0];    // 0=directout  1=signature analyzer
  
   assign driver_bypass  = i_bypass[2];  // 0=no bypass  1=bypass
   assign cordic_bypass  = i_bypass[1];  // 0=no bypass  1=bypass
   assign monitor_bypass = i_bypass[0];  // 0=no bypass  1=bypass
   
   async_reset async_rst_0 
   (
      .clk        (i_clk), 
      .asyncrst   (i_async_rst),
      .rst        (sync_rst)
   );

//-------------------------------------------------------------------------//
//    Driver                                                               //
//-------------------------------------------------------------------------//
   
   assign driver_in.vld  = i_vld;
   assign driver_in.func = cordic_func'(i_data[54]); //[54]
   assign driver_in.data = {i_data[51:36],i_data[33:18],i_data[15:0]};
   
   pseudo_rand_num_gen
   #(
      .DATA_WIDTH (INPUT_DATA_WIDTH)
   ) cordic_driver_0 (
      .i_clk      (i_clk),
      .i_rst      (sync_rst),
      
      .i_mode     (driver_mode),
      .i_en       (driver_in.vld),
      .i_data     ({driver_in.func, driver_in.data}),
      
      .i_stop_code(i_stop_code),

      .o_vld      (driver_out.vld),
      .o_data     ({driver_out.func, driver_out.data}),
      .o_done     (stop_code_hit)
   );
   
   assign cordic_in = driver_bypass ? driver_in : driver_out;

//-------------------------------------------------------------------------//
//    Cordic                                                               //
//-------------------------------------------------------------------------//
   
   cordic_top
   #(
      .NUM_MICRO_ROTATION  (NUM_MICRO_ROTATION)
   ) cordic_top_0 (
      .clk_i      (i_clk),
      .rst_i      (sync_rst),
      
      .en_i       (cordic_in.vld),
      .func_i     (cordic_in.func),
      .data_i     (cordic_in.data),
      
      .done_o     (cordic_out.vld),
      .data_o     (cordic_out.data)
   );

   assign monitor_in.vld  = cordic_bypass ? cordic_in.vld  : cordic_out.vld;
   assign monitor_in.data = cordic_bypass ? {2'b00,cordic_in.data[47:32],2'b00,cordic_in.data[31:16],2'b00,cordic_in.data[15:0]} : cordic_out.data;

   
//-------------------------------------------------------------------------//
//    Monitor                                                              //
//-------------------------------------------------------------------------//
   
   signature_analyzer
   #(
      .DATA_WIDTH (OUTPUT_DATA_WIDTH)
   ) cordic_monitor_0 (
      .i_clk      (i_clk),
      .i_rst      (sync_rst),
      
      .i_mode     (monitor_mode),     
      .i_stop     (stop_code_hit),     
      
      .i_seed_vld (i_vld),     
      .i_seed_data({5'b0,i_data[54],i_data[51:36],i_data[33:18],i_data[15:0]}),

      .i_dut_vld  (monitor_in.vld),     
      .i_dut_data (monitor_in.data),

      .o_vld      (monitor_out.vld),
      .o_data     (monitor_out.data)
   );

   assign o_vld      = monitor_bypass ? monitor_in.vld  : monitor_out.vld;
   assign pre_o_data = monitor_bypass ? monitor_in.data : monitor_out.data;
   assign o_data     ={2'b00, pre_o_data}; 
endmodule
