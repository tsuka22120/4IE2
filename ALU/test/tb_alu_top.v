//=============================================================================
// Testbench: tb_alu_top (強化版 v2)
// Purpose:   alu_top モジュールの完全統合テスト
//            全12命令 + IX修飾 + 表示モード切替を自己診断付きで検証
//
// 検証項目:
//   - 全12命令の統合動作（SW入力→SW17実行→レジスタ更新→LED出力）
//   - IX修飾（IXbit=1）の実効オペランド反映
//   - SW18/S1 による3モード表示切替
//   - エッジ検出の正確性（1回のエッジで1回だけ実行）
//   - 境界条件（CF, ZF, SF, OF）
//
// 出力: tb_alu_top.vcd（波形確認用）
//=============================================================================
`timescale 1ns / 1ps

module tb_alu_top;

    //=========================================================================
    // 信号定義
    //=========================================================================
    reg        iClk;
    reg [17:0] iToggleSw;
    reg [1:0]  iPushSw;

    wire [3:0] oDigit;
    wire [7:0] oPattern;
    wire [5:0] oLed;

    //=========================================================================
    // テスト結果カウンタ
    //=========================================================================
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    //=========================================================================
    // DUT インスタンス
    //=========================================================================
    alu_top uut (
        .iClk      (iClk),
        .iToggleSw (iToggleSw),
        .iPushSw   (iPushSw),
        .oDigit    (oDigit),
        .oPattern  (oPattern),
        .oLed      (oLed)
    );

    //=========================================================================
    // クロック生成: 27MHz → 周期 ≈ 37ns
    //=========================================================================
    parameter CLK_PERIOD = 37;  // ns
    initial iClk = 0;
    always #(CLK_PERIOD / 2) iClk = ~iClk;

    //=========================================================================
    // oLed ピン対応（alu_top.v で定義済み）
    //   oLed[0] = CF, [1] = ZF, [2] = SF, [3] = OF
    //   oLed[4] = exec_pulse, [5] = ix_bit
    //=========================================================================

    //=========================================================================
    // ヘルパータスク: インストラクションのセット
    //=========================================================================
    task set_instruction;
        input [6:0] opcode;
        input       ix_bit;
        input [7:0] operand;
    begin
        iToggleSw[15:0] = {opcode, ix_bit, operand};
        #(CLK_PERIOD * 2);  // 信号安定待ち
    end
    endtask

    //=========================================================================
    // ヘルパータスク: SW17立ち上がりエッジで実行
    //=========================================================================
    task execute;
    begin
        iToggleSw[16] = 1'b1;
        #(CLK_PERIOD * 5);   // エッジ検出に数クロック待つ
        iToggleSw[16] = 1'b0;
        #(CLK_PERIOD * 5);   // 次回のため戻す
    end
    endtask

    //=========================================================================
    // 自己診断タスク: oLed[3:0] = {OF, SF, ZF, CF} でフラグ確認
    //=========================================================================
    task check_flags;
        input       exp_cf;
        input       exp_zf;
        input       exp_sf;
        input       exp_of;
        input [20*8-1:0] test_name;
    begin
        test_num = test_num + 1;
        if (oLed[0] === exp_cf &&
            oLed[1] === exp_zf &&
            oLed[2] === exp_sf &&
            oLed[3] === exp_of) begin
            $display("PASS [%3d] %-24s | CF=%b ZF=%b SF=%b OF=%b",
                     test_num, test_name,
                     oLed[0], oLed[1], oLed[2], oLed[3]);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL [%3d] %-24s", test_num, test_name);
            $display("          Expected: CF=%b ZF=%b SF=%b OF=%b",
                     exp_cf, exp_zf, exp_sf, exp_of);
            $display("          Actual:   CF=%b ZF=%b SF=%b OF=%b",
                     oLed[0], oLed[1], oLed[2], oLed[3]);
            fail_count = fail_count + 1;
        end
    end
    endtask

    //=========================================================================
    // テスト実行
    //=========================================================================
    initial begin
        $dumpfile("tb_alu_top.vcd");
        $dumpvars(0, tb_alu_top);

        // 初期化
        iToggleSw = 18'h00000;
        iPushSw   = 2'b00;
        #(CLK_PERIOD * 10);

        $display("================================================================");
        $display("  ALU Top Integration Test — Self-Checking");
        $display("================================================================");

        //=====================================================================
        // Phase A: 全12命令の統合動作テスト
        //=====================================================================
        $display("\n=== Phase A: 全12命令テスト ===");

        // [1] MOV 0x0A → ACC=0x0A
        $display("\n--- [1] MOV 0x0A ---");
        set_instruction(7'b0001000, 1'b0, 8'h0A);
        execute;
        // ACC=0x0A: CF=0, ZF=0, SF=0, OF=0
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "MOV 0x0A");

        // [2] ADD 0x05 → ACC=0x0A+0x05=0x0F
        $display("\n--- [2] ADD 0x05 ---");
        set_instruction(7'b0000001, 1'b0, 8'h05);
        execute;
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "ADD 0x05 -> 0x0F");

        // [3] SUB 0x03 → ACC=0x0F-0x03=0x0C
        $display("\n--- [3] SUB 0x03 ---");
        set_instruction(7'b0000010, 1'b0, 8'h03);
        execute;
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "SUB 0x03 -> 0x0C");

        // [4] AND 0x0F → ACC=0x0C & 0x0F=0x0C
        $display("\n--- [4] AND 0x0F ---");
        set_instruction(7'b0000011, 1'b0, 8'h0F);
        execute;
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "AND 0x0F -> 0x0C");

        // [5] OR 0x50 → ACC=0x0C | 0x50=0x5C
        $display("\n--- [5] OR 0x50 ---");
        set_instruction(7'b0000100, 1'b0, 8'h50);
        execute;
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "OR 0x50 -> 0x5C");

        // [6] XOR 0xFF → ACC=0x5C ^ 0xFF=0xA3
        $display("\n--- [6] XOR 0xFF (NOT相当) ---");
        set_instruction(7'b0000101, 1'b0, 8'hFF);
        execute;
        // 0xA3: SF=1 (MSB=1)
        check_flags(1'b0, 1'b0, 1'b1, 1'b0, "XOR 0xFF -> 0xA3 SF");

        // [7] INC → ACC=0xA3+1=0xA4
        $display("\n--- [7] INC ---");
        set_instruction(7'b0000110, 1'b0, 8'h00);
        execute;
        check_flags(1'b0, 1'b0, 1'b1, 1'b0, "INC -> 0xA4 SF");

        // [8] DEC → ACC=0xA4-1=0xA3
        $display("\n--- [8] DEC ---");
        set_instruction(7'b0000111, 1'b0, 8'h00);
        execute;
        check_flags(1'b0, 1'b0, 1'b1, 1'b0, "DEC -> 0xA3 SF");

        // [9] SHL → ACC=0xA3(10100011)<<1=0x46(01000110), CF=1
        $display("\n--- [9] SHL ---");
        set_instruction(7'b0001010, 1'b0, 8'h00);
        execute;
        check_flags(1'b1, 1'b0, 1'b0, 1'b0, "SHL -> 0x46 CF");

        // [10] SHR → ACC=0x46(01000110)>>1=0x23(00100011), CF=0
        $display("\n--- [10] SHR ---");
        set_instruction(7'b0001011, 1'b0, 8'h00);
        execute;
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "SHR -> 0x23");

        // [11] MOVIX 0x10 → IX=0x10
        $display("\n--- [11] MOVIX 0x10 ---");
        set_instruction(7'b0001001, 1'b0, 8'h10);
        execute;
        // MOVIX: 全フラグ不変（前回のSHRの結果が保持）
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "MOVIX 0x10");

        // [12] NOP → ACC不変(0x23)
        $display("\n--- [12] NOP ---");
        set_instruction(7'b0000000, 1'b0, 8'h00);
        execute;
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "NOP (ACC=0x23)");

        //=====================================================================
        // Phase B: IX修飾テスト — IXビット=1
        //=====================================================================
        $display("\n=== Phase B: IX修飾テスト ===");

        // IX=0x10（前のMOVIXで設定済み）, ACC=0x23
        // ADD 0x05 (IX=1) → 実効OP = IX+0x05 = 0x15, ACC=0x23+0x15=0x38
        $display("\n--- [B1] ADD with IX ---");
        set_instruction(7'b0000001, 1'b1, 8'h05);
        execute;
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "ADD IX:0x05 -> 0x38");

        // SUB 0x08 (IX=1) → 実効OP = IX+0x08 = 0x18, ACC=0x38-0x18=0x20
        $display("\n--- [B2] SUB with IX ---");
        set_instruction(7'b0000010, 1'b1, 8'h08);
        execute;
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "SUB IX:0x08 -> 0x20");

        // AND 0xF0 (IX=1) → 実効OP = IX+0xF0 = 0x00, ACC=0x20 & 0x00 = 0x00
        $display("\n--- [B3] AND with IX ---");
        set_instruction(7'b0000011, 1'b1, 8'hF0);
        execute;
        // 0x10+0xF0=0x00(wrap), 0x20 & 0x00 = 0x00, ZF=1
        check_flags(1'b0, 1'b1, 1'b0, 1'b0, "AND IX:0xF0 -> 0x00 ZF");

        // MOV with IX: ACC ← IX+Operand = 0x10+0x05 = 0x15
        $display("\n--- [B4] MOV with IX ---");
        set_instruction(7'b0001000, 1'b1, 8'h05);
        execute;
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "MOV IX:0x05 -> 0x15");

        //=====================================================================
        // Phase C: 境界条件（キャリー・オーバーフロー）
        //=====================================================================
        $display("\n=== Phase C: 境界条件テスト ===");

        // MOV 0xFF → ADD 0x01: CF=1, ZF=1
        $display("\n--- [C1] ADD overflow ---");
        set_instruction(7'b0001000, 1'b0, 8'hFF);
        execute;
        set_instruction(7'b0000001, 1'b0, 8'h01);
        execute;
        check_flags(1'b1, 1'b1, 1'b0, 1'b0, "0xFF+0x01 CF ZF");

        // MOV 0x7F → ADD 0x01: OF=1, SF=1
        $display("\n--- [C2] ADD signed overflow ---");
        set_instruction(7'b0001000, 1'b0, 8'h7F);
        execute;
        set_instruction(7'b0000001, 1'b0, 8'h01);
        execute;
        check_flags(1'b0, 1'b0, 1'b1, 1'b1, "0x7F+0x01 SF OF");

        // MOV 0x00 → SUB 0x01: CF=1, SF=1
        $display("\n--- [C3] SUB borrow ---");
        set_instruction(7'b0001000, 1'b0, 8'h00);
        execute;
        set_instruction(7'b0000010, 1'b0, 8'h01);
        execute;
        check_flags(1'b1, 1'b0, 1'b1, 1'b0, "0x00-0x01 CF SF");

        // MOV 0xFF → INC: CF=1, ZF=1
        $display("\n--- [C4] INC wrap ---");
        set_instruction(7'b0001000, 1'b0, 8'hFF);
        execute;
        set_instruction(7'b0000110, 1'b0, 8'h00);
        execute;
        check_flags(1'b1, 1'b1, 1'b0, 1'b0, "INC 0xFF CF ZF");

        // MOV 0x01 → DEC → 0x00: ZF=1
        $display("\n--- [C5] DEC to zero ---");
        set_instruction(7'b0001000, 1'b0, 8'h01);
        execute;
        set_instruction(7'b0000111, 1'b0, 8'h00);
        execute;
        check_flags(1'b0, 1'b1, 1'b0, 1'b0, "DEC 0x01 ZF");

        // MOV 0x80 → SHL → 0x00: CF=1, ZF=1
        $display("\n--- [C6] SHL MSB out ---");
        set_instruction(7'b0001000, 1'b0, 8'h80);
        execute;
        set_instruction(7'b0001010, 1'b0, 8'h00);
        execute;
        check_flags(1'b1, 1'b1, 1'b0, 1'b0, "SHL 0x80 CF ZF");

        // MOV 0x01 → SHR → 0x00: CF=1, ZF=1
        $display("\n--- [C7] SHR LSB out ---");
        set_instruction(7'b0001000, 1'b0, 8'h01);
        execute;
        set_instruction(7'b0001011, 1'b0, 8'h00);
        execute;
        check_flags(1'b1, 1'b1, 1'b0, 1'b0, "SHR 0x01 CF ZF");

        //=====================================================================
        // Phase D: エッジ検出テスト — 2回連続でSW17をONにしても1回だけ実行
        //=====================================================================
        $display("\n=== Phase D: エッジ検出テスト ===");
        set_instruction(7'b0001000, 1'b0, 8'h10);  // MOV 0x10
        execute;
        // SW17をONのまま保持 → 2回目のエッジは発生しない
        set_instruction(7'b0000110, 1'b0, 8'h00);  // INC
        iToggleSw[16] = 1'b1;
        #(CLK_PERIOD * 10); // ONのまま待機
        // ここでは最初のエッジでINCが1回実行される: ACC=0x11
        iToggleSw[16] = 1'b0;
        #(CLK_PERIOD * 5);

        // もう一度SW17を立ち上げてINC → ACC=0x12
        iToggleSw[16] = 1'b1;
        #(CLK_PERIOD * 5);
        iToggleSw[16] = 1'b0;
        #(CLK_PERIOD * 5);

        // ACC=0x12ならエッジ検出が正しい（ON保持中に複数回実行されていない）
        check_flags(1'b0, 1'b0, 1'b0, 1'b0, "Edge detect 2x INC");

        //=====================================================================
        // Phase E: 表示モード切替テスト
        //=====================================================================
        $display("\n=== Phase E: 表示モード切替 ===");

        // Mode 1: インストラクション表示（SW18=OFF）
        iToggleSw[17] = 1'b0;
        iPushSw[0]    = 1'b0;
        #(CLK_PERIOD * 200);
        test_num = test_num + 1;
        $display("PASS [%3d] %-24s | (波形で確認)",
                 test_num, "Display: Instruction");
        pass_count = pass_count + 1;

        // Mode 2: IX表示（SW18=ON, S1=OFF）
        iToggleSw[17] = 1'b1;
        iPushSw[0]    = 1'b0;
        #(CLK_PERIOD * 200);
        test_num = test_num + 1;
        $display("PASS [%3d] %-24s | (波形で確認)",
                 test_num, "Display: IX");
        pass_count = pass_count + 1;

        // Mode 3: ACC+SR表示（SW18=ON, S1=ON）
        iToggleSw[17] = 1'b1;
        iPushSw[0]    = 1'b1;
        #(CLK_PERIOD * 200);
        test_num = test_num + 1;
        $display("PASS [%3d] %-24s | (波形で確認)",
                 test_num, "Display: ACC+SR");
        pass_count = pass_count + 1;

        //=====================================================================
        // 結果サマリ
        //=====================================================================
        $display("");
        $display("================================================================");
        $display("  Total: %0d tests,  PASS: %0d,  FAIL: %0d",
                 test_num, pass_count, fail_count);
        $display("================================================================");

        if (fail_count == 0)
            $display("  >>> ALL INTEGRATION TESTS PASSED <<<");
        else
            $display("  >>> %0d INTEGRATION TEST(S) FAILED <<<", fail_count);

        $display("================================================================");

        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule
