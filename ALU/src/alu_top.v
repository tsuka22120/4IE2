//-----------------------------------------------------------------------------
// Module: alu_top
// Purpose: 8ビットALU トップモジュール
//          全サブモジュールをインスタンス化し、FPGAピンと接続する
//
// Target:  Gowin GW1NR-9
//
// Input:   iClk            - システムクロック (27MHz, ピン52)
//          iToggleSw[17:0] - トグルスイッチ (SW1〜SW18)
//          iPushSw[1:0]    - プッシュスイッチ (S1, S2)
// Output:  oDigit[3:0]     - 7セグメント桁選択
//          oPattern[7:0]   - 7セグメントパターン
//          oLed[5:0]       - LED出力
//-----------------------------------------------------------------------------
module alu_top (
    input  wire        iClk,
    input  wire [17:0] iToggleSw,
    input  wire [1:0]  iPushSw,
    output wire [3:0]  oDigit,
    output wire [7:0]  oPattern,
    output wire [5:0]  oLed
);

    //=========================================================================
    // 信号名マッピング（可読性向上）
    //=========================================================================
    // SW1(iToggleSw[0])=MSB(bit15), SW16(iToggleSw[15])=LSB(bit0) に対応
    wire [15:0] w_instruction = {iToggleSw[0],  iToggleSw[1],  iToggleSw[2],  iToggleSw[3],
                                  iToggleSw[4],  iToggleSw[5],  iToggleSw[6],  iToggleSw[7],
                                  iToggleSw[8],  iToggleSw[9],  iToggleSw[10], iToggleSw[11],
                                  iToggleSw[12], iToggleSw[13], iToggleSw[14], iToggleSw[15]};
    wire        w_sw17        = iToggleSw[16];    // SW17: 実行トリガ
    wire        w_sw18        = iToggleSw[17];    // SW18: 表示モード切替（アクティブHIGH: そのまま）
    wire        w_s1          = ~iPushSw[0];      // S1: 表示モード切替（アクティブLOW: 反転）

    //=========================================================================
    // 内部ワイヤ定義
    //=========================================================================
    // edge_detector → register_file
    wire w_exec_pulse;

    // instruction_decoder → alu_core
    wire [6:0] w_opcode;
    wire       w_ix_bit;
    wire [7:0] w_operand;
    wire [7:0] w_eff_operand;

    // register_file → alu_core / instruction_decoder / display_controller
    wire [7:0] w_acc;
    wire [7:0] w_ix;
    wire [3:0] w_sr;

    // alu_core → register_file
    wire [7:0] w_alu_result;
    wire [7:0] w_ix_result;
    wire [3:0] w_flags;
    wire       w_acc_we;
    wire       w_ix_we;

    //=========================================================================
    // Module 1: Edge Detector — SW17立ち上がりエッジ検出
    //=========================================================================
    edge_detector u_edge_detector (
        .iClk  (iClk),
        .iSw   (w_sw17),
        .oRise (w_exec_pulse)
    );

    //=========================================================================
    // Module 2: Instruction Decoder — 命令デコード + IX修飾
    //=========================================================================
    instruction_decoder u_instruction_decoder (
        .iInstruction (w_instruction),
        .iIX          (w_ix),
        .oOpCode      (w_opcode),
        .oIxBit       (w_ix_bit),
        .oOperand     (w_operand),
        .oEffOperand  (w_eff_operand)
    );

    //=========================================================================
    // Module 3: ALU Core — 12命令の演算実行
    //=========================================================================
    alu_core u_alu_core (
        .iOpCode      (w_opcode),
        .iAcc         (w_acc),
        .iEffOperand  (w_eff_operand),
        .iSR          (w_sr),
        .oResult      (w_alu_result),
        .oIxResult    (w_ix_result),
        .oFlags       (w_flags),
        .oAccWe       (w_acc_we),
        .oIxWe        (w_ix_we)
    );

    //=========================================================================
    // Module 4: Register File — ACC/IX/SR 保持・更新
    //=========================================================================
    register_file u_register_file (
        .iClk     (iClk),
        .iExec    (w_exec_pulse),
        .iAccData (w_alu_result),
        .iAccWe   (w_acc_we),
        .iIxData  (w_ix_result),
        .iIxWe    (w_ix_we),
        .iFlags   (w_flags),
        .oAcc     (w_acc),
        .oIx      (w_ix),
        .oSR      (w_sr)
    );

    //=========================================================================
    // Module 5: Display Controller — 7セグメント表示制御
    //=========================================================================
    display_controller u_display_controller (
        .iClk          (iClk),
        .iSw18         (w_sw18),
        .iS1           (w_s1),
        .iInstruction  (w_instruction),
        .iAcc          (w_acc),
        .iIx           (w_ix),
        .iSR           (w_sr),
        .oDigit        (oDigit),
        .oPattern      (oPattern)
    );

    //=========================================================================
    // LED出力 — ステータスフラグ + 実行パルスのデバッグ表示
    //   oLed[0] = CF (Carry Flag)
    //   oLed[1] = ZF (Zero Flag)
    //   oLed[2] = SF (Sign Flag)
    //   oLed[3] = OF (Overflow Flag)
    //   oLed[4] = 実行パルス（exec_pulse）
    //   oLed[5] = IX修飾ビット
    //=========================================================================
    assign oLed[0] = ~w_sr[3];        // CF（アクティブLOW: 0=点灯）
    assign oLed[1] = ~w_sr[2];        // ZF
    assign oLed[2] = ~w_sr[1];        // SF
    assign oLed[3] = ~w_sr[0];        // OF
    assign oLed[4] = ~w_exec_pulse;   // 実行パルス
    assign oLed[5] = ~w_ix_bit;       // IX修飾ビット

endmodule
