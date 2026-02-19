//-----------------------------------------------------------------------------
// Module: register_file
// Purpose: ACC(8bit), IX(8bit), SR(4bit) を保持し、
//          実行パルス(iExec)に同期して更新する順序回路
//
// Input:   iClk      - システムクロック
//          iExec     - 実行パルス（edge_detectorの出力）
//          iAccData  - ACC書込みデータ
//          iAccWe    - ACC書込みイネーブル
//          iIxData   - IX書込みデータ
//          iIxWe     - IX書込みイネーブル
//          iFlags    - フラグ書込みデータ {CF, ZF, SF, OF}
// Output:  oAcc      - 現在のACC値
//          oIx       - 現在のIX値
//          oSR       - 現在のSR値
//-----------------------------------------------------------------------------
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

    // レジスタ定義（初期値設定）
    reg [7:0] r_acc = 8'h00;
    reg [7:0] r_ix  = 8'h00;
    reg [3:0] r_sr  = 4'h0;

    // 出力接続
    assign oAcc = r_acc;
    assign oIx  = r_ix;
    assign oSR  = r_sr;

    // 同期更新: 実行パルスに応じてレジスタを更新
    always @(posedge iClk) begin
        if (iExec == 1'b1) begin
            // ACC更新
            if (iAccWe == 1'b1) begin
                r_acc <= iAccData;
            end else begin
                r_acc <= r_acc;
            end

            // IX更新
            if (iIxWe == 1'b1) begin
                r_ix <= iIxData;
            end else begin
                r_ix <= r_ix;
            end

            // フラグ更新（常に更新 — alu_coreが不変時はiSRをそのまま返す）
            r_sr <= iFlags;
        end else begin
            r_acc <= r_acc;
            r_ix  <= r_ix;
            r_sr  <= r_sr;
        end
    end

endmodule
