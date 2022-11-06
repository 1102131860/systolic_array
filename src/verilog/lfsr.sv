module lfsr 
#(
   parameter NUM_BITS
)
(
   input                   i_clk,
   input                   i_rst,
   
   input                   i_en,
   input                   i_load,
   input  [NUM_BITS-1:0]   i_data,
   input  [NUM_BITS-1:0]   i_stop_code,
 
   output                  o_lfsr_vld,
   output [NUM_BITS-1:0]   o_lfsr_data,
   output                  o_lfsr_done
);
 
   reg    [NUM_BITS:1]     r_lfsr_data;
   reg                     r_lfsr_vld;
   reg                     r_xnor;
 
 
   // Load data if i_load is detected. Otherwise run LFSR when enabled.
   always @(posedge i_clk or posedge i_rst) begin
      if(i_rst) begin
         r_lfsr_data <= '0;
         r_lfsr_vld  <= '0;
      end
      else begin
         r_lfsr_vld  <= i_en;
         if (i_en == 1'b1)
            if (i_load == 1'b1) 
               r_lfsr_data <= i_data;
            else                
               r_lfsr_data <= {r_lfsr_data[NUM_BITS-1:1], r_xnor};
      end
   end
   
   // https://docs.xilinx.com/v/u/en-US/xapp052
   // Taps for Maximum-Length LFSR Counters XNOR form 
   always @(*) begin
         r_xnor = r_lfsr_data[49] ^~ r_lfsr_data[40];   
   end
 
   assign o_lfsr_vld  = r_lfsr_vld;
   assign o_lfsr_data = r_lfsr_data[NUM_BITS:1];
   assign o_lfsr_done =(r_lfsr_data[NUM_BITS:1] == i_stop_code) ? 1'b1 : 1'b0;
 
endmodule
