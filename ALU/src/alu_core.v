//-----------------------------------------------------------------------------
// Module: alu_core
// Purpose: 12種類の演算を実行し、結果と4フラグを出力する組み合わせ回路
//
// Input:   iOpCode[6:0]      - 命令コード
//          iAcc[7:0]         - 現在のACC値
//          iEffOperand[7:0]  - 実効オペランド
//          iSR[3:0]          - 現在のSR値（フラグ不変命令で保持用）
// Output:  oResult[7:0]      - 演算結果（ACC書込みデータ）
//          oIxResult[7:0]    - IX書込みデータ（MOVIX命令用）
//          oFlags[3:0]       - {CF, ZF, SF, OF}
//          oAccWe            - ACC書込みイネーブル
//          oIxWe             - IX書込みイネーブル
//-----------------------------------------------------------------------------
module alu_core (
    input  wire [6:0] iOpCode,
    input  wire [7:0] iAcc,
    input  wire [7:0] iEffOperand,
    input  wire [3:0] iSR,
    output reg  [7:0] oResult,
    output reg  [7:0] oIxResult,
    output reg  [3:0] oFlags,      // {CF, ZF, SF, OF}
    output reg        oAccWe,
    output reg        oIxWe
);

    //=========================================================================
    // 命令コード定数 (OpCode [15:9] = [6:0])
    //=========================================================================
    parameter OP_NOP   = 7'b0000000;  // 0x00: 無操作
    parameter OP_ADD   = 7'b0000001;  // 0x02: 加算
    parameter OP_SUB   = 7'b0000010;  // 0x04: 減算
    parameter OP_AND   = 7'b0000011;  // 0x06: 論理積
    parameter OP_OR    = 7'b0000100;  // 0x08: 論理和
    parameter OP_XOR   = 7'b0000101;  // 0x0A: 排他的論理和
    parameter OP_INC   = 7'b0000110;  // 0x0C: インクリメント
    parameter OP_DEC   = 7'b0000111;  // 0x0E: デクリメント
    parameter OP_MOV   = 7'b0001000;  // 0x10: ロード
    parameter OP_MOVIX = 7'b0001001;  // 0x12: IXレジスタ転送
    parameter OP_SHL   = 7'b0001010;  // 0x14: 論理左シフト
    parameter OP_SHR   = 7'b0001011;  // 0x16: 論理右シフト

    //=========================================================================
    // フラグビット位置
    //=========================================================================
    parameter CF_BIT = 3;  // Carry Flag
    parameter ZF_BIT = 2;  // Zero Flag
    parameter SF_BIT = 1;  // Sign Flag
    parameter OF_BIT = 0;  // Overflow Flag

    //=========================================================================
    // 内部演算用ワイヤ
    //=========================================================================
    reg [8:0] r_tmp9;  // 9ビット一時結果（キャリー/ボロー検出用）

    //=========================================================================
    // 演算ロジック（組み合わせ回路）
    // 注意: always @(*) は使用禁止 → 全入力を感度リストに明示
    //=========================================================================
    always @(iOpCode, iAcc, iEffOperand, iSR) begin
        // ラッチ防止: デフォルト値の設定
        oResult   = iAcc;
        oIxResult = 8'h00;
        oFlags    = iSR;       // フラグ不変がデフォルト
        oAccWe    = 1'b0;
        oIxWe     = 1'b0;
        r_tmp9    = 9'h000;

        case (iOpCode)
            //--- NOP: 何もしない -----------------------------------------
            OP_NOP: begin
                oResult = iAcc;
                oAccWe  = 1'b0;
                oIxWe   = 1'b0;
                // フラグ不変
            end

            //--- ADD: ACC ← ACC + d --------------------------------------
            OP_ADD: begin
                r_tmp9  = {1'b0, iAcc} + {1'b0, iEffOperand};
                oResult = r_tmp9[7:0];
                oAccWe  = 1'b1;
                oFlags[CF_BIT] = r_tmp9[8];                                // Carry
                oFlags[ZF_BIT] = (r_tmp9[7:0] == 8'h00) ? 1'b1 : 1'b0;   // Zero
                oFlags[SF_BIT] = r_tmp9[7];                                // Sign
                oFlags[OF_BIT] = (iAcc[7] == iEffOperand[7]) &&            // Overflow
                                 (r_tmp9[7] != iAcc[7]);
            end

            //--- SUB: ACC ← ACC - d --------------------------------------
            OP_SUB: begin
                r_tmp9  = {1'b0, iAcc} - {1'b0, iEffOperand};
                oResult = r_tmp9[7:0];
                oAccWe  = 1'b1;
                oFlags[CF_BIT] = r_tmp9[8];                                // Borrow
                oFlags[ZF_BIT] = (r_tmp9[7:0] == 8'h00) ? 1'b1 : 1'b0;   // Zero
                oFlags[SF_BIT] = r_tmp9[7];                                // Sign
                oFlags[OF_BIT] = (iAcc[7] != iEffOperand[7]) &&            // Overflow
                                 (r_tmp9[7] != iAcc[7]);
            end

            //--- AND: ACC ← ACC & d --------------------------------------
            OP_AND: begin
                oResult = iAcc & iEffOperand;
                oAccWe  = 1'b1;
                oFlags[CF_BIT] = 1'b0;                                     // CF cleared
                oFlags[ZF_BIT] = (oResult == 8'h00) ? 1'b1 : 1'b0;
                oFlags[SF_BIT] = oResult[7];
                oFlags[OF_BIT] = 1'b0;                                     // OF cleared
            end

            //--- OR: ACC ← ACC | d ---------------------------------------
            OP_OR: begin
                oResult = iAcc | iEffOperand;
                oAccWe  = 1'b1;
                oFlags[CF_BIT] = 1'b0;
                oFlags[ZF_BIT] = (oResult == 8'h00) ? 1'b1 : 1'b0;
                oFlags[SF_BIT] = oResult[7];
                oFlags[OF_BIT] = 1'b0;
            end

            //--- XOR: ACC ← ACC ^ d --------------------------------------
            OP_XOR: begin
                oResult = iAcc ^ iEffOperand;
                oAccWe  = 1'b1;
                oFlags[CF_BIT] = 1'b0;
                oFlags[ZF_BIT] = (oResult == 8'h00) ? 1'b1 : 1'b0;
                oFlags[SF_BIT] = oResult[7];
                oFlags[OF_BIT] = 1'b0;
            end

            //--- INC: ACC ← ACC + 1 （Operand無視）----------------------
            OP_INC: begin
                r_tmp9  = {1'b0, iAcc} + 9'h001;
                oResult = r_tmp9[7:0];
                oAccWe  = 1'b1;
                oFlags[CF_BIT] = r_tmp9[8];
                oFlags[ZF_BIT] = (r_tmp9[7:0] == 8'h00) ? 1'b1 : 1'b0;
                oFlags[SF_BIT] = r_tmp9[7];
                oFlags[OF_BIT] = (iAcc == 8'h7F) ? 1'b1 : 1'b0;   // 127→-128
            end

            //--- DEC: ACC ← ACC - 1 （Operand無視）----------------------
            OP_DEC: begin
                r_tmp9  = {1'b0, iAcc} - 9'h001;
                oResult = r_tmp9[7:0];
                oAccWe  = 1'b1;
                oFlags[CF_BIT] = r_tmp9[8];
                oFlags[ZF_BIT] = (r_tmp9[7:0] == 8'h00) ? 1'b1 : 1'b0;
                oFlags[SF_BIT] = r_tmp9[7];
                oFlags[OF_BIT] = (iAcc == 8'h80) ? 1'b1 : 1'b0;   // -128→127
            end

            //--- MOV: ACC ← d --------------------------------------------
            OP_MOV: begin
                oResult = iEffOperand;
                oAccWe  = 1'b1;
                oFlags[ZF_BIT] = (iEffOperand == 8'h00) ? 1'b1 : 1'b0;
                oFlags[SF_BIT] = iEffOperand[7];
                // CF, OF は不変（iSRのまま保持）
            end

            //--- MOVIX: IX ← d -------------------------------------------
            OP_MOVIX: begin
                oIxResult = iEffOperand;
                oIxWe     = 1'b1;
                oAccWe    = 1'b0;
                // 全フラグ不変
            end

            //--- SHL: 論理左シフト ----------------------------------------
            OP_SHL: begin
                oResult = {iAcc[6:0], 1'b0};
                oAccWe  = 1'b1;
                oFlags[CF_BIT] = iAcc[7];                                  // MSB → CF
                oFlags[ZF_BIT] = ({iAcc[6:0], 1'b0} == 8'h00) ? 1'b1 : 1'b0;
                oFlags[SF_BIT] = iAcc[6];                                  // 新MSB
                oFlags[OF_BIT] = 1'b0;
            end

            //--- SHR: 論理右シフト ----------------------------------------
            OP_SHR: begin
                oResult = {1'b0, iAcc[7:1]};
                oAccWe  = 1'b1;
                oFlags[CF_BIT] = iAcc[0];                                  // LSB → CF
                oFlags[ZF_BIT] = ({1'b0, iAcc[7:1]} == 8'h00) ? 1'b1 : 1'b0;
                oFlags[SF_BIT] = 1'b0;                                     // 常に0（MSBに0挿入）
                oFlags[OF_BIT] = 1'b0;
            end

            //--- default: NOP相当（ラッチ防止）----------------------------
            default: begin
                oResult   = iAcc;
                oIxResult = 8'h00;
                oFlags    = iSR;
                oAccWe    = 1'b0;
                oIxWe     = 1'b0;
            end
        endcase
    end

endmodule
