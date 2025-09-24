module matrix_mult #(parameter WIDTH=8, ROW=4, COL=4, W_SIZE=256, I_SIZE=256, O_SIZE=256) (
  input  logic                          clk_i,            // clock signal
  input  logic                          rstn_i,           // active low reset signal
  input  logic                          start_i,          // active high start calculation, must reset back to 0 first to start a new calculation
  input  data_config_struct             data_config_i,    // test controls
  output logic                          done_o,           // data controls
  // output buffer memory
  output  logic                         ob_mem_cenb_o,    // memory enable, active low
  output  logic                         ob_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(O_SIZE)-1:0]    ob_mem_addr_o,    // address
  output  logic [COL-1:0][WIDTH-1:0]    ob_mem_data_o,    // input data
  input   logic [COL-1:0][WIDTH-1:0]    ob_mem_data_i,    // output data
  // input buffer memory
  output  logic                         ib_mem_cenb_o,    // memory enable, active low
  output  logic                         ib_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(I_SIZE)-1:0]    ib_mem_addr_o,    // address
  input   logic [ROW-1:0][WIDTH-1:0]    ib_mem_data_i,    // input data
  // output  logic [ROW-1:0][WIDTH-1:0]   ib_mem_data_o,    // output data
  // weights buffer memory
  output  logic                         wb_mem_cenb_o,    // memory enable, active low
  output  logic                         wb_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(W_SIZE)-1:0]    wb_mem_addr_o,    // address
  input   logic [COL-1:0][WIDTH-1:0]    wb_mem_data_i,    // input data
  // output  logic [COL-1:0][WIDTH-1:0]   wb_mem_data_o,    // output data
  // partial sum buffer memory
  output  logic                         ps_mem_cenb_o,    // memory enable, active low
  output  logic                         ps_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(W_SIZE)-1:0]    ps_mem_addr_o,    // address
  output  logic [COL-1:0][WIDTH-1:0]    ps_mem_data_o,    // input data
  input   logic [COL-1:0][WIDTH-1:0]    ps_mem_data_i,    // output data
  // external mode
  input  logic                          ext_en_i,         // external mode enable, acitve high
  input  external_inputs_struct         ext_inputs_i,     // external inputs
  output logic [COL-1:0][WIDTH-1:0]     ext_result_o      // external outputs
);

endmodule