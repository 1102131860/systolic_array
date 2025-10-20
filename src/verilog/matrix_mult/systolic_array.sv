/*
* Name: systolic_array.sv
*
* Description:
* This is the module implementation of the the systolic array.
*/

module systolic_array #(parameter WIDTH=8, ROW=4, COL=4) (
  input  logic                          clk_i,              // clock signal
  input  logic                          rstn_i,             // active low reset signal

  // pe control signals
  input  logic [ROW*COL-1:0]            ctrl_load_i,        // if high, load into weights register; else, send north_i to south_o
  input  logic [ROW*COL-1:0]            ctrl_sum_out_i,     // if high, send adder result to output; else, send north_i to south_o

  // input buffer memory
  input   logic [ROW-1:0][WIDTH-1:0]    ib_mem_data_i,      // input data

  // weights buffer memory
  input   logic [COL-1:0][WIDTH-1:0]    wb_mem_data_i,      // input data

  // output buffer memory
  output  logic [COL-1:0][WIDTH-1:0]    ob_mem_data_o,      // output data

  // external mode
  input  logic                          ext_en_i,           // external mode enable, acitve high
  input  external_inputs_struct         ext_inputs_i,       // external inputs
  output logic [COL-1:0][WIDTH-1:0]     ext_result_o        // external outputs
);

// declare internal busses
logic [ROW*(COL-1)-1:0][WIDTH-1:0]      east_b;             // pe east outputs
logic [COL*(ROW-1)-1:0][WIDTH-1:0]      south_b;            // pe south outputs

logic [ROW-1:0][WIDTH-1:0]              ib_data_muxed;      // muxed input ib memory data
logic [COL-1:0][WIDTH-1:0]              wb_data_muxed;      // muxed weight wb memory data
logic [COL-1:0][WIDTH-1:0]              pe_result_b;        // internal bus for PE results

logic [ROW*COL-1:0]                     ctrl_load_muxed;    // muxed ctrl load signal
logic [ROW*COL-1:0]                     ctrl_sum_out_muxed; // muxed ctrl sum out signal

// for verification
logic [COL-1:0][WIDTH-1:0]              weight_b[0:ROW-1];
logic [COL-1:0][WIDTH-1:0]              result_b[0:ROW-1];

always_comb begin : Input_Weight_Output_Control_Mux
    if (ext_en_i) begin
        ib_data_muxed = ext_inputs_i.ext_input;
        wb_data_muxed = ext_inputs_i.ext_weight;
        ext_result_o = pe_result_b;
        ctrl_load_muxed = {ROW*COL{ext_inputs_i.ext_weight_en}};
        ctrl_sum_out_muxed = {ROW*COL{ext_inputs_i.ext_valid}};
    end else begin
        ib_data_muxed = ib_mem_data_i;
        wb_data_muxed = wb_mem_data_i;
        ob_mem_data_o = pe_result_b;
        ctrl_load_muxed = ctrl_load_i;
        ctrl_sum_out_muxed = ctrl_sum_out_i;
    end
end

`ifdef DEBUG
always_ff @(posedge clk_i) begin : DEBUG_BLOCKING
    if (ext_en_i) begin
        $display("=========Systolic Array Internal=========");
        $write("@%0t: weight_b ", $realtime);
        for (int i = 0; i < ROW; i++)
            $write("%x ", weight_b[i]);
        $display("");

        $write("@%0t: result_b ", $realtime);
        for (int i = 0; i < ROW; i++)
            $write("%x ", result_b[i]);
        $display("");

        $display("@%0t: ib_data_muxed: %x", $realtime, ib_data_muxed);
        $display("@%0t: wb_data_muxed: %x", $realtime, wb_data_muxed);
    end
end

`endif

