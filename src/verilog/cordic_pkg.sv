package cordic_pkg;

localparam [5:0] CORDIC_DATA_WIDTH = 16;
localparam [5:0] CORDIC_OUTPUT_DATA_WIDTH = 18;

typedef enum bit {
    ROTATION = 1'b0,
    VECTOR   = 1'b1
} cordic_func;

typedef struct packed{
    logic signed [CORDIC_DATA_WIDTH-1:0] x;
    logic signed [CORDIC_DATA_WIDTH-1:0] y;
    logic signed [CORDIC_DATA_WIDTH-1:0] z;
} cordic_data;   
    
typedef struct packed{
    logic signed [CORDIC_OUTPUT_DATA_WIDTH-1:0] x;
    logic signed [CORDIC_OUTPUT_DATA_WIDTH-1:0] y;
    logic signed [CORDIC_OUTPUT_DATA_WIDTH-1:0] z;
} cordic_output_data;

endpackage
