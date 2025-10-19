/*
* Name: controller.sv
*
* Description:
* This is the control path implemenation of the matrix multipler.
*/

module controller #(parameter WIDTH=8, ROW=4, COL=4, W_SIZE=256, I_SIZE=256, O_SIZE=256) (
  input  logic                          clk_i,            // clock signal
  input  logic                          rstn_i,           // active low reset signal

  // output done
  input  logic                          start_i,          // active high start calculation, must pull down to 0 first to start a new calculation
  output logic                          done_o,           // data controls

  // output buffer memory control
  output  logic                         ob_mem_cenb_o,    // memory enable, active low
  output  logic                         ob_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(O_SIZE)-1:0]    ob_mem_addr_o,    // address

  // input buffer memory control
  output  logic                         ib_mem_cenb_o,    // memory enable, active low
  output  logic                         ib_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(I_SIZE)-1:0]    ib_mem_addr_o,    // address

  // weights buffer memory control
  output  logic                         wb_mem_cenb_o,    // memory enable, active low
  output  logic                         wb_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(W_SIZE)-1:0]    wb_mem_addr_o,    // address

  // partial sum buffer memory
  // not using partial sum buffer memory for now (no tiling)

  // pe control signals
  output  logic [ROW*COL-1:0]           ctrl_load_o,        // if high, load into weights register; else, maintain weights register
  output  logic [ROW*COL-1:0]           ctrl_sum_out_o     // if high, send adder result to output; else, send north_i to south_o
);

// declare local parameters
localparam LOAD_CNT = ROW + 2;
localparam IN_CNT = LOAD_CNT + COL + 1;
localparam IN_OUT_CNT = IN_CNT + I_SIZE - 3;
localparam OUT_CNT = IN_OUT_CNT + COL + 1;

// declare internal signals
state_struct                            state_r, next_state_r;  // present & next states
logic [$clog2(OUT_CNT)-1:0]             count_r;

// present state logic
always_ff @(posedge clk_i or negedge rstn_i) // active low asynch reset
    if (!rstn_i)    state_r <= IDLE;
    else            state_r <= next_state_r;

// combinational next state logic
always_comb begin
    next_state_r = STATEX;
    case (state_r)
        IDLE:       if (start_i)                        next_state_r = LOAD;
                    else                                next_state_r = IDLE;
        LOAD:       if (count_r == LOAD_CNT - 1)        next_state_r = IN;      // takes 1 additional cycle to finish loading memory
                    else                                next_state_r = LOAD;
        IN:         if (count_r == IN_CNT - 1)          next_state_r = IN_OUT;
                    else                                next_state_r = IN;
        IN_OUT:     if (count_r == IN_OUT_CNT - 1)      next_state_r = OUT;
                    else                                next_state_r = IN_OUT;
        OUT:        if (count_r == OUT_CNT - 1)         next_state_r = DONE;
                    else                                next_state_r = OUT;           
        DONE:                                           next_state_r = IDLE;    // only stays in DONE for 1 cycle
        default:                                        next_state_r = STATEX;
    endcase
end

// sequential address logic
always_ff @(posedge clk_i or negedge rstn_i)
    if(!rstn_i) count_r <= 0;
    else begin
        // default assignments
        count_r <= count_r + 1;
        case (state_r)
            IDLE:       count_r <= 0;
            LOAD:       ;
            IN:         ;
            IN_OUT:     ;
            OUT:        ;
            DONE:       ;
            default:    begin // generate error
                            count_r <= 'x;
                        end
        endcase
    end

// next state output logic
always_ff @(posedge clk_i or negedge rstn_i)
    if(!rstn_i) begin // reset assignments
        done_o <=  1'b0;

        ob_mem_cenb_o <= 1'b1; // active low
        ob_mem_wenb_o <= 1'b1; // active low
        ob_mem_addr_o <= '0; // default address pointed at 0x00

        ib_mem_cenb_o <= 1'b1; // active low
        ib_mem_wenb_o <= 1'b1; // active low
        ib_mem_addr_o <= '0; // default address pointed at 0x00

        wb_mem_cenb_o <= 1'b1; // active low
        wb_mem_wenb_o <= 1'b1; // active low
        wb_mem_addr_o <= '0; // default address pointed at 0x00

        ctrl_load_o <= '0;
        ctrl_sum_out_o <= '1;
    end
    else begin
        // default assignments
        done_o <= done_o;

        ob_mem_cenb_o <= 1'b1; // active low
        ob_mem_wenb_o <= 1'b1; // active low
        ob_mem_addr_o <= '0; // default address pointed at 0x00

        ib_mem_cenb_o <= 1'b1; // active low
        ib_mem_wenb_o <= 1'b1; // never write input memory
        ib_mem_addr_o <= '0; // default address pointed at 0x00

        wb_mem_cenb_o <= 1'b1; // active low
        wb_mem_wenb_o <= 1'b1; // never write weight memory
        wb_mem_addr_o <= '0; // default address pointed at 0x00

        ctrl_load_o <= '0; // maintain weight registers
        ctrl_sum_out_o <= '1; // pass partial sums to next row
        
        // next state output logic
        case (next_state_r)
            IDLE:       ;
            LOAD:       begin
                            done_o <= 1'b0;

                            wb_mem_cenb_o <= 1'b0; // read weights memory
                            wb_mem_addr_o <= count_r;

                            ctrl_load_o <= (wb_mem_addr_o == COL - 1) ? ('1) : ('0); // on last weight address, load in weight regs
                            ctrl_sum_out_o <= '0; // pass inputs to next row
                        end
            IN:         begin
                            ib_mem_cenb_o <= 1'b0; // read inputs memory
                            ib_mem_addr_o <= count_r - LOAD_CNT + 1;
                        end
            IN_OUT:     begin
                            ib_mem_cenb_o <= 1'b0; // read inputs memory
                            ib_mem_addr_o <= count_r - LOAD_CNT + 1;

                            ob_mem_cenb_o <= 1'b0; // enable outputs memory
                            ob_mem_wenb_o <= 1'b0; // write outputs memory
                            ob_mem_addr_o <= count_r - IN_CNT + 1;
                        end
            OUT:        begin
                            ob_mem_cenb_o <= 1'b0; // enable outputs memory
                            ob_mem_wenb_o <= 1'b0; // write outputs memory
                            ob_mem_addr_o <= count_r - IN_CNT + 1;
                        end
            DONE:       done_o <= 1'b1;
            default:    begin
                            // all states to X (error encountered)
                            {done_o, ctrl_load_o, ctrl_sum_out_o} <= 'x;
                            {ob_mem_cenb_o, ob_mem_wenb_o, ob_mem_addr_o} <= 'x;
                            {ib_mem_cenb_o, ib_mem_wenb_o, ib_mem_addr_o} <= 'x;
                            {wb_mem_cenb_o, wb_mem_wenb_o, wb_mem_addr_o} <= 'x;
                        end
        endcase
    end

endmodule