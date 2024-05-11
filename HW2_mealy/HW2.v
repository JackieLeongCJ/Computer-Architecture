module ALU #(
    parameter DATA_W = 32
)
(
    input                       i_clk,   // clock
    input                       i_rst_n, // reset

    input                       i_valid, // input valid signal
    input [DATA_W - 1 : 0]      i_A,     // input operand A
    input [DATA_W - 1 : 0]      i_B,     // input operand B
    input [         2 : 0]      i_inst,  // instruction

    output [2*DATA_W - 1 : 0]   o_data,  // output value
    output                      o_done   // output valid signal
);
// Do not Modify the above part !!!

// Parameters
    // ======== choose your FSM style ==========
    // 1. FSM based on operation cycles
    parameter S_IDLE           = 2'd0;
    parameter S_ONE_CYCLE_OP   = 2'd1;
    parameter S_MULTI_CYCLE_OP = 2'd2;
    // 2. FSM based on operation modes
    // parameter S_IDLE = 4'd0;
    // parameter S_ADD  = 4'd1;
    // parameter S_SUB  = 4'd2;
    // parameter S_AND  = 4'd3;
    // parameter S_OR   = 4'd4;
    // parameter S_SLT  = 4'd5;
    // parameter S_SLL  = 4'd6;
    // parameter S_MUL  = 4'd7;
    // parameter S_DIV  = 4'd8;
    // parameter S_OUT  = 4'd9;
    //
    parameter ADD       = 3'd0;
    parameter SUB       = 3'd1;
    parameter AND       = 3'd2;
    parameter OR        = 3'd3;
    parameter SLT       = 3'd4;
    parameter SLL       = 3'd5;
    parameter MUL       = 3'd6;
    parameter DIV       = 3'd7;

// Wires & Regs
    // Todo
    // state
    reg  [         1: 0] state, state_nxt; // remember to expand the bit width if you want to add more states!
    // load input
    reg  [  DATA_W-1: 0] operand_a, operand_a_nxt;
    reg  [  DATA_W-1: 0] operand_b, operand_b_nxt;
    reg  [         2: 0] inst, inst_nxt;
    reg  [         4: 0] cnt, cnt_nxt;
    reg  [2*DATA_W: 0] s_reg, s_reg_nxt;
    reg  [        32: 0] aluout; 
// Wire Assignments
    // Todo
    assign o_done = (s_reg[64])? 1'b1 : 1'b0;
    assign o_data = (s_reg[64])? s_reg[63:0] : 64'b0;
