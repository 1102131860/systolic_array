import cordic_wrapper_pkg::*;

module cordic_top_<groupnum>
    #(
        parameter NUM_MICRO_ROTATION = 12
    )
    (
        input  logic           i_clk,
        input  logic           i_rst,
        
        input  logic           i_valid,
        input  cordic_func     i_func,
        input  cordic_data_in  i_data,
        
        output logic           o_valid,
        output cordic_data     o_data
    );
endmodule    
