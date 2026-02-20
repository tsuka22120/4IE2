# 8ビットALU — 集積回路設計 最終課題

## プロジェクト概要

高専 集積回路設計 最終課題のALU（演算装置）プロジェクト。
Gowin GW1NR-9上にVerilog HDLで8ビットALUを構築する。

- **12命令** 対応（課題要件4命令の3倍）
- **4フラグ** ステータスレジスタ（CF/ZF/SF/OF）
- **インデックス修飾** によるアドレッシング
- **SW1〜16** による直接命令入力（加点要素 ✅）
- **目標**: S評価（最高評価）

## ディレクトリ構成

```
ALU/
├── ALU_SPECIFICATION.md         # ALU仕様書（命令・フラグ・表示の真実のソース）
├── README.md                    # このファイル
├── .cursorrules/
│   └── coding_rules.md          # コーディング規約・メモリバンク運用ルール
├── data/                        # 元資料（課題要件・ピンアサイン・PDF）
│   ├── REQUIREMENT.md
│   ├── PIN.md
│   ├── 最終課題.pdf
│   └── ALUの作り方.pdf
├── docs/memory_bank/            # メモリバンク（設計情報の記録庫）
│   ├── projectContext.md        # プロジェクト概要・技術スタック
│   ├── systemPatterns.md        # アーキテクチャ・モジュール構成・インターフェース定義
│   └── progress.md              # 進捗管理・決定事項ログ・実行コマンド
├── src/                         # RTLソースコード
│   ├── alu_top.v                # トップモジュール
│   ├── edge_detector.v          # SW17エッジ検出
│   ├── instruction_decoder.v    # 命令デコード・IX修飾
│   ├── alu_core.v               # 12命令の演算・フラグ生成
│   ├── register_file.v          # ACC/IX/SR保持・更新
│   ├── display_controller.v     # 7セグ表示制御（3モード切替）
│   └── alu_top.cst              # ピンアサインファイル
└── test/                        # テストベンチ
    ├── tb_alu_core.v            # ALU Core単体テスト（46ケース）
    └── tb_alu_top.v             # 統合テスト（30ケース、5フェーズ）
```

## クイックスタート

### シミュレーション（Icarus Verilog）

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

### FPGA書き込み（Gowin EDA）

1. Gowin EDAで新規プロジェクト作成（Part: GW1NR-LV9QN88PC6/I5）
2. `src/` 内の全 `.v` ファイルをDesign Sourceに追加
3. `src/alu_top.cst` をConstraint Fileに追加
4. Synthesize → Place & Route → Download

## 現在の進捗

**実装・テストベンチ作成完了** → シミュレーション実行待ち

詳細は `docs/memory_bank/progress.md` を参照。

## AI（Cursor/Gemini/Antigravity）との作業再開

このプロジェクトを別PCで開いた場合、AIに以下の指示を出すことで状況を完全に把握してもらえます：

> **指示例**: 「docs/memory_bank/ 内のファイルを全て読み、現在のプロジェクト状況を把握してください。ALU_SPECIFICATION.md が仕様の真実のソースです。」

AIが読むべきファイル（優先順）：

1. `docs/memory_bank/progress.md` — 現在の進捗と残作業
2. `docs/memory_bank/systemPatterns.md` — アーキテクチャとインターフェース定義
3. `docs/memory_bank/projectContext.md` — 要件・技術スタック
4. `.cursorrules/coding_rules.md` — コーディング規約
5. `ALU_SPECIFICATION.md` — 完全な仕様書
