/*
* Name: controller.sv
*
* Description:
* This is the control path implemenation of the matrix multipler for the memory mode.
*/

module controller #(parameter WIDTH=8, ROW=4, COL=4, W_SIZE=256, I_SIZE=256, O_SIZE=256) (
  input  logic                          clk_i,            // clock signal
  input  logic                          rstn_i,           // active low reset signal
  input  logic                          start_i,          // active high start calculation, must pull down to 0 first to start a new calculation
  input  data_config_struct             config_i,         // test controls
  output logic                          done_o,           // data controls

  // output buffer memory control
  output  logic                         ob_mem_cenb_o,    // memory enable, active low
  output  logic                         ob_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(O_SIZE)-1:0]    ob_mem_addr_o,    // address

  // input buffer memory control
  output  logic                         ib_mem_cenb_o,    // memory enable, active low
  output  logic                         ib_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(I_SIZE)-1:0]    ib_mem_addr_o,    // address
  input   logic [ROW-1:0][WIDTH-1:0]    ib_mem_data_i,    // input data

  // weights buffer memory control
  output  logic                         wb_mem_cenb_o,    // memory enable, active low
  output  logic                         wb_mem_wenb_o,    // write enable, active low
  output  logic [$clog2(W_SIZE)-1:0]    wb_mem_addr_o,    // address
  input   logic [COL-1:0][WIDTH-1:0]    wb_mem_data_i,    // input data

  // pe control signals
  output  logic [0:ROW-1][0:COL-1]      ctrl_load_o,      // control weights register
  output  logic [0:ROW-1][0:COL-1]      ctrl_sum_out_o,   // control output selection
  output  logic [0:ROW-1][0:COL-1]      ctrl_ps_in_o,     // control addition carry-in
  output  logic [0:ROW-1][0:COL-1]      ctrl_ps_valid_o   // control partial sums register validity
);

// declare internal signals
state_struct                                    state_r, next_state_r;  // present & next states
logic [$clog2(W_SIZE + I_SIZE + 2*ROW)-1:0]     count_r;                // states transition counter
logic [0:ROW-1][0:COL-1]                        next_ps_valid_b;        // used to calculate next ctrl_ps_valid_o combinationally

// sequential present state logic
always_ff @(posedge clk_i or negedge rstn_i) // active low asynch reset
    if (!rstn_i)    state_r <= IDLE;
    else            state_r <= next_state_r;

// combinational next state logic
always_comb begin
    next_state_r = STATEX;
    case (state_r)
        IDLE:   if (config_i.extra_config[0]) begin
                    if (start_i)                                    next_state_r = IN;
                    else                                            next_state_r = IDLE;
                end 
                else begin
                    if (start_i)                                    next_state_r = LOAD;
                    else                                            next_state_r = IDLE;
                end
        LOAD:       if (count_r == ROW + 1)                         next_state_r = IN;
                    else                                            next_state_r = LOAD;
        IN:     if (config_i.extra_config[0]) begin
                    if (count_r == config_i.w_rows + ROW + 1)       next_state_r = OUT;
                    else                                            next_state_r = IN;
                end 
                else begin
                    if (count_r == 2*ROW + 2)                       next_state_r = IN_OUT;
                    else                                            next_state_r = IN;
                end
        IN_OUT:     if (count_r == ROW + 2 + config_i.i_rows)       next_state_r = OUT;
                    else                                            next_state_r = IN_OUT;
        OUT:    if (config_i.extra_config[0]) begin
                    if (count_r == config_i.w_rows + 2*ROW + 1)     next_state_r = DONE;
                    else                                            next_state_r = OUT;
                end 
                else begin
                    if (count_r == ROW + COL + config_i.i_rows + 3) next_state_r = DONE;
                    else                                            next_state_r = OUT; 
                end
        DONE:                                                       next_state_r = IDLE;
        default:                                                    next_state_r = STATEX;
    endcase
end

