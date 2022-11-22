
module signature_analyzer 
#(
   parameter DATA_WIDTH = 54 // x-18 y-18 z-18
)
(
   input  logic                  i_clk,
   input  logic                  i_rst,

   input  logic                  i_mode,
   input  logic                  i_stop,
   
   input  logic [DATA_WIDTH-1:0] i_seed_data,

   input  logic                  i_dut_vld,
   input  logic [DATA_WIDTH-1:0] i_dut_data,
   
   output logic                  o_vld,
   output logic [DATA_WIDTH-1:0] o_data
);

   import pseudo_rand_num_gen_pkg::*;

   st_prng_state          r_state, r_next_state;
   logic                  misr_done;
   
   //state update (ff)
   always_ff @(posedge i_clk or posedge i_rst) 
      if(i_rst)   r_state <= IDLE;
      else        r_state <= r_next_state;
   
   //next state (combo)
   always_comb begin
      case (r_state)
	     IDLE:   r_next_state = RUN;
         RUN:     r_next_state = i_stop ? DONE:RUN;
         DONE:    r_next_state = DONE;
         default: r_next_state = IDLE;
      endcase
   end
   
   //next logic (combo+ff)
   assign misr_done  = r_next_state == DONE;

   misr #(
      .NUM_BITS(DATA_WIDTH)
   ) misr_0 (
      .i_clk         (i_clk),
      .i_rst         (i_rst),

      .i_mode        (i_mode),
      .i_done        (misr_done),
      .i_seed_data   (i_seed_data),
      .i_vld         (i_dut_vld),
      .i_data        (i_dut_data),
      
      .o_misr_vld    (o_vld),
      .o_misr_data   (o_data)
   );
   
endmodule
