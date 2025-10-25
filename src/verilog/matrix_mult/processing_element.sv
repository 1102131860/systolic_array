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
  input     logic                  ctrl_out_stat_i, // high if in output stationary mode; otherwise, weight stationary mode
  input     logic                  ctrl_load_i,     // if high, load into weights register; else, maintain weights register
  input     logic                  ctrl_sum_out_i,  // if high, send adder result to output; else, send north_i to south_o
  input     logic                  ctrl_ps_in_i,    // if high, carry in partial sums adder; else, carry in north_i
  input     logic                  ctrl_ps_valid_i, // if low, means that partial sums register value is not valid yet

  // data between elements
  input     logic signed [WIDTH-1:0]      north_i,  // north input
  input     logic signed [WIDTH-1:0]      west_i,   // west input
  output    logic signed [WIDTH-1:0]      east_o,   // east output
  output    logic signed [WIDTH-1:0]      south_o,   // south output

  // for verification
  output    logic signed [WIDTH-1:0]      ps_o,
  output    logic signed [WIDTH-1:0]      weight_o,
  output    logic signed [WIDTH-1:0]      result_o
);

// local parameters
localparam MAX_VAL = (1 << (WIDTH - 1)) - 1;
localparam MIN_VAL = -(1 << (WIDTH - 1));

// declare internal signals
logic signed [WIDTH-1:0]      weight_r, ps_r;               // internal registers for storing weights and partial sums
logic signed [WIDTH-1:0]      result_b;                     // bus that stores arithmatic results
logic signed [2*WIDTH-1:0]    long_mult_b, long_sum_b;      // (long) buses that store arithmatic result

// saturation implementation
function signed [WIDTH-1:0] saturation(input signed [2*WIDTH-1:0] x);
    if      (x > 2**(WIDTH-1)-1)    return {1'b0, {(WIDTH-1){1'b1}}};
    else if (x < -2**(WIDTH-1))     return {1'b1, {(WIDTH-1){1'b0}}};
    else                            return x[WIDTH-1:0];
endfunction

// sequential processing element logic
always_ff @(posedge clk_i or negedge rstn_i) begin
    if(!rstn_i) begin // default assignments
        weight_r    <=  '0;
        ps_r        <=  '0;
        east_o      <=  '0;
        south_o     <=  '0;
    end
    else begin
        weight_r    <=  ctrl_load_i ? north_i : weight_r;
        ps_r        <=  ctrl_ps_valid_i ? result_b : ps_r;
        east_o      <=  west_i;
        south_o     <=  ctrl_sum_out_i ? (ctrl_out_stat_i ? ps_r : result_b) : north_i;
    end
end

// combinational logic for computation
always_comb begin
    // multiplication operation
    long_mult_b = ctrl_out_stat_i ? (north_i * west_i) : (weight_r * west_i);

    // addition operation
    long_sum_b = (ctrl_ps_in_i ? ps_r : north_i) + saturation(long_mult_b);
    
    result_b = saturation(long_sum_b);

    // for verification
    ps_o = ps_r;
    weight_o = weight_r;
    result_o = result_b;
end

endmodule