// Always Combination
    // load input
    always @(*) begin
        if (i_valid) begin
            operand_a_nxt = i_A;
            operand_b_nxt = i_B;
            inst_nxt      = i_inst;
        end
        else begin
            operand_a_nxt = operand_a;
            operand_b_nxt = operand_b;
            inst_nxt      = inst;
        end
    end
    // Todo: FSM , NL
    always @(*) begin
        case(state)
            S_IDLE: begin
                if (!i_valid) state_nxt = S_IDLE;
                else begin
                    case (i_inst)
                        MUL : state_nxt = S_MULTI_CYCLE_OP;
                        DIV : state_nxt = S_MULTI_CYCLE_OP;
                        default: state_nxt = S_ONE_CYCLE_OP;
                    endcase
                end
            end
            S_ONE_CYCLE_OP: state_nxt = S_IDLE;
            S_MULTI_CYCLE_OP: state_nxt = (cnt == 5'd31)? S_IDLE : S_MULTI_CYCLE_OP;
            default: state_nxt = S_IDLE;
        endcase
    end

    // Todo: Counter
    always @(*) begin
        if (state == S_MULTI_CYCLE_OP) cnt_nxt = cnt + 5'd1;
        else cnt_nxt = 5'd0;
    end

    // Todo: ALU output
    always @(*) begin
        case (state)
            S_ONE_CYCLE_OP  :begin
                case (inst)
                    ADD : aluout[32:0] = s_reg[31:0] + operand_b[31:0]; 
                    SUB : aluout[32:0] = s_reg[31:0] - operand_b[31:0]; 
                    AND : aluout[32:0] = s_reg[31:0] & operand_b[31:0];
                    OR  : aluout[32:0] = s_reg[31:0] | operand_b[31:0];
                    SLT : aluout[32:0] = {30'b0, $signed(s_reg[31:0]) < $signed(operand_b[31:0])};
                    SLL : aluout[32:0] = s_reg[31:0] << operand_b;
                    default: aluout[32:0] = 33'b0;
                endcase
            end

            S_MULTI_CYCLE_OP: begin
                if (inst == MUL) aluout[32:0] = (s_reg[0])? s_reg[63:32] + operand_b[31:0] : {1'b0, s_reg[63:32]};
                else begin
                    if (s_reg[63:32] >= operand_b) aluout[32:0] = {1'b1, s_reg[63:32] - operand_b};
                    else aluout[32:0] = {1'b0, s_reg[63:32]};
                end
            end 

            default: aluout[32:0] = 33'b0;
        endcase
    end
    // Todo: output valid signal (OL)
    // shift register logic
    always @(*) begin
        case(state)
            S_IDLE: begin
                if (i_valid) begin
                    if (i_inst == DIV) s_reg_nxt = {32'b0, i_A, 1'b0}; // (i_A << 1)div shift left 1 bit
                    else s_reg_nxt = {33'b0, i_A};
                end
                else s_reg_nxt = 65'b0;
            end
            S_ONE_CYCLE_OP: begin
                case (inst)
                    ADD : begin
                        if ((s_reg[31] == 1'b1) && (operand_b[31] == 1'b1) && (aluout[31] == 1'b0)) begin //negative overflow
                        s_reg_nxt = {1'b1,32'b0, 1'b1, 31'b0};
                        end
                        else if ((s_reg[31] == 1'b0) && (operand_b[31] == 1'b0) && (aluout[31] == 1'b1)) begin //positive overflow
                        s_reg_nxt = {1'b1,33'b0, {31{1'b1}}};
                        end
                        else s_reg_nxt = {1'b1,32'b0, aluout[31:0]};
                    end

                    SUB : begin
                        if ((s_reg[31] == 1'b1) && (operand_b[31] == 1'b0) && (aluout[31] == 1'b0)) begin //negative overflow
                        s_reg_nxt = {1'b1,32'b0, 1'b1, 31'b0};
                        end
                        else if ((s_reg[31] == 1'b0) && (operand_b[31] == 1'b1) && (aluout[31] == 1'b1)) begin //positive overflow
                        s_reg_nxt = {1'b1,33'b0, {31{1'b1}}};
                        end
                        else s_reg_nxt = {1'b1,32'b0, aluout[31:0]};
                    end
                    AND : s_reg_nxt = {1'b1,32'b0, aluout[31:0]};
                    OR  : s_reg_nxt = {1'b1,32'b0, aluout[31:0]};
                    SLT : s_reg_nxt = {1'b1,32'b0, aluout[31:0]};
                    SLL : s_reg_nxt = {1'b1,32'b0, aluout[31:0]};
                    default: s_reg_nxt = 65'b0;
                endcase
            end

            S_MULTI_CYCLE_OP: begin
                if (inst == MUL) begin
                    if (cnt == 5'd31) s_reg_nxt = {1'b1,aluout[32:0], s_reg[31:1]};
                    else s_reg_nxt = {aluout[32:0], s_reg[31:1]};
                end
                else begin
                    if (cnt == 5'd31) s_reg_nxt = {1'b1,aluout[31:0], s_reg[30:0],aluout[32]};
                    else s_reg_nxt = ({aluout[31:0],s_reg[31:0]} << 1) + aluout[32];
                end
            end

            default: s_reg_nxt = 65'b0;            
        endcase
    end
    // Todo: Sequential always block CS(FSM)
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state       <= S_IDLE;
            operand_a   <= 0;
            operand_b   <= 0;
            inst        <= 0;
        end
        else begin
            state       <= state_nxt;
            operand_a   <= operand_a_nxt;
            operand_b   <= operand_b_nxt;
            inst        <= inst_nxt;
            cnt         <= cnt_nxt;
            s_reg       <= s_reg_nxt;
        end
    end

endmodule