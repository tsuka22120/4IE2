// ALU Simplified - DigitalJS Block Diagram
// Modules: instruction_decoder, alu_core, register_file, alu_top (top)

// ============================================================
// Module 1: instruction_decoder
// ============================================================
module instruction_decoder (
    input  wire [15:0] iInstruction,
    input  wire [7:0]  iIX,
    output wire [6:0]  oOpCode,
    output wire        oIxBit,
    output wire [7:0]  oOperand,
    output reg  [7:0]  oEffOperand
);
    assign oOpCode  = iInstruction[15:9];
    assign oIxBit   = iInstruction[8];
    assign oOperand = iInstruction[7:0];
    always @(iInstruction, iIX) begin
        if (iInstruction[8] == 1'b0)
            oEffOperand = iInstruction[7:0];
        else
            oEffOperand = iIX + iInstruction[7:0];
    end
endmodule

// ============================================================
// Module 2: alu_core
// Uses 9-bit r_tmp so oResult is not read back (avoids Yosys proc issues)
// ============================================================
module alu_core (
    input  wire [6:0] iOpCode,
    input  wire [7:0] iAcc,
    input  wire [7:0] iEffOperand,
    input  wire [3:0] iSR,
    output reg  [7:0] oResult,
    output reg  [7:0] oIxResult,
    output reg  [3:0] oFlags,
    output reg        oAccWe,
    output reg        oIxWe
);
    parameter OP_NOP   = 7'b0000000;
    parameter OP_ADD   = 7'b0000001;
    parameter OP_SUB   = 7'b0000010;
    parameter OP_AND   = 7'b0000011;
    parameter OP_OR    = 7'b0000100;
    parameter OP_XOR   = 7'b0000101;
    parameter OP_MOV   = 7'b0001000;
    parameter OP_MOVIX = 7'b0001001;

    // 9-bit temp: bit[8]=carry/borrow, bit[7:0]=result
    // Using r_tmp avoids reading back output regs in the same always block
    reg [8:0] r_tmp;

    always @(iOpCode, iAcc, iEffOperand, iSR) begin
        oResult   = iAcc;
        oIxResult = 8'h00;
        oFlags    = iSR;
        oAccWe    = 1'b0;
        oIxWe     = 1'b0;
        r_tmp     = 9'h000;
        case (iOpCode)
            OP_ADD: begin
                r_tmp   = {1'b0, iAcc} + {1'b0, iEffOperand};
                oResult = r_tmp[7:0];
                oFlags  = {r_tmp[8], (r_tmp[7:0] == 8'h00), r_tmp[7], 1'b0};
                oAccWe  = 1'b1;
            end
            OP_SUB: begin
                r_tmp   = {1'b0, iAcc} - {1'b0, iEffOperand};
                oResult = r_tmp[7:0];
                oFlags  = {r_tmp[8], (r_tmp[7:0] == 8'h00), r_tmp[7], 1'b0};
                oAccWe  = 1'b1;
            end
            OP_AND: begin
                r_tmp   = {1'b0, iAcc & iEffOperand};
                oResult = r_tmp[7:0];
                oFlags  = {1'b0, (r_tmp[7:0] == 8'h00), r_tmp[7], 1'b0};
                oAccWe  = 1'b1;
            end
            OP_OR: begin
                r_tmp   = {1'b0, iAcc | iEffOperand};
                oResult = r_tmp[7:0];
                oFlags  = {1'b0, (r_tmp[7:0] == 8'h00), r_tmp[7], 1'b0};
                oAccWe  = 1'b1;
            end
            OP_XOR: begin
                r_tmp   = {1'b0, iAcc ^ iEffOperand};
                oResult = r_tmp[7:0];
                oFlags  = {1'b0, (r_tmp[7:0] == 8'h00), r_tmp[7], 1'b0};
                oAccWe  = 1'b1;
            end
            OP_MOV: begin
                oResult = iEffOperand;
                oFlags  = {iSR[3], (iEffOperand == 8'h00), iEffOperand[7], iSR[0]};
                oAccWe  = 1'b1;
            end
            OP_MOVIX: begin
                oIxResult = iEffOperand;
                oIxWe     = 1'b1;
            end
            default: begin
                oResult = iAcc;
            end
        endcase
    end
endmodule

// ============================================================
// Module 3: register_file
// ============================================================
module register_file (
    input  wire       iClk,
    input  wire       iExec,
    input  wire [7:0] iAccData,
    input  wire       iAccWe,
    input  wire [7:0] iIxData,
    input  wire       iIxWe,
    input  wire [3:0] iFlags,
    output wire [7:0] oAcc,
    output wire [7:0] oIx,
    output wire [3:0] oSR
);
    reg [7:0] r_acc = 8'h00;
    reg [7:0] r_ix  = 8'h00;
    reg [3:0] r_sr  = 4'h0;
    assign oAcc = r_acc;
    assign oIx  = r_ix;
    assign oSR  = r_sr;
    always @(posedge iClk) begin
        if (iExec == 1'b1) begin
            if (iAccWe == 1'b1) r_acc <= iAccData;
            if (iIxWe  == 1'b1) r_ix  <= iIxData;
            r_sr <= iFlags;
        end
    end
endmodule

// ============================================================
// Module 4: alu_top  <-- TOP MODULE
// Internal wires w_acc/w_ix/w_sr separate register feedback
// from output ports so DigitalJS does not mistake them for
// combinational loops.
// ============================================================
module alu_top (
    input  wire        iClk,
    input  wire [15:0] iInstruction,
    input  wire        iExec,
    output wire [7:0]  oAcc,
    output wire [7:0]  oIx,
    output wire [3:0]  oSR,
    output wire [3:0]  oFlags
);
    wire [6:0] w_opcode;
    wire       w_ix_bit;
    wire [7:0] w_operand;
    wire [7:0] w_eff_operand;
    wire [7:0] w_result;
    wire [7:0] w_ix_result;
    wire [3:0] w_flags;
    wire       w_acc_we;
    wire       w_ix_we;
    wire [7:0] w_acc;
    wire [7:0] w_ix;
    wire [3:0] w_sr;

    assign oAcc   = w_acc;
    assign oIx    = w_ix;
    assign oSR    = w_sr;
    assign oFlags = w_flags;

    instruction_decoder u_decoder (
        .iInstruction(iInstruction),
        .iIX(w_ix),
        .oOpCode(w_opcode),
        .oIxBit(w_ix_bit),
        .oOperand(w_operand),
        .oEffOperand(w_eff_operand)
    );

    alu_core u_alu (
        .iOpCode(w_opcode),
        .iAcc(w_acc),
        .iEffOperand(w_eff_operand),
        .iSR(w_sr),
        .oResult(w_result),
        .oIxResult(w_ix_result),
        .oFlags(w_flags),
        .oAccWe(w_acc_we),
        .oIxWe(w_ix_we)
    );

    register_file u_regfile (
        .iClk(iClk),
        .iExec(iExec),
        .iAccData(w_result),
        .iAccWe(w_acc_we),
        .iIxData(w_ix_result),
        .iIxWe(w_ix_we),
        .iFlags(w_flags),
        .oAcc(w_acc),
        .oIx(w_ix),
        .oSR(w_sr)
    );

endmodule
