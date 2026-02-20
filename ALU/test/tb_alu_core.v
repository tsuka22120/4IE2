//=============================================================================
// Testbench: tb_alu_core (強化版 v2)
// Purpose:   alu_core モジュールの12命令すべてを網羅的に検証
//            自己診断（Self-Checking）機能付き
//
// 検証項目:
//   - 全12命令の基本動作
//   - CF/ZF/SF/OF の全フラグ境界条件
//   - フラグ不変命令(NOP/MOV/MOVIX)でのフラグ保持
//   - 未定義OpCodeに対するdefault動作
//   - テスト結果の自動PASS/FAIL判定＋サマリ出力
//
// 出力: tb_alu_core.vcd（波形確認用）
//=============================================================================
`timescale 1ns / 1ps

module tb_alu_core;

    //=========================================================================
    // 信号定義
    //=========================================================================
    reg  [6:0] iOpCode;
    reg  [7:0] iAcc;
    reg  [7:0] iEffOperand;
    reg  [3:0] iSR;

    wire [7:0] oResult;
    wire [7:0] oIxResult;
    wire [3:0] oFlags;    // {CF, ZF, SF, OF}
    wire       oAccWe;
    wire       oIxWe;

    //=========================================================================
    // テスト結果カウンタ
    //=========================================================================
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    //=========================================================================
    // DUT インスタンス
    //=========================================================================
    alu_core uut (
        .iOpCode     (iOpCode),
        .iAcc        (iAcc),
        .iEffOperand (iEffOperand),
        .iSR         (iSR),
        .oResult     (oResult),
        .oIxResult   (oIxResult),
        .oFlags      (oFlags),
        .oAccWe      (oAccWe),
        .oIxWe       (oIxWe)
    );

    //=========================================================================
    // OpCode定数
    //=========================================================================
    parameter OP_NOP   = 7'b0000000;
    parameter OP_ADD   = 7'b0000001;
    parameter OP_SUB   = 7'b0000010;
    parameter OP_AND   = 7'b0000011;
    parameter OP_OR    = 7'b0000100;
    parameter OP_XOR   = 7'b0000101;
    parameter OP_INC   = 7'b0000110;
    parameter OP_DEC   = 7'b0000111;
    parameter OP_MOV   = 7'b0001000;
    parameter OP_MOVIX = 7'b0001001;
    parameter OP_SHL   = 7'b0001010;
    parameter OP_SHR   = 7'b0001011;

    //=========================================================================
    // 自己診断タスク: 演算結果 + フラグ + WriteEnable を一括検証
    //=========================================================================
    task check;
        input [7:0]  exp_result;
        input [3:0]  exp_flags;     // {CF, ZF, SF, OF}
        input        exp_acc_we;
        input        exp_ix_we;
        input [20*8-1:0] test_name; // 最大20文字
    begin
        test_num = test_num + 1;
        if (oResult  === exp_result  &&
            oFlags   === exp_flags   &&
            oAccWe   === exp_acc_we  &&
            oIxWe    === exp_ix_we) begin
            $display("PASS [%3d] %-20s | Result=%02h Flags=%b AccWe=%b IxWe=%b",
                     test_num, test_name, oResult, oFlags, oAccWe, oIxWe);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL [%3d] %-20s", test_num, test_name);
            $display("          Expected: Result=%02h Flags=%b AccWe=%b IxWe=%b",
                     exp_result, exp_flags, exp_acc_we, exp_ix_we);
            $display("          Actual:   Result=%02h Flags=%b AccWe=%b IxWe=%b",
                     oResult, oFlags, oAccWe, oIxWe);
            fail_count = fail_count + 1;
        end
    end
    endtask

    // IX結果専用チェックタスク
    task check_ix;
        input [7:0]  exp_ix_result;
        input [3:0]  exp_flags;
        input        exp_acc_we;
        input        exp_ix_we;
        input [20*8-1:0] test_name;
    begin
        test_num = test_num + 1;
        if (oIxResult === exp_ix_result &&
            oFlags    === exp_flags     &&
            oAccWe    === exp_acc_we    &&
            oIxWe     === exp_ix_we) begin
            $display("PASS [%3d] %-20s | IxResult=%02h Flags=%b AccWe=%b IxWe=%b",
                     test_num, test_name, oIxResult, oFlags, oAccWe, oIxWe);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL [%3d] %-20s", test_num, test_name);
            $display("          Expected: IxResult=%02h Flags=%b AccWe=%b IxWe=%b",
                     exp_ix_result, exp_flags, exp_acc_we, exp_ix_we);
            $display("          Actual:   IxResult=%02h Flags=%b AccWe=%b IxWe=%b",
                     oIxResult, oFlags, oAccWe, oIxWe);
            fail_count = fail_count + 1;
        end
    end
    endtask

    //=========================================================================
    // テスト実行
    //=========================================================================
    initial begin
        $dumpfile("tb_alu_core.vcd");
        $dumpvars(0, tb_alu_core);

        $display("================================================================");
        $display("  ALU Core Unit Test — 全12命令 + 境界条件テスト");
        $display("================================================================");
        iSR = 4'b0000;

        //=====================================================================
        // [1] NOP: 何もしない
        //=====================================================================
        $display("\n--- NOP ---");
        iOpCode = OP_NOP; iAcc = 8'h42; iEffOperand = 8'h00; #10;
        check(8'h42, 4'b0000, 1'b0, 1'b0, "NOP basic");

        // NOP: フラグ保持確認
        iSR = 4'b1111;
        iOpCode = OP_NOP; iAcc = 8'h00; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b1111, 1'b0, 1'b0, "NOP flag preserve");
        iSR = 4'b0000;

        //=====================================================================
        // [2] ADD: 加算
        //=====================================================================
        $display("\n--- ADD ---");
        // 基本加算
        iOpCode = OP_ADD; iAcc = 8'h10; iEffOperand = 8'h20; #10;
        check(8'h30, 4'b0000, 1'b1, 1'b0, "ADD 10+20=30");

        // CF=1, ZF=1: 0xFF + 0x01 = 0x00
        iOpCode = OP_ADD; iAcc = 8'hFF; iEffOperand = 8'h01; #10;
        check(8'h00, 4'b1100, 1'b1, 1'b0, "ADD FF+01 CF ZF");

        // OF=1: 127+1=128(0x80), 正+正→負
        iOpCode = OP_ADD; iAcc = 8'h7F; iEffOperand = 8'h01; #10;
        check(8'h80, 4'b0011, 1'b1, 1'b0, "ADD 7F+01 OF");

        // OF=1: (-128)+(-1)=+127, 負+負→正
        iOpCode = OP_ADD; iAcc = 8'h80; iEffOperand = 8'h80; #10;
        // 0x80+0x80=0x100→0x00, CF=1,ZF=1,SF=0,OF=1
        check(8'h00, 4'b1101, 1'b1, 1'b0, "ADD 80+80 CF ZF OF");

        // SF=1: 結果が負数
        iOpCode = OP_ADD; iAcc = 8'h70; iEffOperand = 8'h70; #10;
        // 0x70+0x70=0xE0, CF=0,ZF=0,SF=1,OF=1
        check(8'hE0, 4'b0011, 1'b1, 1'b0, "ADD 70+70 SF OF");

        // 0+0=0: ZF=1
        iOpCode = OP_ADD; iAcc = 8'h00; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b0100, 1'b1, 1'b0, "ADD 00+00 ZF");

        //=====================================================================
        // [3] SUB: 減算
        //=====================================================================
        $display("\n--- SUB ---");
        // 基本減算
        iOpCode = OP_SUB; iAcc = 8'h30; iEffOperand = 8'h10; #10;
        check(8'h20, 4'b0000, 1'b1, 1'b0, "SUB 30-10=20");

        // CF=1(ボロー): 0x00 - 0x01 = 0xFF
        iOpCode = OP_SUB; iAcc = 8'h00; iEffOperand = 8'h01; #10;
        check(8'hFF, 4'b1010, 1'b1, 1'b0, "SUB 00-01 CF SF");

        // ZF=1: 同値減算
        iOpCode = OP_SUB; iAcc = 8'h42; iEffOperand = 8'h42; #10;
        check(8'h00, 4'b0100, 1'b1, 1'b0, "SUB 42-42 ZF");

        // OF=1: 正-負→負オーバーフロー (0x7F - 0xFF)
        // 127 - (-1) = 128, but wraps: 0x7F-0xFF = 0x80(borrow)
        iOpCode = OP_SUB; iAcc = 8'h7F; iEffOperand = 8'hFF; #10;
        // {1'b0,7F} - {1'b0,FF} = 9'h180 → result=0x80, CF=1
        // OF: acc[7]=0, eff[7]=1, result[7]=1 → (0!=1)&&(1!=0)=1
        check(8'h80, 4'b1011, 1'b1, 1'b0, "SUB 7F-FF OF CF SF");

        // OF=1: 負-正→正オーバーフロー (0x80 - 0x01)
        // -128 - 1 = -129 → 0x7F
        iOpCode = OP_SUB; iAcc = 8'h80; iEffOperand = 8'h01; #10;
        // {1'b0,80} - {1'b0,01} = 9'h07F → result=0x7F, CF=0
        // OF: acc[7]=1, eff[7]=0, result[7]=0 → (1!=0)&&(0!=1)=1
        check(8'h7F, 4'b0001, 1'b1, 1'b0, "SUB 80-01 OF");

        //=====================================================================
        // [4] AND: 論理積
        //=====================================================================
        $display("\n--- AND ---");
        // ZF=1: マスク結果ゼロ
        iOpCode = OP_AND; iAcc = 8'hF0; iEffOperand = 8'h0F; #10;
        check(8'h00, 4'b0100, 1'b1, 1'b0, "AND F0&0F ZF");

        // SF=1: 結果のMSB=1
        iOpCode = OP_AND; iAcc = 8'hFF; iEffOperand = 8'h80; #10;
        check(8'h80, 4'b0010, 1'b1, 1'b0, "AND FF&80 SF");

        // 通常: 部分マスク
        iOpCode = OP_AND; iAcc = 8'hA5; iEffOperand = 8'hF0; #10;
        check(8'hA0, 4'b0010, 1'b1, 1'b0, "AND A5&F0=A0 SF");

        // CF,OF常にクリア確認
        iSR = 4'b1001; // 事前にCF=1,OF=1を設定
        iOpCode = OP_AND; iAcc = 8'hFF; iEffOperand = 8'hFF; #10;
        check(8'hFF, 4'b0010, 1'b1, 1'b0, "AND CF OF clear");
        iSR = 4'b0000;

        //=====================================================================
        // [5] OR: 論理和
        //=====================================================================
        $display("\n--- OR ---");
        iOpCode = OP_OR; iAcc = 8'hF0; iEffOperand = 8'h0F; #10;
        check(8'hFF, 4'b0010, 1'b1, 1'b0, "OR F0|0F=FF SF");

        // ZF=1: 0|0=0
        iOpCode = OP_OR; iAcc = 8'h00; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b0100, 1'b1, 1'b0, "OR 00|00 ZF");

        iOpCode = OP_OR; iAcc = 8'h0A; iEffOperand = 8'h50; #10;
        check(8'h5A, 4'b0000, 1'b1, 1'b0, "OR 0A|50=5A");

        //=====================================================================
        // [6] XOR: 排他的論理和
        //=====================================================================
        $display("\n--- XOR ---");
        iOpCode = OP_XOR; iAcc = 8'hAA; iEffOperand = 8'hFF; #10;
        check(8'h55, 4'b0000, 1'b1, 1'b0, "XOR AA^FF=55");

        // ZF=1: 同値XOR
        iOpCode = OP_XOR; iAcc = 8'h42; iEffOperand = 8'h42; #10;
        check(8'h00, 4'b0100, 1'b1, 1'b0, "XOR 42^42 ZF");

        // SF=1: NOT演算(XOR FF)
        iOpCode = OP_XOR; iAcc = 8'h00; iEffOperand = 8'hFF; #10;
        check(8'hFF, 4'b0010, 1'b1, 1'b0, "XOR 00^FF=FF SF");

        //=====================================================================
        // [7] INC: インクリメント
        //=====================================================================
        $display("\n--- INC ---");
        iOpCode = OP_INC; iAcc = 8'h09; iEffOperand = 8'h00; #10;
        check(8'h0A, 4'b0000, 1'b1, 1'b0, "INC 09+1=0A");

        // CF=1,ZF=1: 0xFF+1=0x00
        iOpCode = OP_INC; iAcc = 8'hFF; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b1100, 1'b1, 1'b0, "INC FF+1 CF ZF");

        // OF=1: 0x7F+1=0x80 (127→-128)
        iOpCode = OP_INC; iAcc = 8'h7F; iEffOperand = 8'h00; #10;
        check(8'h80, 4'b0011, 1'b1, 1'b0, "INC 7F+1 SF OF");

        // DEC 1→0: ZF=1
        iOpCode = OP_INC; iAcc = 8'h00; iEffOperand = 8'h00; #10;
        check(8'h01, 4'b0000, 1'b1, 1'b0, "INC 00+1=01");

        //=====================================================================
        // [8] DEC: デクリメント
        //=====================================================================
        $display("\n--- DEC ---");
        iOpCode = OP_DEC; iAcc = 8'h0A; iEffOperand = 8'h00; #10;
        check(8'h09, 4'b0000, 1'b1, 1'b0, "DEC 0A-1=09");

        // CF=1: 0x00-1=0xFF (ボロー)
        iOpCode = OP_DEC; iAcc = 8'h00; iEffOperand = 8'h00; #10;
        check(8'hFF, 4'b1010, 1'b1, 1'b0, "DEC 00-1 CF SF");

        // OF=1: 0x80-1=0x7F (-128→127)
        iOpCode = OP_DEC; iAcc = 8'h80; iEffOperand = 8'h00; #10;
        check(8'h7F, 4'b0001, 1'b1, 1'b0, "DEC 80-1 OF");

        // ZF=1: 0x01-1=0x00
        iOpCode = OP_DEC; iAcc = 8'h01; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b0100, 1'b1, 1'b0, "DEC 01-1 ZF");

        //=====================================================================
        // [9] MOV: ロード
        //=====================================================================
        $display("\n--- MOV ---");
        // 基本ロード + CF/OF保持
        iSR = 4'b1001;  // CF=1, OF=1
        iOpCode = OP_MOV; iAcc = 8'hFF; iEffOperand = 8'h42; #10;
        // ACC←0x42, ZF=0,SF=0, CF/OF保持→flags=1001
        check(8'h42, 4'b1001, 1'b1, 1'b0, "MOV 42 CF/OF keep");
        iSR = 4'b0000;

        // MOV 0x00: ZF=1
        iOpCode = OP_MOV; iAcc = 8'hFF; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b0100, 1'b1, 1'b0, "MOV 00 ZF");

        // MOV 0x80: SF=1
        iOpCode = OP_MOV; iAcc = 8'h00; iEffOperand = 8'h80; #10;
        check(8'h80, 4'b0010, 1'b1, 1'b0, "MOV 80 SF");

        //=====================================================================
        // [10] MOVIX: IXレジスタ転送
        //=====================================================================
        $display("\n--- MOVIX ---");
        iSR = 4'b1010;  // フラグ保持確認用
        iOpCode = OP_MOVIX; iAcc = 8'hFF; iEffOperand = 8'hAB; #10;
        check_ix(8'hAB, 4'b1010, 1'b0, 1'b1, "MOVIX AB");

        iOpCode = OP_MOVIX; iAcc = 8'hFF; iEffOperand = 8'h00; #10;
        check_ix(8'h00, 4'b1010, 1'b0, 1'b1, "MOVIX 00");
        iSR = 4'b0000;

        //=====================================================================
        // [11] SHL: 論理左シフト
        //=====================================================================
        $display("\n--- SHL ---");
        // 基本: 0xA5(10100101) → 0x4A(01001010), CF=1(MSB=1)
        iOpCode = OP_SHL; iAcc = 8'hA5; iEffOperand = 8'h00; #10;
        check(8'h4A, 4'b1000, 1'b1, 1'b0, "SHL A5 CF");

        // CF=0: MSB=0のケース
        iOpCode = OP_SHL; iAcc = 8'h01; iEffOperand = 8'h00; #10;
        check(8'h02, 4'b0000, 1'b1, 1'b0, "SHL 01=02");

        // ZF=1: 0x80→0x00, CF=1
        iOpCode = OP_SHL; iAcc = 8'h80; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b1100, 1'b1, 1'b0, "SHL 80 CF ZF");

        // SF=1: 0x40→0x80
        iOpCode = OP_SHL; iAcc = 8'h40; iEffOperand = 8'h00; #10;
        check(8'h80, 4'b0010, 1'b1, 1'b0, "SHL 40=80 SF");

        // ZF=1: 0x00→0x00
        iOpCode = OP_SHL; iAcc = 8'h00; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b0100, 1'b1, 1'b0, "SHL 00 ZF");

        //=====================================================================
        // [12] SHR: 論理右シフト
        //=====================================================================
        $display("\n--- SHR ---");
        // 基本: 0xA5(10100101) → 0x52(01010010), CF=1(LSB=1)
        iOpCode = OP_SHR; iAcc = 8'hA5; iEffOperand = 8'h00; #10;
        check(8'h52, 4'b1000, 1'b1, 1'b0, "SHR A5 CF");

        // CF=0: LSB=0
        iOpCode = OP_SHR; iAcc = 8'h80; iEffOperand = 8'h00; #10;
        check(8'h40, 4'b0000, 1'b1, 1'b0, "SHR 80=40");

        // ZF=1: 0x01→0x00, CF=1
        iOpCode = OP_SHR; iAcc = 8'h01; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b1100, 1'b1, 1'b0, "SHR 01 CF ZF");

        // ZF=1: 0x00→0x00
        iOpCode = OP_SHR; iAcc = 8'h00; iEffOperand = 8'h00; #10;
        check(8'h00, 4'b0100, 1'b1, 1'b0, "SHR 00 ZF");

        //=====================================================================
        // [13] undefined OpCode → default(NOP相当)
        //=====================================================================
        $display("\n--- UNDEFINED OPCODE ---");
        iSR = 4'b0101;
        iOpCode = 7'b1111111; iAcc = 8'hAA; iEffOperand = 8'h55; #10;
        check(8'hAA, 4'b0101, 1'b0, 1'b0, "UNDEF default");
        iSR = 4'b0000;

        //=====================================================================
        // 結果サマリ
        //=====================================================================
        $display("");
        $display("================================================================");
        $display("  Total: %0d tests,  PASS: %0d,  FAIL: %0d",
                 test_num, pass_count, fail_count);
        $display("================================================================");

        if (fail_count == 0)
            $display("  >>> ALL TESTS PASSED <<<");
        else
            $display("  >>> %0d TEST(S) FAILED <<<", fail_count);

        $display("================================================================");
        $finish;
    end

endmodule
