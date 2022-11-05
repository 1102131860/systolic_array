
module signature_analyzer 
#(
   parameter DATA_WIDTH = 54 // x-18 y-18 z-18
)
(
   input  logic                  i_clk,
   input  logic                  i_rst,

   input  logic                  i_mode,
   input  logic                  i_stop,
   
   input  logic                  i_seed_vld,
   input  logic [DATA_WIDTH-1:0] i_seed_data,

   input  logic                  i_dut_vld,
   input  logic [DATA_WIDTH-1:0] i_dut_data,
   
   output logic                  o_vld,
   output logic [DATA_WIDTH-1:0] o_data
);

   import pseudo_rand_num_gen_pkg::*;

   st_prng_state          r_state, r_next_state;
   logic                  misr_en, misr_load, misr_done, misr_vld;
   logic [DATA_WIDTH-1:0] misr_data_in, misr_data_out;
   logic                  set_seed, set_data;
   
   //state update (ff)
   always_ff @(posedge i_clk or posedge i_rst) 
      if(i_rst)   r_state <= RESET;
      else        r_state <= r_next_state;
   
   //next state (combo)
   always_comb begin
	  r_next_state     = STATEX;
      case (r_state)
	     RESET:   r_next_state =(set_seed || i_dut_vld) ? RUN:RESET;
         RUN:     r_next_state = i_stop ? DONE:RUN;
         DONE:    r_next_state = RESET;
         default: r_next_state = STATEX;
      endcase
   end
   
   //next logic (combo+ff)
   assign set_seed      = i_mode ? (i_seed_vld && (r_state == RESET)) : 1'b0;
   assign set_data      = i_mode ? 1'b0 : i_dut_vld;
   assign misr_en       = set_seed || i_dut_vld;
   assign misr_load     = set_seed || set_data;
   assign misr_data_in  = set_seed ? i_seed_data : i_dut_data;

   misr #(
      .NUM_BITS(DATA_WIDTH)
   ) misr_0 (
      .i_clk         (i_clk),
      .i_rst         (i_rst),

      .i_en          (misr_en),
      .i_load        (misr_load),
      .i_data        (misr_data_in),
      
      .o_misr_vld    (misr_vld),
      .o_misr_data   (misr_data_out)
   );
   
   assign o_vld = i_mode ? (r_next_state == DONE) : misr_vld;
   assign o_data = misr_data_out;
endmodule
