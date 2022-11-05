module async_reset 
(
   output reg rst,
   input      clk, asyncrst
);
   reg        rff1;
   
   always @(posedge clk or posedge asyncrst)
      if (asyncrst)     {rst,rff1} <= 2'b11;
      else              {rst,rff1} <= {rff1,1'b0};
endmodule
