/*
* Name: matrix_mult.sv
*
* Description: This implementation of the matrix multiplier supports both
* weight-stationary and output-stationary operation.
*/
module matrix_mult_group3 #(parameter WIDTH=8, ROW=4, COL=4, W_SIZE=256, I_SIZE=256, O_SIZE=256) (
  input  logic                          clk_i,            // clock signal
  input  logic                          rstn_i,           // active low reset signal
  input  logic                          start_i,          // active high start calculation, must reset back to 0 first to start a new calculation
  input  data_config_struct             data_config_i,    // test controls

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

  // weights buffer memory
  output  logic                         wb_mem_cenb_o,    // memory enable, active low
  output  logic                         wb_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(W_SIZE)-1:0]    wb_mem_addr_o,    // address
  input   logic [COL-1:0][WIDTH-1:0]    wb_mem_data_i,    // input data

  // partial sum buffer memory
  output  logic                         ps_mem_cenb_o,    // memory enable, active low
  output  logic                         ps_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(W_SIZE)-1:0]    ps_mem_addr_o,    // address
  output  logic [COL-1:0][WIDTH-1:0]    ps_mem_data_o,    // input data
  input   logic [COL-1:0][WIDTH-1:0]    ps_mem_data_i,    // output data

  // external mode
  input  logic                          ext_en_i,         // external mode enable, acitve high
  input  external_inputs_struct         ext_inputs_i,     // external inputs
  output logic [COL-1:0][WIDTH-1:0]     ext_result_o,     // external outputs
  output logic                          ext_valid_o,      // external valid

  // output done
  output logic                          done_o            // data controls
);

logic [$clog2(ROW)-1:0]  ext_count_r;                   // counter for external mode

// declare interfacing signals between systolic array and controller
logic [0:ROW-1][0:COL-1]            ctrl_load_b, ctrl_sum_out_b, ctrl_ps_in_b, ctrl_ps_valid_b;

// declare internal busses
logic [ROW-1:0][WIDTH-1:0]          ib_data_muxed;      // muxed input ib memory data
logic [COL-1:0][WIDTH-1:0]          wb_data_muxed;      // muxed weight wb memory data
logic [COL-1:0][WIDTH-1:0]          pe_result_b;        // internal bus for PE results

logic [ROW*COL-1:0]                 ctrl_load_muxed;    // muxed ctrl load signal
logic [ROW*COL-1:0]                 ctrl_sum_out_muxed; // muxed ctrl sum out signal
logic                               start_r1, start_r2, start_en;  // detect posedge of start_i

//=========================================================================//
//  EXTERNAL MODE (BYPASS MEMORY CONTROLLER)                               //
//=========================================================================//
// synchronous counter for controlling ext_valid_o
always_ff @(posedge clk_i or negedge rstn_i) begin : control_ext_valid_o
    if (!rstn_i) begin
        ext_valid_o <= '0;
        ext_count_r <= '0;
    end
    else begin
        ext_valid_o <= '0;
        if (!start_i && ext_en_i && ext_inputs_i.ext_valid) begin
            ext_valid_o <= (ext_count_r == ROW - 1);
            if (ext_count_r < ROW - 1)
                ext_count_r <= ext_count_r + 1;
        end else
            ext_count_r <= '0;
    end
end

// combinational logic to control systolic array I/O
always_comb begin : Input_Weight_Control_Mux
    if (ext_en_i) begin
        ib_data_muxed       = ext_inputs_i.ext_input;
        wb_data_muxed       = ext_inputs_i.ext_weight;
        ctrl_load_muxed     = {ROW*COL{ext_inputs_i.ext_weight_en}};
        ctrl_sum_out_muxed  = {ROW*COL{ext_inputs_i.ext_valid}};
    end else begin
        ib_data_muxed       = ib_mem_data_i;
        wb_data_muxed       = wb_mem_data_i;
        ctrl_load_muxed     = ctrl_load_b;
        ctrl_sum_out_muxed  = ctrl_sum_out_b;
    end
end

// Output Assignment
assign ext_result_o         = pe_result_b;
assign ob_mem_data_o        = pe_result_b;

//=========================================================================//
// Start_i Posedge Detector                                                //
//=========================================================================//
always_ff @(posedge clk_i or negedge rstn_i) begin : posedge_start_i
    if (!rstn_i) {start_r1, start_r2} <= 2'b00;
    else {start_r1, start_r2} <= {start_i, start_r1};
end

assign start_en = start_r1 & ~start_r2;

//=========================================================================//
//  SYSTOLIC ARRAY                                                         //
//=========================================================================//
systolic_array #(.WIDTH(WIDTH), .ROW(ROW), .COL(COL))
    sys_array (
        .ctrl_load_i        (ctrl_load_muxed    ),
        .ctrl_sum_out_i     (ctrl_sum_out_muxed ),
        .ctrl_ps_in_i       (ctrl_ps_in_b       ),
        .ctrl_ps_valid_i    (ctrl_ps_valid_b    ),
        .north_i            (wb_data_muxed      ),
        .west_i             (ib_data_muxed      ),
        .south_o            (pe_result_b        ),
        .*
);

//=========================================================================//
//  MEMORY-MODE CONTROLLER                                                 //
//=========================================================================//
controller #(.WIDTH(WIDTH), .ROW(ROW), .COL(COL), .W_SIZE(W_SIZE), .I_SIZE(I_SIZE), .O_SIZE(O_SIZE))
    sys_ctrl (
        .config_i           (data_config_i      ),
        .ctrl_load_o        (ctrl_load_b        ),
        .ctrl_sum_out_o     (ctrl_sum_out_b     ),
        .ctrl_ps_in_o       (ctrl_ps_in_b       ),
        .ctrl_ps_valid_o    (ctrl_ps_valid_b    ),
        .start_i            (start_en),
        .*
);

endmodule