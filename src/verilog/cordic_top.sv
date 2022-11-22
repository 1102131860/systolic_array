import cordic_wrapper_pkg::*;

module cordic_top
    #(
        parameter NUM_MICRO_ROTATION = 12
    )
    (
        input  logic        clk_i,
        input  logic        rst_i,
        
        input  logic        en_i,
        input  cordic_func  func_i,
        input  cordic_data  data_i,
        
        output logic        done_o,
        output cordic_data  data_o
    );
