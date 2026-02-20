//-----------------------------------------------------------------------------
// Module: display_controller
// Purpose: SW18/S1に応じた表示データ選択、ダイナミック点灯制御、
//          7セグメントデコードを行う
//
// Input:   iClk             - システムクロック
//          iSw18            - SW18（表示モード切替）
//          iS1              - S1プッシュスイッチ
//          iInstruction     - 現在のインストラクション（16bit）
//          iAcc             - ACC値（8bit）
//          iIx              - IX値（8bit）
//          iSR              - SR値（4bit: CF/ZF/SF/OF）
// Output:  oDigit[3:0]      - 桁選択（アクティブHIGH / ワンホット）
//          oPattern[7:0]    - 7セグパターン
//                             oPattern[0]=セグa, [1]=b, [2]=c, [3]=d,
//                             [4]=e, [5]=f, [6]=g, [7]=dp
//                             アクティブLOW（0で点灯）
//-----------------------------------------------------------------------------
module display_controller (
    input  wire        iClk,
    input  wire        iSw18,
    input  wire        iS1,
    input  wire [15:0] iInstruction,
    input  wire [7:0]  iAcc,
    input  wire [7:0]  iIx,
    input  wire [3:0]  iSR,
    output reg  [3:0]  oDigit,
    output reg  [7:0]  oPattern
);

    //=========================================================================
    // 分周カウンタ（ダイナミック点灯用）
    // 27MHz クロック → 約 1kHz で桁切り替え
    // 27,000,000 / 4桁 / 1kHz ≈ 6750 → 13bit カウンタ
    //=========================================================================
    reg [12:0] r_div_cnt = 13'h0000;
    reg [1:0]  r_digit_sel = 2'b00;

    always @(posedge iClk) begin
        if (r_div_cnt == 13'd6749) begin
            r_div_cnt   <= 13'h0000;
            r_digit_sel <= r_digit_sel + 2'b01;
        end else begin
            r_div_cnt   <= r_div_cnt + 13'h0001;
            r_digit_sel <= r_digit_sel;
        end
    end

    //=========================================================================
    // 表示モード選択 — SW18/S1に応じて16bit表示データを決定
    //   SW18=OFF       → インストラクション（16bit全体）
    //   SW18=ON, S1=OFF → IX表示（上位00, 下位IX）
    //   SW18=ON, S1=ON  → ACC(上位) + SR(下位)
    //=========================================================================
    reg [15:0] r_display_data;

    always @(iSw18, iS1, iInstruction, iAcc, iIx, iSR) begin
        if (iSw18 == 1'b0) begin
            r_display_data = iInstruction;
        end else begin
            if (iS1 == 1'b0) begin
                r_display_data = {8'h00, iIx};
            end else begin
                r_display_data = {iAcc, 4'h0, iSR};
            end
        end
    end

    //=========================================================================
    // 桁セレクタ — カウンタ値に応じてニブルを抽出 + 桁選択信号を生成
    //=========================================================================
    reg [3:0] r_nibble;

    always @(r_digit_sel, r_display_data) begin
        case (r_digit_sel)
            2'b00: begin
                oDigit   = 4'b0001;   // 一の位
                r_nibble = r_display_data[3:0];
            end
            2'b01: begin
                oDigit   = 4'b0010;   // 十の位
                r_nibble = r_display_data[7:4];
            end
            2'b10: begin
                oDigit   = 4'b0100;   // 百の位
                r_nibble = r_display_data[11:8];
            end
            2'b11: begin
                oDigit   = 4'b1000;   // 千の位
                r_nibble = r_display_data[15:12];
            end
            default: begin
                oDigit   = 4'b0001;
                r_nibble = 4'h0;
            end
        endcase
    end

    //=========================================================================
    // 7セグメントデコーダ（アクティブHIGH: 1=点灯, 0=消灯）
    //
    // ピン対応 (PIN.md準拠):
    //   oPattern[0] = セグa (ピン75)
    //   oPattern[1] = セグb (ピン74)
    //   oPattern[2] = セグc (ピン73)
    //   oPattern[3] = セグd (ピン72)
    //   oPattern[4] = セグe (ピン71)
    //   oPattern[5] = セグf (ピン70)
    //   oPattern[6] = セグg (ピン48)
    //   oPattern[7] = セグdp(ピン49) — 常にOFF(0)
    //
    //        aaaa
    //       f    b
    //       f    b
    //        gggg
    //       e    c
    //       e    c
    //        dddd
    //=========================================================================
    always @(r_nibble) begin
        case (r_nibble)
            //                 dp g f e d c b a
            4'h0: oPattern = 8'b0_0_1_1_1_1_1_1;  // 0: a,b,c,d,e,f ON
            4'h1: oPattern = 8'b0_0_0_0_0_1_1_0;  // 1: b,c ON
            4'h2: oPattern = 8'b0_1_0_1_1_0_1_1;  // 2: a,b,d,e,g ON
            4'h3: oPattern = 8'b0_1_0_0_1_1_1_1;  // 3: a,b,c,d,g ON
            4'h4: oPattern = 8'b0_1_1_0_0_1_1_0;  // 4: b,c,f,g ON
            4'h5: oPattern = 8'b0_1_1_0_1_1_0_1;  // 5: a,c,d,f,g ON
            4'h6: oPattern = 8'b0_1_1_1_1_1_0_1;  // 6: a,c,d,e,f,g ON
            4'h7: oPattern = 8'b0_0_0_0_0_1_1_1;  // 7: a,b,c ON
            4'h8: oPattern = 8'b0_1_1_1_1_1_1_1;  // 8: all ON
            4'h9: oPattern = 8'b0_1_1_0_1_1_1_1;  // 9: a,b,c,d,f,g ON
            4'hA: oPattern = 8'b0_1_1_1_0_1_1_1;  // A: a,b,c,e,f,g ON
            4'hB: oPattern = 8'b0_1_1_1_1_1_0_0;  // b: c,d,e,f,g ON
            4'hC: oPattern = 8'b0_0_1_1_1_0_0_1;  // C: a,d,e,f ON
            4'hD: oPattern = 8'b0_1_0_1_1_1_1_0;  // d: b,c,d,e,g ON
            4'hE: oPattern = 8'b0_1_1_1_1_0_0_1;  // E: a,d,e,f,g ON
            4'hF: oPattern = 8'b0_1_1_1_0_0_0_1;  // F: a,e,f,g ON
            default: oPattern = 8'b0_0_0_0_0_0_0_0; // 全消灯
        endcase
    end

endmodule
