# ============================================================
# 水力発電候補地選定システム V2 - Notebook用実行スクリプト
# ============================================================
# 
# このファイルをNotebookセルにコピーして実行するか、
# %run hydro_v2_runner.py で実行してください。
#
# 使用方法:
#   1. LOCATION_NAME を変更して対象地域を指定
#   2. セルを実行
#   3. 結果が deta/yyyymmddhhmm/ に自動保存されます
# ============================================================

# 設定値
LOCATION_NAME = "松本市"  # ← ここを変更して対象地域を指定
GRID_SIZE = 20           # グリッドサイズ（大きいほど詳細、計算時間増）
CANDIDATES_PER_TYPE = 20 # 各タイプの候補数
TOP_N = 10               # 出力する上位組合せ数

# ============================================================
# 実行
# ============================================================
import sys
import os

# hydro_selector_v2.py のパスを追加
if 'c:\\vscode\\4IE2\\ED' not in sys.path:
    sys.path.insert(0, r'c:\vscode\4IE2\ED')

from hydro_selector_v2 import HydroSiteSelectorV2

print(f"対象地域: {LOCATION_NAME}")
print(f"設定: grid_size={GRID_SIZE}, candidates={CANDIDATES_PER_TYPE}, top_n={TOP_N}")
print("="*60)

# インスタンス作成と分析実行
selector = HydroSiteSelectorV2(LOCATION_NAME)
map_result, fig_result = selector.run_analysis(
    grid_size=GRID_SIZE,
    candidates_per_type=CANDIDATES_PER_TYPE,
    top_n=TOP_N
)

# 結果表示
if selector.best_combinations:
    print("\n" + "="*60)
    print(f"上位{len(selector.best_combinations)}組の結果:")
    print("="*60)
    for i, combo in enumerate(selector.best_combinations, start=1):
        print(f"#{i}: 発電量={combo['power_kw']:.1f} kW, 落差={combo['head']:.1f} m, 流量={combo['flow']:.2f} m³/s")
    
    # 結果保存
    output_dir, saved_files = selector.save_results(map_result, fig_result)
    
    print(f"\n保存先: {output_dir}")
    print(f"保存ファイル数: {len(saved_files)}")
else:
    print("候補が見つかりませんでした。")

# 地図をNotebook上に表示（Jupyter環境の場合）
if map_result:
    try:
        from IPython.display import display
        display(map_result)
    except:
        print("地図はHTMLファイルをブラウザで開いて確認してください。")
