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
    // parameter S_IDLE           = 2'd0;
    // parameter S_ONE_CYCLE_OP   = 2'd1;
    // parameter S_MULTI_CYCLE_OP = 2'd2;
    // 2. FSM based on operation modes
    parameter S_IDLE = 4'd0;
    parameter S_ADD  = 4'd1;
    parameter S_SUB  = 4'd2;
    parameter S_AND  = 4'd3;
    parameter S_OR   = 4'd4;
    parameter S_SLT  = 4'd5;
    parameter S_SLL  = 4'd6;
    parameter S_MUL  = 4'd7;
    parameter S_DIV  = 4'd8;
    parameter S_OUT  = 4'd9;
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
    reg  [         3: 0] state, state_nxt; // remember to expand the bit width if you want to add more states!
    // load input
    reg  [  DATA_W-1: 0] operand_a, operand_a_nxt;
    reg  [  DATA_W-1: 0] operand_b, operand_b_nxt;
    reg  [         2: 0] inst, inst_nxt;
    reg  [         4: 0] cnt, cnt_nxt;
    reg  [2*DATA_W-1: 0] s_reg, s_reg_nxt;
    reg  [        32: 0] aluout; 
// Wire Assignments
    // Todo
    assign o_done = (state == S_OUT)? 1'b1 : 1'b0;
    assign o_data = (state == S_OUT)? s_reg[63:0] : 64'b0;
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
                        ADD: state_nxt = S_ADD;
                        SUB: state_nxt = S_SUB;
                        AND: state_nxt = S_AND;
                        OR : state_nxt = S_OR;
                        SLT: state_nxt = S_SLT;
                        SLL: state_nxt = S_SLL;
                        MUL: state_nxt = S_MUL;
                        DIV: state_nxt = S_DIV;
                        default: state_nxt = S_IDLE;
                    endcase
                end
            end
            S_ADD : state_nxt = S_OUT;
            S_SUB : state_nxt = S_OUT;
            S_AND : state_nxt = S_OUT;
            S_OR  : state_nxt = S_OUT;
            S_SLT : state_nxt = S_OUT;
            S_SLL : state_nxt = S_OUT;
            S_MUL : state_nxt = (cnt == 5'd31)? S_OUT : S_MUL;
            S_DIV : state_nxt = (cnt == 5'd31)? S_OUT : S_DIV;
            S_OUT : state_nxt = S_IDLE;
            default: state_nxt = S_IDLE;
        endcase
    end

    // Todo: Counter
    always @(*) begin
        if ((state == S_MUL) || (state == S_DIV)) cnt_nxt = cnt + 5'd1;
        else cnt_nxt = 5'd0;
    end

    // Todo: ALU output
    always @(*) begin
        case(state)   
            S_ADD : aluout[32:0] = s_reg[31:0] + operand_b[31:0]; 
            S_SUB : aluout[32:0] = s_reg[31:0] - operand_b[31:0];
            S_AND : aluout[32:0] = s_reg[31:0] & operand_b[31:0];
            S_OR  : aluout[32:0] = s_reg[31:0] | operand_b[31:0];
            S_SLT : aluout[32:0] = {30'b0, $signed(s_reg[31:0]) < $signed(operand_b[31:0])};
            S_SLL : aluout[32:0] = s_reg[31:0] << operand_b;
            S_MUL : aluout[32:0] = (s_reg[0])? s_reg[63:32] + operand_b[31:0] : {1'b0, s_reg[63:32]};
            S_DIV : begin
                if (s_reg[63:32] >= operand_b) aluout[32:0] = {1'b1, s_reg[63:32] - operand_b};
                else aluout[32:0] = {1'b0, s_reg[63:32]};
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
                    if (i_inst == DIV) s_reg_nxt = {31'b0, i_A, 1'b0}; // (i_A << 1)div shift left 1 bit
                    else s_reg_nxt = {32'b0, i_A};
                end
                else s_reg_nxt = 64'b0;
            end
            S_ADD : begin
                if ((s_reg[31] == 1'b1) && (operand_b[31] == 1'b1) && (aluout[31] == 1'b0)) begin //negative overflow
                    s_reg_nxt = {32'b0, 1'b1, 31'b0};
                end
                else if ((s_reg[31] == 1'b0) && (operand_b[31] == 1'b0) && (aluout[31] == 1'b1)) begin //positive overflow
                    s_reg_nxt = {33'b0, {31{1'b1}}};
                end
                else s_reg_nxt = {32'b0, aluout[31:0]};
            end
            S_SUB :begin
                if ((s_reg[31] == 1'b1) && (operand_b[31] == 1'b0) && (aluout[31] == 1'b0)) begin //negative overflow
                    s_reg_nxt = {32'b0, 1'b1, 31'b0};
                end
                else if ((s_reg[31] == 1'b0) && (operand_b[31] == 1'b1) && (aluout[31] == 1'b1)) begin //positive overflow
                    s_reg_nxt = {33'b0, {31{1'b1}}};
                end
                else s_reg_nxt = {32'b0, aluout[31:0]};
            end
            S_AND : s_reg_nxt = {32'b0, aluout[31:0]};
            S_OR  : s_reg_nxt = {32'b0, aluout[31:0]};
            S_SLT : s_reg_nxt = {32'b0, aluout[31:0]};
            S_SLL : s_reg_nxt = {32'b0, aluout[31:0]};
            S_MUL : s_reg_nxt = {aluout[32:0], s_reg[31:1]}; // >> 1
            S_DIV : begin
                if (cnt == 5'd31) s_reg_nxt = {aluout[31:0], s_reg[30:0],aluout[32]};
                else s_reg_nxt = ({aluout[31:0],s_reg[31:0]} << 1) + aluout[32];
            end
            S_OUT : s_reg_nxt = s_reg;
            default: s_reg_nxt = 64'b0;
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