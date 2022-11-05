
module pseudo_rand_num_gen
#(
   parameter DATA_WIDTH = 49 // func-1 x-16 y-16 z-16
)
(
   input  logic                  i_clk,
   input  logic                  i_rst,

   input  logic                  i_mode,
   input  logic                  i_en,
   input  logic [DATA_WIDTH-1:0] i_data, // data or seed
   input  logic [DATA_WIDTH-1:0] i_stop_code,
   
   output logic                  o_vld,
   output logic [DATA_WIDTH-1:0] o_data,
   output logic                  o_done
);

   import pseudo_rand_num_gen_pkg::*;

   st_prng_state                 r_state, r_next_state;
   logic                         lfsr_en, lfsr_load, lfsr_done;
   
   //state update (ff)
   always_ff @(posedge i_clk or posedge i_rst) 
      if(i_rst)   r_state <= RESET;
      else        r_state <= r_next_state;

   //next state (combo)
   always_comb begin
	  r_next_state = STATEX;
      case (r_state)
	     RESET:   r_next_state = i_en ? RUN:RESET;
         RUN:     r_next_state = lfsr_done ? DONE:RUN;
         DONE:    r_next_state = RESET;
         default: r_next_state = STATEX;
      endcase
   end
   
   //next logic (combo+ff)    //test mode ? 1-internal : 0-external 
   assign lfsr_en   = i_mode ? (r_next_state == RUN) : i_en;
   assign lfsr_load = i_en;

   lfsr #(
      .NUM_BITS(DATA_WIDTH)
   ) lfsr_0 (
      .i_clk         (i_clk),
      .i_rst         (i_rst),

      .i_en          (lfsr_en),
      .i_load        (lfsr_load),
      .i_data        (i_data),
      .i_stop_code   (i_stop_code),
      
      .o_lfsr_vld    (o_vld),
      .o_lfsr_data   (o_data),
      .o_lfsr_done   (lfsr_done)
   );

   assign o_done = (r_next_state == DONE); 
   
endmodule
