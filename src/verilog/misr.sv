module misr 
#(
   parameter NUM_BITS = 54
)
(
   input                   i_clk,
   input                   i_rst,

   input                   i_mode,
   input                   i_done,
   input  [NUM_BITS-1:0]   i_seed_data,
   
   input                   i_vld,
   input  [NUM_BITS-1:0]   i_data,
 
   output                  o_misr_vld,
   output [NUM_BITS-1:0]   o_misr_data
);
 
   reg    [NUM_BITS:1]     r_misr_data;
   reg                     r_misr_vld;
   reg                     r_xnor;
 
 
   always @(posedge i_clk or posedge i_rst) begin
      if(i_rst) begin 
         r_misr_data <= i_seed_data;
         r_misr_vld  <= '0;
      end
      else begin
         r_misr_vld  <= i_mode ? i_done : i_vld;
         if (i_vld == 1'b1)
            if (i_mode == 1'b0)
               r_misr_data <= i_data;
            else
               if (i_done == 1'b0)
               r_misr_data <= {r_misr_data[NUM_BITS-1:1], r_xnor} ^ i_data;
      end
   end
 
   // https://docs.xilinx.com/v/u/en-US/xapp052
   // Taps for Maximum-Length LFSR Counters XNOR form 
   always_comb begin
         r_xnor = r_misr_data[54] ^~ r_misr_data[53] ^~ r_misr_data[18] ^~ r_misr_data[17];
   end
 
   assign o_misr_vld  = r_misr_vld;
   assign o_misr_data = r_misr_data[NUM_BITS:1];
 
endmodule
