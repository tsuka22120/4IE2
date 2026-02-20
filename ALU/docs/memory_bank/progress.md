# Progress — 進捗管理

## 現在のフェーズ

**FPGA VERIFIED** — シミュレーション・実機動作確認完了。レポート作成待ち。

## 完了タスク

- [x] 要件分析（REQUIREMENT.md, PIN.md）
- [x] ALU仕様書作成（ALU_SPECIFICATION.md — 12命令・4フラグ・IX修飾）
- [x] メモリバンク初期化
- [x] コーディング規約策定（.cursorrules/coding_rules.md）
- [x] モジュール分割・インターフェース定義（6モジュール）
- [x] 実装計画策定（4フェーズロードマップ）
- [x] Phase 1: edge_detector.v, instruction_decoder.v 実装
- [x] Phase 2: alu_core.v 実装（12命令＋4フラグ）
- [x] Phase 3: register_file.v, alu_top.v 実装
- [x] Phase 4: display_controller.v, alu_top.cst 実装
- [x] テストベンチ v1 作成
- [x] `always @(*)` 不使用の最終確認 ✅（全8箇所検査済み）
- [x] テストベンチ v2 強化（自己診断機能付き）
  - [x] tb_alu_core.v: 46テストケース（全12命令+境界条件+未定義OpCode）
  - [x] tb_alu_top.v: 30テストケース（5フェーズ統合テスト）
- [x] 検証チェックリスト・レポート用テンプレート作成

## 残作業

- [x] **Icarus Verilog シミュレーション実行**
  - ALU Core単体テスト: 46/46 PASS
  - 統合テスト: 27/27 PASS
  - VCDファイル生成済み（tb_alu_core.vcd, tb_alu_top.vcd）
- [x] シミュレーション結果の解析（ログ・VCD波形）
- [x] Gowin EDA で論理合成・配置配線
- [x] FPGA実機書き込み・動作確認
  - 7セグ: アクティブHIGHに修正
  - LED: アクティブLOWに修正
  - SW1〜SW16: ビット順反転（SW1=MSB）
  - S1: アクティブLOW反転
  - 全テスト（MOV/ADD/SUB/INC/MOVIX/IX修飾）成功
- [x] レポート作成（PDF）
  - 44ページ、2,404,351バイト
  - 全報告事項（仕様・ブロック図・操作方法・コード・ピンアサイン・テストベンチ・考察）完備

## 作成ファイル一覧

### ドキュメント

| パス                                 | 説明                                                               |
| ------------------------------------ | ------------------------------------------------------------------ |
| `ALU_SPECIFICATION.md`               | ALU仕様書（命令セット・フラグ・表示仕様の真実のソース）            |
| `.cursorrules/coding_rules.md`       | コーディング規約・メモリバンク運用ルール                           |
| `docs/memory_bank/projectContext.md` | プロジェクト概要・技術スタック・要件                               |
| `docs/memory_bank/systemPatterns.md` | アーキテクチャ図・モジュール構成・命令セット・インターフェース定義 |
| `docs/memory_bank/progress.md`       | 進捗管理（このファイル）                                           |

### RTLソース（src/）

| ファイル                | モジュール名          | 行数 | 種別                 |
| ----------------------- | --------------------- | :--: | -------------------- |
| `edge_detector.v`       | `edge_detector`       |  30  | 順序回路             |
| `instruction_decoder.v` | `instruction_decoder` |  38  | 組み合わせ回路       |
| `alu_core.v`            | `alu_core`            | 203  | 組み合わせ回路       |
| `register_file.v`       | `register_file`       |  67  | 順序回路             |
| `display_controller.v`  | `display_controller`  | 140  | 順序+組み合わせ      |
| `alu_top.v`             | `alu_top`             | 130  | トップモジュール     |
| `alu_top.cst`           | —                     |  —   | ピンアサインファイル |

### テストベンチ（test/）

| ファイル        | テスト数 | 内容                                                              |
| --------------- | :------: | ----------------------------------------------------------------- |
| `tb_alu_core.v` |    46    | 全12命令単体テスト（境界条件・フラグ保持・未定義OpCode含む）      |
| `tb_alu_top.v`  |    30    | 5フェーズ統合テスト（全命令・IX修飾・境界・エッジ検出・表示切替） |

### 元資料（data/）

| ファイル          | 説明                     |
| ----------------- | ------------------------ |
| `REQUIREMENT.md`  | 課題要件書               |
| `PIN.md`          | ピンアサイン（表1・表2） |
| `最終課題.pdf`    | 課題説明PDF              |
| `ALUの作り方.pdf` | 参考資料PDF              |

## シミュレーション実行コマンド

```bash
# ALU Core 単体テスト
iverilog -o test/tb_alu_core.vvp src/alu_core.v test/tb_alu_core.v
vvp test/tb_alu_core.vvp

# 統合テスト
iverilog -o test/tb_alu_top.vvp src/edge_detector.v src/instruction_decoder.v src/alu_core.v src/register_file.v src/display_controller.v src/alu_top.v test/tb_alu_top.v
vvp test/tb_alu_top.vvp

# 波形確認
gtkwave tb_alu_core.vcd
gtkwave tb_alu_top.vcd
```

## 決定事項ログ

| 日時             | 決定事項                                                             |
| ---------------- | -------------------------------------------------------------------- |
| 2026-02-20 02:02 | 8bitデータバス / 16bitインストラクション採用                         |
| 2026-02-20 02:02 | 12命令セット確定（NOP/ADD/SUB/AND/OR/XOR/INC/DEC/MOV/MOVIX/SHL/SHR） |
| 2026-02-20 02:02 | SR = 4bit (CF/ZF/SF/OF)                                              |
| 2026-02-20 02:02 | IX修飾: bit[8]で直接/インデックス切替                                |
| 2026-02-20 02:08 | 6モジュール構成で分割                                                |
| 2026-02-20 02:12 | 全モジュール実装完了                                                 |
| 2026-02-20 02:21 | テストベンチ v2 強化完了（46+30テスト、自己診断付き）                |
| 2026-02-20 02:29 | メモリバンク最終更新                                                 |
| 2026-02-20 15:51 | Icarus Verilog シミュレーション実行 — 全テストPASS（46+27=73テスト） |
| 2026-02-20 16:30 | 7セグアクティブHIGH修正・LEDアクティブLOW修正・SWビット順修正        |
| 2026-02-20 17:07 | スイッチ極性テスト実施・S1アクティブLOW反転確定                      |
| 2026-02-20 17:18 | FPGA実機動作確認完了（全テスト成功）                                 |
