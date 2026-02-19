# System Patterns — アーキテクチャ・設計パターン

## アーキテクチャ概要

```
                        ┌─────────────────────────────────────┐
                        │         alu_top (Top Module)        │
                        │                                     │
  iToggleSw[15:0] ─────┤──→ instruction_decoder               │
  (SW1〜16)             │      │ opcode[6:0]                  │
                        │      │ ix_bit                        │
                        │      │ operand[7:0]                  │
                        │      │ eff_operand[7:0]              │
                        │      └──────────┐                    │
                        │                 ▼                    │
                        │              alu_core ──→ result[7:0]│
                        │                 │    ──→ flags[3:0]  │
                        │                 ▼                    │
  iToggleSw[16] ────────┤──→ edge_detector ──→ exec_pulse      │
  (SW17)                │                 │                    │
                        │                 ▼                    │
                        │           register_file              │
                        │              │ acc[7:0]              │
                        │              │ ix[7:0]               │
                        │              │ sr[3:0]               │
                        │              └──────────┐            │
                        │                         ▼            │
  iToggleSw[17] ────────┤──→ display_controller                │
  iPushSw[0] ───────────┤      │ oDigit[3:0]                  │
  (SW18, S1)            │      │ oPattern[7:0]                │
                        │      └──────────────────────→ 出力   │
                        └─────────────────────────────────────┘
```

## モジュール一覧

| #   | モジュール名          | ファイル                    | 種別       | 役割                                             |
| --- | --------------------- | --------------------------- | ---------- | ------------------------------------------------ |
| 1   | `alu_top`             | `src/alu_top.v`             | トップ     | 全サブモジュールの接続、LED割当                  |
| 2   | `instruction_decoder` | `src/instruction_decoder.v` | 組み合わせ | インストラクション解析、IX修飾計算               |
| 3   | `alu_core`            | `src/alu_core.v`            | 組み合わせ | 12種類の演算実行、フラグ生成                     |
| 4   | `register_file`       | `src/register_file.v`       | 順序       | ACC/IX/SRの保持、実行パルスで更新                |
| 5   | `display_controller`  | `src/display_controller.v`  | 順序+組合  | ダイナミック点灯、7セグデコード、3モード表示切替 |
| 6   | `edge_detector`       | `src/edge_detector.v`       | 順序       | SW17の2段FF同期化＋立ち上がりエッジ検出          |

## モジュール別インターフェース定義

### edge_detector

|  方向  | 信号名  | 幅  | 説明                                |
| :----: | ------- | :-: | ----------------------------------- |
| input  | `iClk`  |  1  | システムクロック                    |
| input  | `iSw`   |  1  | SW17入力                            |
| output | `oRise` |  1  | 立ち上がり検出パルス（1クロック幅） |

### instruction_decoder

|  方向  | 信号名         | 幅  | 説明                       |
| :----: | -------------- | :-: | -------------------------- |
| input  | `iInstruction` | 16  | SW1〜16の値                |
| input  | `iIX`          |  8  | 現在のIXレジスタ値         |
| output | `oOpCode`      |  7  | 命令コード [15:9]          |
| output | `oIxBit`       |  1  | IX修飾ビット [8]           |
| output | `oOperand`     |  8  | 生のオペランド [7:0]       |
| output | `oEffOperand`  |  8  | 実効オペランド（IX修飾後） |

### alu_core

|  方向  | 信号名        | 幅  | 説明                      |
| :----: | ------------- | :-: | ------------------------- |
| input  | `iOpCode`     |  7  | 命令コード                |
| input  | `iAcc`        |  8  | 現在のACC値               |
| input  | `iEffOperand` |  8  | 実効オペランド            |
| input  | `iSR`         |  4  | 現在のSR値                |
| output | `oResult`     |  8  | 演算結果                  |
| output | `oIxResult`   |  8  | IX書込みデータ（MOVIX用） |
| output | `oFlags`      |  4  | {CF, ZF, SF, OF}          |
| output | `oAccWe`      |  1  | ACC書込みイネーブル       |
| output | `oIxWe`       |  1  | IX書込みイネーブル        |

### register_file

|  方向  | 信号名     | 幅  | 説明                |
| :----: | ---------- | :-: | ------------------- |
| input  | `iClk`     |  1  | システムクロック    |
| input  | `iExec`    |  1  | 実行パルス          |
| input  | `iAccData` |  8  | ACC書込みデータ     |
| input  | `iAccWe`   |  1  | ACC書込みイネーブル |
| input  | `iIxData`  |  8  | IX書込みデータ      |
| input  | `iIxWe`    |  1  | IX書込みイネーブル  |
| input  | `iFlags`   |  4  | フラグ書込みデータ  |
| output | `oAcc`     |  8  | 現在のACC値         |
| output | `oIx`      |  8  | 現在のIX値          |
| output | `oSR`      |  4  | 現在のSR値          |

