module misr 
#(
   parameter NUM_BITS = 54
)
(
   input                   i_clk,
   input                   i_rst,

   input                   i_en,
   input                   i_load,
   input  [NUM_BITS-1:0]   i_data,
 
   output                  o_misr_vld,
   output [NUM_BITS-1:0]   o_misr_data
);
 
   reg    [NUM_BITS:1]     r_misr_data = '0;
   reg                     r_misr_vld;
   reg                     r_xnor;
 
 
   // Load seed if i_load is detected. Otherwise run LFSR when enabled.
   always @(posedge i_clk or posedge i_rst) begin
      if(i_rst) begin 
         r_misr_data <= '0;
         r_misr_vld  <= '0;
      end
      else begin
         r_misr_vld  <= i_en;
         if (i_en == 1'b1)
            if (i_load == 1'b1)
               r_misr_data <= i_data;
            else
               r_misr_data <= {r_misr_data[NUM_BITS-1:1], r_xnor} ^ i_data;
      end
   end
 
   // https://docs.xilinx.com/v/u/en-US/xapp052
   // Taps for Maximum-Length LFSR Counters XNOR form 
   always @(*) begin
         r_xnor = r_misr_data[54] ^~ r_misr_data[53] ^~ r_misr_data[18] ^~ r_misr_data[17];
   end
 
   assign o_misr_vld  = r_misr_vld;
   assign o_misr_data = r_misr_data[NUM_BITS:1];
 
endmodule