// combinational next ctrl_ps_valid_o logic
always_comb begin
    next_ps_valid_b = '0; // default
    case (state_r)
        IDLE:   ;
        LOAD:   ;
        IN:     if (config_i.extra_config[0]) begin
                    next_ps_valid_b = ctrl_ps_valid_o;
                    if (count_r == 1) begin
                        for (int i = 0; i < ROW; i++) begin
                            for (int j = 0; j < COL; j++) begin
                                // all bits 0 except for index (0, 0) = 1
                                next_ps_valid_b[i][j] = (i == 0 && j == 0) ? 1'b1 : 1'b0;
                            end
                        end
                    end
                    else begin
                        // push all rows down by 1
                        for (int i = ROW-1; i > 0; i--) begin
                            for (int j = 0; j < COL; j++) begin
                                next_ps_valid_b[i][j] = next_ps_valid_b[i-1][j];
                            end
                        end

                        // create new first row
                        if (count_r < (config_i.w_rows - COL + 2)) begin
                            for (int j = 0; j < COL; j++) begin
                                // 1 0 0 --> 1 1 0 --> 1 1 1
                                next_ps_valid_b[0][j] = (j < count_r) ? 1'b1 : 1'b0;
                            end
                        end
                        else begin
                            for (int j = 0; j < COL; j++) begin
                                // 1 1 1 --> 1 1 0 ---> 1 0 0 
                                next_ps_valid_b[0][j] = (j > count_r - (config_i.w_rows - COL + 2)) ? 1'b1 : 1'b0;
                            end
                        end
                    end
                end
        IN_OUT: ;
        OUT:    ;
        DONE:   ;
        default:    next_ps_valid_b = 'x;
    endcase
end

// sequential counter logic
always_ff @(posedge clk_i or negedge rstn_i)
    if(!rstn_i) count_r <= 0;
    else begin
        count_r <= count_r + 1;
        case (next_state_r)
            IDLE:       count_r <= 0;
            LOAD:       ;
            IN:         ;
            IN_OUT:     ;
            OUT:        ;
            DONE:       ;
            default:    count_r <= 'x;
        endcase
    end

