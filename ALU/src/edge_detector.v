//-----------------------------------------------------------------------------
// Module: edge_detector
// Purpose: SW17の立ち上がりエッジを検出する同期回路
//          2段FFで非同期入力を同期化し、1クロック幅のパルスを出力
//
// Input:   iClk  - システムクロック
//          iSw   - SW17入力（非同期）
// Output:  oRise - 立ち上がりエッジ検出パルス（1クロック幅）
//-----------------------------------------------------------------------------
module edge_detector (
    input  wire iClk,
    input  wire iSw,
    output wire oRise
);

    // 2段FF: 非同期入力の同期化（メタステーブル対策）
    reg r_sw_d1;  // 1段目FF
    reg r_sw_d2;  // 2段目FF

    always @(posedge iClk) begin
        r_sw_d1 <= iSw;
        r_sw_d2 <= r_sw_d1;
    end

    // 立ち上がりエッジ検出: 前段=1, 後段=0 のとき1クロック幅パルス
    assign oRise = r_sw_d1 & ~r_sw_d2;

endmodule
