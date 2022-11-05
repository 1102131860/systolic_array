`ifndef __CORDIC_WRAPPER_PKG__
`define __CORDIC_WRAPPER_PKG__

package cordic_wrapper_pkg;

localparam CORDIC_DATA_IN_WIDTH = 16;
localparam CORDIC_DATA_WIDTH = 18;
localparam NUM_ROT = 12;
localparam NUM_ROT_PER_STAGE = 6;
localparam NUM_STAGE = 2;

typedef enum bit {
    ROTATION = 1'b0,
    VECTOR   = 1'b1
} cordic_func;

typedef struct packed{
    logic signed [CORDIC_DATA_IN_WIDTH-1:0] x;
    logic signed [CORDIC_DATA_IN_WIDTH-1:0] y;
    logic signed [CORDIC_DATA_IN_WIDTH-1:0] z;
} cordic_data_in;

typedef struct packed{
    logic signed [CORDIC_DATA_WIDTH-1:0] x;
    logic signed [CORDIC_DATA_WIDTH-1:0] y;
    logic signed [CORDIC_DATA_WIDTH-1:0] z;
} cordic_data;

typedef struct packed{
    cordic_data [NUM_ROT_PER_STAGE:0] stage;
} st_cordic_stage;

typedef struct packed{
    cordic_data data;
    cordic_func func;
} st_cordic_state;

typedef struct packed{
    logic            vld;
    cordic_func      func;
    cordic_data_in   data;
} st_cordic_in;

typedef struct packed{
    logic            vld;
    cordic_data      data;
} st_cordic_out;

endpackage

import cordic_wrapper_pkg::*;

`endif
