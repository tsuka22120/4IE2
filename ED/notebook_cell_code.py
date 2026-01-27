# ============================================================
# 🔍 分析実行セル（修正版）
# ============================================================
import importlib
import sys
import os

# カレントディレクトリをパスに追加
if os.getcwd() not in sys.path:
    sys.path.insert(0, os.getcwd())

# モジュールを再読み込み（修正後のコードを反映）
for module_name in ['hydro_data_provider', 'hydro_selector_v2']:
    if module_name in sys.modules:
        try:
            importlib.reload(sys.modules[module_name])
        except Exception as e:
            print(f"⚠ {module_name}のリロードをスキップ: {e}")

from hydro_selector_v2 import HydroSiteSelectorV2

# インスタンス作成
selector = HydroSiteSelectorV2(LOCATION_NAME)

# 分析実行
map_result, fig_result = selector.run_analysis(
    grid_size=GRID_SIZE,
    candidates_per_type=CANDIDATES_PER_TYPE,
    top_n=TOP_N
)

# 結果保存
if selector.best_combinations:
    output_dir, saved_files = selector.save_results(map_result, fig_result)
    print(f"\n✓ 保存先: {output_dir}")
    print(f"✓ 保存ファイル数: {len(saved_files)}")
else:
    print("⚠ 候補が見つかりませんでした")