// next state output logic
always_ff @(posedge clk_i or negedge rstn_i)
    if(!rstn_i) begin // reset assignments
        done_o          <=  1'b0;   // done

        ib_mem_cenb_o   <= 1'b1;    // active low
        ib_mem_wenb_o   <= 1'b1;    // active low
        wb_mem_cenb_o   <= 1'b1;    // active low
        wb_mem_wenb_o   <= 1'b1;    // active low
        ob_mem_cenb_o   <= 1'b1;    // active low
        ob_mem_wenb_o   <= 1'b1;    // active low

        ib_mem_addr_o   <= config_i.i_offset;      // default address pointed at input addr offset
        wb_mem_addr_o   <= config_i.w_offset;      // default address pointed at weight addr offset
        ob_mem_addr_o   <= config_i.o_offset_w;    // default address pointed at output addr offset

        ctrl_load_o     <= '0;
        ctrl_ps_in_o    <= '0;
        ctrl_sum_out_o  <= '0;
        ctrl_ps_valid_o <= '0;
    end
    else begin
        // default assignments
        done_o <= done_o;

        ib_mem_cenb_o   <= 1'b1;    // active low
        ib_mem_wenb_o   <= 1'b1;    // active low
        wb_mem_cenb_o   <= 1'b1;    // active low
        wb_mem_wenb_o   <= 1'b1;    // active low
        ob_mem_cenb_o   <= 1'b1;    // active low
        ob_mem_wenb_o   <= 1'b1;    // active low

        ib_mem_addr_o   <= config_i.i_offset;      // default address pointed at input addr offset
        wb_mem_addr_o   <= config_i.w_offset;      // default address pointed at weight addr offset
        ob_mem_addr_o   <= config_i.o_offset_w;    // default address pointed at output addr offset

        ctrl_load_o                     <= '0;  // maintain weight registers
        ctrl_sum_out_o                  <= '1;  // set south output of pe as the computation result
        ctrl_ps_valid_o                 <= '0;  // by default, partial sums regs not valid

        // weight stationary: first row '1; other rows '0 to flow down partial sums
        // output stationary: all rows '1 as we are flowing down weights
        ctrl_ps_in_o[0][0:COL-1]        <= '1;
        for (int r = 1; r < ROW; r++) begin
            ctrl_ps_in_o[r][0:COL-1]    <= config_i.extra_config[0] ? '1 : '0;
        end
        
        // next state output logic
        case (next_state_r)
            IDLE:       ;
            LOAD:       begin
                            wb_mem_cenb_o <= 1'b0; // read weights memory
                            wb_mem_addr_o <= config_i.w_offset + count_r;

                            done_o <= 1'b0;
                            ctrl_sum_out_o <= '0; // flow down weights from north to south

                            // at the end of this state, load in weight regs for 1 cycle
                            ctrl_load_o <= (wb_mem_addr_o == ROW - 1) ? '1 : '0; 
                        end
            IN:         begin
                            ib_mem_cenb_o <= 1'b0; // read inputs memory
                            ib_mem_addr_o <= (config_i.extra_config[0] ? count_r : (count_r - ROW - 1)) + config_i.i_offset;

                            wb_mem_cenb_o <= config_i.extra_config[0] ? 1'b0 : 1'b1; // flow down weights (for output stationary mode)
                            wb_mem_addr_o <= (config_i.extra_config[0] ? count_r : '0) + config_i.w_offset;

                            ctrl_ps_valid_o <= next_ps_valid_b; // increment partial sums controls

                            // for output stationary, at the end of this state, unload partial sums regs for 1 cycle
                            ctrl_sum_out_o <= config_i.extra_config[0] ? ((count_r == config_i.w_rows + ROW) ? '1 : '0) : '1;
                        end
            IN_OUT:     begin
                            ib_mem_cenb_o <= 1'b0; // read inputs memory
                            ib_mem_addr_o <= config_i.extra_config[0] ? count_r : (count_r - ROW - 1) + config_i.i_offset;

                            wb_mem_cenb_o <= config_i.extra_config[0] ? 1'b0 : 1'b1; // read weights memory (for output stationary mode)
                            wb_mem_addr_o <= (config_i.extra_config[0] ? count_r : '0) + config_i.w_offset;

                            ob_mem_cenb_o <= 1'b0; // enable outputs memory
                            ob_mem_wenb_o <= 1'b0; // write outputs memory
                            ob_mem_addr_o <= (config_i.extra_config[0] ? (count_r - ROW) : (count_r - 2*ROW - 2)) + config_i.o_offset_w;

                            ctrl_ps_valid_o <= next_ps_valid_b; // increment partial sums controls
                        end
            OUT:        begin
                            ob_mem_cenb_o <= 1'b0; // enable outputs memory
                            ob_mem_wenb_o <= 1'b0; // write outputs memory
                            ob_mem_addr_o <= (config_i.extra_config[0] ? (count_r - config_i.w_rows - ROW - 1) : (count_r - 2*ROW - 2)) + config_i.o_offset_w;
                        
                            ctrl_ps_valid_o <= next_ps_valid_b; // increment partial sums controlsd
                            ctrl_sum_out_o <= config_i.extra_config[0] ? '0 : '1; // for output stationary mode, flow north input to south output
                        end
            DONE:           done_o <= 1'b1;
            default:    begin
                            // all states to X (error encountered)
                            {done_o, ctrl_load_o, ctrl_sum_out_o, ctrl_ps_in_o, ctrl_ps_valid_o} <= 'x;
                            {ob_mem_cenb_o, ob_mem_wenb_o, ob_mem_addr_o} <= 'x;
                            {ib_mem_cenb_o, ib_mem_wenb_o, ib_mem_addr_o} <= 'x;
                            {wb_mem_cenb_o, wb_mem_wenb_o, wb_mem_addr_o} <= 'x;
                        end
        endcase
    end

endmodule