// instantiate ROW x COL processing elements
genvar i, j;
generate
    for (i = 0; i < ROW; i = i + 1) begin
        if (i == 0) begin // first row of pe
            for (j = 0; j < COL; j = j + 1) begin
                if (j == 0) begin // first row, first col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_muxed[0]         ),
                            .ctrl_sum_out_i     (ctrl_sum_out_muxed[0]      ),
                            .ctrl_ps_in_i       (1'b0                       ),
                            .north_i            (wb_data_muxed[0]           ),
                            .west_i             (ib_data_muxed[0]           ),
                            .east_o             (east_b[0]                  ),
                            .south_o            (south_b[0]                 ),
                            .weight_o           (weight_b[i][j]             ),
                            .result_o           (result_b[i][j]             )
                    );
                end
                else if (j == (COL - 1)) begin // first row, last col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_muxed[j]         ),
                            .ctrl_sum_out_i     (ctrl_sum_out_muxed[j]      ),
                            .ctrl_ps_in_i       (1'b0                       ),
                            .north_i            (wb_data_muxed[j]           ),
                            .west_i             (east_b[j - 1]              ),
                            .east_o             (                           ),
                            .south_o            (south_b[j]                 ),
                            .weight_o           (weight_b[i][j]             ),
                            .result_o           (result_b[i][j]             )
                    );
                end
                else begin // first row, intermediate col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_muxed[j]         ),
                            .ctrl_sum_out_i     (ctrl_sum_out_muxed[j]      ),
                            .ctrl_ps_in_i       (1'b0                       ),
                            .north_i            (wb_data_muxed[j]           ),
                            .west_i             (east_b[j - 1]              ),
                            .east_o             (east_b[j]                  ),
                            .south_o            (south_b[j]                 ),
                            .weight_o           (weight_b[i][j]             ),
                            .result_o           (result_b[i][j]             )
                    );
                end
            end
        end
        else if (i == (ROW - 1)) begin // last row of pe
            for (j = 0; j < COL; j = j + 1) begin
                if (j == 0) begin // last row, first col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_muxed[i*ROW]     ),
                            .ctrl_sum_out_i     (ctrl_sum_out_muxed[i*ROW]  ),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW]         ),
                            .west_i             (ib_data_muxed[i]           ),
                            .east_o             (east_b[i*(ROW-1)]          ),
                            .south_o            (pe_result_b[0]             ),
                            .weight_o           (weight_b[i][j]             ),
                            .result_o           (result_b[i][j]             )
                    );
                end
                else if (j == (COL - 1)) begin // last row, last col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_muxed[i*ROW + j] ),
                            .ctrl_sum_out_i     (ctrl_sum_out_muxed[i*ROW + j]),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (east_b[i*(ROW-1) + j - 1]  ),
                            .east_o             (                           ),
                            .south_o            (pe_result_b[j]             ),
                            .weight_o           (weight_b[i][j]             ),
                            .result_o           (result_b[i][j]             )
                    );
                end
                else begin // last row, intermediate col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_muxed[i*ROW + j] ),
                            .ctrl_sum_out_i     (ctrl_sum_out_muxed[i*ROW + j]),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (east_b[i*(ROW-1) + j - 1]  ),
                            .east_o             (east_b[i*(ROW-1) + j]      ),
                            .south_o            (pe_result_b[j]             ),
                            .weight_o           (weight_b[i][j]             ),
                            .result_o           (result_b[i][j]             )
                    );
                end
            end
        end
        else begin // intermediate row of pe
            for (j = 0; j < COL; j = j + 1) begin
                if (j == 0) begin // intermediate row, first col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_muxed[i*ROW + j] ),
                            .ctrl_sum_out_i     (ctrl_sum_out_muxed[i*ROW + j]),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (ib_data_muxed[i]           ),
                            .east_o             (east_b[i*(ROW-1) + j]      ),
                            .south_o            (south_b[i*ROW + j]         ),
                            .weight_o           (weight_b[i][j]             ),
                            .result_o           (result_b[i][j]             )
                    );
                end
                else if (j == (COL - 1)) begin // intermediate row, last col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_muxed[i*ROW + j] ),
                            .ctrl_sum_out_i     (ctrl_sum_out_muxed[i*ROW + j]),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (east_b[i*(ROW-1) + j - 1]  ),
                            .east_o             (                           ),
                            .south_o            (south_b[i*ROW + j]         ),
                            .weight_o           (weight_b[i][j]             ),
                            .result_o           (result_b[i][j]             )
                    );
                end
                else begin // intermediate row, intermediate col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_muxed[i*ROW + j] ),
                            .ctrl_sum_out_i     (ctrl_sum_out_muxed[i*ROW + j]),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (east_b[i*(ROW-1) + j - 1]  ),
                            .east_o             (east_b[i*(ROW-1) + j]      ),
                            .south_o            (south_b[i*ROW + j]         ),
                            .weight_o           (weight_b[i][j]             ),
                            .result_o           (result_b[i][j]             )
                    );
                end
            end
        end
    end
endgenerate

endmodule