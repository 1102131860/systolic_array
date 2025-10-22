/*
* Name: systolic_array.sv
*
* Description:
* This is the module implementation of the the systolic array.
*/

module systolic_array #(parameter WIDTH=8, ROW=4, COL=4) (
  input  logic                          clk_i,              // clock signal
  input  logic                          rstn_i,             // active low reset signal
  input  data_config_struct             data_config_i,      // test controls

  // pe control signals
  input  logic [0:ROW-1][0:COL-1]       ctrl_load_i,        // control weights register
  input  logic [0:ROW-1][0:COL-1]       ctrl_sum_out_i,     // control output selection
  input  logic [0:ROW-1][0:COL-1]       ctrl_ps_in_i,       // control addition carry-in
  input  logic [0:ROW-1][0:COL-1]       ctrl_ps_valid_i,    // control partial sums register validity

  // peripheral I/O ports
  input  logic [COL-1:0][WIDTH-1:0]     north_i,     // input data
  input  logic [ROW-1:0][WIDTH-1:0]     west_i,      // input data
  output logic [COL-1:0][WIDTH-1:0]     south_o      // output data
);

// declare internal busses
logic signed [WIDTH-1:0]                we_b    [0:ROW-1][0:COL];
logic signed [WIDTH-1:0]                ns_b    [0:ROW][0:COL-1];

// for verification
logic signed [WIDTH-1:0]  ps_b              [0:ROW][0:COL-1];
logic signed [WIDTH-1:0]  weight_b          [0:ROW][0:COL-1];
logic signed [WIDTH-1:0]  result_b          [0:ROW][0:COL-1];

`ifdef DEBUG
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (ctrl_load_i[0] || ctrl_sum_out_i[0]) begin
            $display("==========Internal States==========");

            $write("@%0t: weight_b: ", $realtime);
            for (int i = 0; i < ROW; i++) begin
               for (int j = COL - 1; j >= 0; j--) begin
                    $write("%x", weight_b[i][j]);
               end
               $write(" ");
            end
            $display("");

            $write("@%0t: result_b: ", $realtime);
            for (int i = 0; i < ROW; i++) begin
               for (int j = COL - 1; j >= 0; j--) begin
                    $write("%x", result_b[i][j]);
               end
               $write(" ");
            end
            $display("");

            $write("@%0t: ps_b: ", $realtime);
            for (int i = 0; i < ROW; i++) begin
               for (int j = COL - 1; j >= 0; j--) begin
                    $write("%x", ps_b[i][j]);
               end
               $write(" ");
            end
            $display("");
        end
    end
`endif

// instantiate ROW x COL processing elements
genvar r, c;
generate
    for (r=0; r<ROW; r++) begin : sys_ROW
        for (c=0; c<COL; c++) begin : sys_COL
            processing_element #(.WIDTH(WIDTH)) u_pe (
                .clk_i              (clk_i                          ),
                .rstn_i             (rstn_i                         ),
                .ctrl_out_stat_i    (data_config_i.extra_config[0]  ),
                .ctrl_load_i        (ctrl_load_i[r][c]              ),
                .ctrl_sum_out_i     (ctrl_sum_out_i[r][c]           ),
                .ctrl_ps_in_i       (ctrl_ps_in_i[r][c]             ),    
                .ctrl_ps_valid_i    (ctrl_ps_valid_i[r][c]          ),  
                .north_i            (ns_b[r][c]                     ),
                .west_i             (we_b[r][c]                     ),            
                .east_o             (we_b[r][c + 1]                 ),
                .south_o            (ns_b[r + 1][c]                 ),
                .ps_o               (ps_b[r][c]             ),
                .weight_o           (weight_b[r][c]         ),
                .result_o           (result_b[r][c]         )
            );
        end

        // assign busses to inputs/outputs
        assign we_b[r][0] = west_i[r];
    end
endgenerate

genvar j;
generate
    for (j=0; j<COL; j++) begin
        // assign busses to inputs/outputs
        assign ns_b[0][j] = north_i[j];
        assign south_o[j] = ns_b[ROW][j];
    end
endgenerate

endmodule