### display_controller

|  方向  | 信号名         | 幅  | 説明                           |
| :----: | -------------- | :-: | ------------------------------ |
| input  | `iClk`         |  1  | システムクロック               |
| input  | `iSw18`        |  1  | SW18（表示モード切替）         |
| input  | `iS1`          |  1  | S1（表示モード切替）           |
| input  | `iInstruction` | 16  | 現在のインストラクション       |
| input  | `iAcc`         |  8  | ACC値                          |
| input  | `iIx`          |  8  | IX値                           |
| input  | `iSR`          |  4  | SR値                           |
| output | `oDigit`       |  4  | 桁選択（ワンホット）           |
| output | `oPattern`     |  8  | 7セグパターン（アクティブLOW） |

### alu_top（= FPGAピン）

|  方向  | 信号名      | 幅  | 説明                                               |
| :----: | ----------- | :-: | -------------------------------------------------- |
| input  | `iClk`      |  1  | システムクロック（ピン52）                         |
| input  | `iToggleSw` | 18  | トグルスイッチ SW1〜18                             |
| input  | `iPushSw`   |  2  | プッシュスイッチ S1, S2                            |
| output | `oDigit`    |  4  | 7セグ桁選択                                        |
| output | `oPattern`  |  8  | 7セグパターン                                      |
| output | `oLed`      |  6  | LED（[0]=CF,[1]=ZF,[2]=SF,[3]=OF,[4]=exec,[5]=IX） |

## 命令セット定義（真実のソース）

| OpCode[6:0] | 名前  | ニーモニック | 動作                | CF  | ZF  | SF  | OF  |
| :---------: | :---: | :----------: | :------------------ | :-: | :-: | :-: | :-: |
|  `0000000`  |  NOP  |    `NOP`     | 何もしない          |  -  |  -  |  -  |  -  |
|  `0000001`  |  ADD  |   `ADD d`    | ACC ← ACC + d       |  ✓  |  ✓  |  ✓  |  ✓  |
|  `0000010`  |  SUB  |   `SUB d`    | ACC ← ACC - d       |  ✓  |  ✓  |  ✓  |  ✓  |
|  `0000011`  |  AND  |   `AND d`    | ACC ← ACC & d       |  0  |  ✓  |  ✓  |  0  |
|  `0000100`  |  OR   |    `OR d`    | ACC ← ACC \| d      |  0  |  ✓  |  ✓  |  0  |
|  `0000101`  |  XOR  |   `XOR d`    | ACC ← ACC ^ d       |  0  |  ✓  |  ✓  |  0  |
|  `0000110`  |  INC  |    `INC`     | ACC ← ACC + 1       |  ✓  |  ✓  |  ✓  |  ✓  |
|  `0000111`  |  DEC  |    `DEC`     | ACC ← ACC - 1       |  ✓  |  ✓  |  ✓  |  ✓  |
|  `0001000`  |  MOV  |   `MOV d`    | ACC ← d             |  -  |  ✓  |  ✓  |  -  |
|  `0001001`  | MOVIX |  `MOVIX d`   | IX ← d              |  -  |  -  |  -  |  -  |
|  `0001010`  |  SHL  |    `SHL`     | ACC ← {ACC[6:0], 0} |  ✓  |  ✓  |  ✓  |  0  |
|  `0001011`  |  SHR  |    `SHR`     | ACC ← {0, ACC[7:1]} |  ✓  |  ✓  |  ✓  |  0  |

> 凡例: `d` = 実効オペランド, `✓` = 影響あり, `-` = 不変, `0` = クリア

## IX修飾ロジック

```verilog
if (ix_bit == 1'b0)
    eff_operand = operand;       // 直接参照
else
    eff_operand = ix + operand;  // インデックス修飾
```

## 設計原則

1. **同期設計**: 全レジスタは `posedge iClk` で動作
2. **ラッチ防止**: 全 `case`/`if` に `default`/`else` を付与
3. **感度リスト明示**: `always @(*)` は使用禁止 — 確認済み ✅
4. **1モジュール1ファイル**: モジュール名 = ファイル名
5. **命名規則**: 入力=`i`、出力=`o`、内部ワイヤ=`w_`、内部レジスタ=`r_`、定数=大文字
