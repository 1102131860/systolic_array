/*
* Name: processing_element.sv
*
* Description:
* This is the module implementation of a single processing unit for the systolic array.
*/

module processing_element #(parameter WIDTH=8) (
  input     logic                  clk_i,          // clock signal
  input     logic                  rstn_i,         // active low reset signal

  // control signals
  input     logic                  ctrl_load_i,     // if high, load into weights register; else, maintain weights register
  input     logic                  ctrl_sum_out_i,  // if high, send adder result to output; else, send north_i to south_o
  input     logic                  ctrl_ps_in_i,    // if high, use north_i as partial sum; else, use '0

  // data between elements
  input     logic signed [WIDTH-1:0]      north_i,        // north input
  input     logic signed [WIDTH-1:0]      west_i,         // west input
  output    logic signed [WIDTH-1:0]      east_o,         // east output
  output    logic signed [WIDTH-1:0]      south_o,        // south output

  // for verification
  output    logic signed [WIDTH-1:0]      weight_o,
  output    logic signed [WIDTH-1:0]      result_o
);

// local parameters
localparam MAX_VAL = (1 << (WIDTH - 1)) - 1;
localparam MIN_VAL = -(1 << (WIDTH - 1));

// declare internal signals
logic signed [WIDTH-1:0]      weight_r;                     // internal register for storing weights
logic signed [WIDTH-1:0]      result_b, ps_b;               // bus that stores arithmatic results
logic signed [2*WIDTH-1:0]    long_mult_b, long_sum_b;      // (long) buses that store arithmatic result

// saturation implementation
function signed [WIDTH-1:0] saturation(input signed [2*WIDTH-1:0] x);
    if (x > 2**(WIDTH-1)-1)         return {1'b0, {(WIDTH-1){1'b1}}};
    else if (x < -2**(WIDTH-1))     return {1'b1, {(WIDTH-1){1'b0}}};
    else                            return x[WIDTH-1:0];
endfunction

// sequential processing element logic
always_ff @(posedge clk_i or negedge rstn_i) begin
    if(!rstn_i) begin // default assignments
        weight_r    <=  '0;
        east_o      <=  '0;
        south_o     <=  '0;
    end
    else begin
        weight_r    <=  (ctrl_load_i) ? (north_i) : (weight_r);
        east_o      <=  west_i;
        south_o     <=  (ctrl_sum_out_i) ? (result_b) : (north_i);
    end
end

// combinational logic for multiplication
always_comb begin
    // compute partial sum
    if (ctrl_ps_in_i)       ps_b = north_i;
    else                    ps_b = 0;

    // multiplication operation
    long_mult_b = weight_r * west_i;
    long_sum_b = ps_b + saturation(long_mult_b);
    result_b = saturation(long_sum_b);

    // for verification
    weight_o = weight_r;
    result_o = result_b;
end

endmodule