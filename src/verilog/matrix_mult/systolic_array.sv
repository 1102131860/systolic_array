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
  output  logic [COL-1:0][WIDTH-1:0]    ob_mem_data_o      // output data
);

// declare internal busses
logic [ROW*(COL-1)-1:0][WIDTH-1:0]      east_b;             // pe east outputs
logic [COL*(ROW-1)-1:0][WIDTH-1:0]      south_b;            // pe south outputs

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
                            .ctrl_load_i        (ctrl_load_i[0]             ),
                            .ctrl_sum_out_i     (ctrl_sum_out_i[0]          ),
                            .ctrl_ps_in_i       (1'b0                       ),
                            .north_i            (wb_mem_data_i[0]           ),
                            .west_i             (ib_mem_data_i[0]           ),
                            .east_o             (east_b[0]                  ),
                            .south_o            (south_b[0]                 )
                    );
                end
                else if (j == (COL - 1)) begin // first row, last col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_i[j]             ),
                            .ctrl_sum_out_i     (ctrl_sum_out_i[j]          ),
                            .ctrl_ps_in_i       (1'b0                       ),
                            .north_i            (wb_mem_data_i[j]           ),
                            .west_i             (east_b[j - 1]              ),
                            .east_o             (   ),
                            .south_o            (south_b[j]                 )
                    );
                end
                else begin // first row, intermediate col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_i[j]             ),
                            .ctrl_sum_out_i     (ctrl_sum_out_i[j]          ),
                            .ctrl_ps_in_i       (1'b0                       ),
                            .north_i            (wb_mem_data_i[j]           ),
                            .west_i             (east_b[j - 1]              ),
                            .east_o             (east_b[j]                  ),
                            .south_o            (south_b[j]                 )
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
                            .ctrl_load_i        (ctrl_load_i[i*ROW]         ),
                            .ctrl_sum_out_i     (ctrl_sum_out_i[i*ROW]      ),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW]         ),
                            .west_i             (ib_mem_data_i[i]           ),
                            .east_o             (east_b[i*(ROW-1)]          ),
                            .south_o            (ob_mem_data_o[0]           )
                    );
                end
                else if (j == (COL - 1)) begin // last row, last col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_i[i*ROW + j]     ),
                            .ctrl_sum_out_i     (ctrl_sum_out_i[i*ROW + j]  ),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (east_b[i*(ROW-1) + j - 1]  ),
                            .east_o             (   ),
                            .south_o            (ob_mem_data_o[j]           ) 
                    );
                end
                else begin // last row, intermediate col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_i[i*ROW + j]     ),
                            .ctrl_sum_out_i     (ctrl_sum_out_i[i*ROW + j]  ),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (east_b[i*(ROW-1) + j - 1]  ),
                            .east_o             (east_b[i*(ROW-1) + j]      ),
                            .south_o            (ob_mem_data_o[j]           )  
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
                            .ctrl_load_i        (ctrl_load_i[i*ROW + j]     ),
                            .ctrl_sum_out_i     (ctrl_sum_out_i[i*ROW + j]  ),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (ib_mem_data_i[i]           ),
                            .east_o             (east_b[i*(ROW-1) + j]      ),
                            .south_o            (south_b[i*ROW + j]         )   
                    );
                end
                else if (j == (COL - 1)) begin // intermediate row, last col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_i[i*ROW + j]     ),
                            .ctrl_sum_out_i     (ctrl_sum_out_i[i*ROW + j]  ),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (east_b[i*(ROW-1) + j - 1]  ),
                            .east_o             (   ),
                            .south_o            (south_b[i*ROW + j]         )  
                    );
                end
                else begin // intermediate row, intermediate col pe
                    processing_element #(.WIDTH(WIDTH))
                        pe (
                            .clk_i              (clk_i                      ),
                            .rstn_i             (rstn_i                     ),
                            .ctrl_load_i        (ctrl_load_i[i*ROW + j]     ),
                            .ctrl_sum_out_i     (ctrl_sum_out_i[i*ROW + j]  ),
                            .ctrl_ps_in_i       (1'b1                       ),
                            .north_i            (south_b[(i-1)*ROW + j]     ),
                            .west_i             (east_b[i*(ROW-1) + j - 1]  ),
                            .east_o             (east_b[i*(ROW-1) + j]      ),
                            .south_o            (south_b[i*ROW + j]         )
                    );
                end
            end
        end
    end
endgenerate

endmodule