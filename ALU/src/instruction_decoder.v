//-----------------------------------------------------------------------------
// Module: instruction_decoder
// Purpose: 16ビットインストラクションをOpCode/IX/Operandに分解し、
//          IX修飾を適用した実効オペランドを計算する組み合わせ回路
//
// Input:   iInstruction[15:0] - SW1〜16の値
//          iIX[7:0]           - 現在のIXレジスタ値
// Output:  oOpCode[6:0]       - 命令コード [15:9]
//          oIxBit             - IX修飾ビット [8]
//          oOperand[7:0]      - 生のオペランド [7:0]
//          oEffOperand[7:0]   - 実効オペランド（IX修飾後）
//-----------------------------------------------------------------------------
module instruction_decoder (
    input  wire [15:0] iInstruction,
    input  wire [7:0]  iIX,
    output wire [6:0]  oOpCode,
    output wire        oIxBit,
    output wire [7:0]  oOperand,
    output reg  [7:0]  oEffOperand
);

    // フィールド分割（組み合わせ回路: assign）
    assign oOpCode  = iInstruction[15:9];
    assign oIxBit   = iInstruction[8];
    assign oOperand = iInstruction[7:0];

    // IX修飾による実効オペランド計算
    // 感度リスト明示: always @(*) は使用しない
    always @(iInstruction, iIX) begin
        if (iInstruction[8] == 1'b0) begin
            oEffOperand = iInstruction[7:0];    // 直接参照
        end else begin
            oEffOperand = iIX + iInstruction[7:0]; // インデックス修飾
        end
    end

endmodule
