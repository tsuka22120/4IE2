# ============================================================
# 精密流量・集水域データプロバイダー
# ============================================================
# 
# データソース優先度:
# 1. 水文水質データベース（実測流量）
# 2. 国土数値情報 流域メッシュデータ
# 3. pyshedsによるDEMベース集水域解析
# 4. 既存の推定ロジック（フォールバック）
# ============================================================

import os
import json
import requests
import numpy as np
from pathlib import Path
from typing import Optional, Dict, List, Tuple, Any
from dataclasses import dataclass
from shapely.geometry import Point, Polygon
import warnings

warnings.filterwarnings('ignore')

# データキャッシュディレクトリ
DATA_DIR = Path(__file__).parent / "data"
DATA_DIR.mkdir(exist_ok=True)

# ============================================================
# データクラス
# ============================================================

@dataclass
class FlowMeasurement:
    """流量実測データ"""
    station_code: str
    station_name: str
    river_name: str
    lat: float
    lon: float
    mean_flow: float  # 平均流量 (m³/s)
    max_flow: float   # 最大流量 (m³/s)
    min_flow: float   # 最小流量 (m³/s)
    catchment_area: float  # 集水域面積 (km²)
    data_source: str

@dataclass
class CatchmentInfo:
    """集水域情報"""
    area_km2: float
    river_code: str
    river_name: str
    source: str  # 'ksj' (国土数値情報), 'dem', 'estimated'


# ============================================================
# 水文水質データベース アクセスクラス
# ============================================================

class WaterInfoDatabase:
    """
    水文水質データベース（国土交通省）からのデータ取得
    
    注意: 直接APIはないため、主要河川の観測所データをローカルにキャッシュして使用
    """
    
    # 主要河川の代表的な流量データ（事前調査に基づく）
    # 実際の運用では水文水質データベースからダウンロードしたCSVを読み込む
    MAJOR_RIVER_FLOWS = {
        # 河川名: (平均流量 m³/s, 集水域面積 km², 代表観測所)
        '千曲川': (150.0, 7163.0, '杭瀬下'),
        '梓川': (35.0, 790.0, '島内'),
        '犀川': (80.0, 2271.0, '小市'),
        '信濃川': (510.0, 11900.0, '大河津'),
        '利根川': (280.0, 16840.0, '八斗島'),
        '荒川': (45.0, 2940.0, '寄居'),
        '多摩川': (25.0, 1240.0, '田園調布'),
        '淀川': (250.0, 8240.0, '枚方'),
        '木曽川': (200.0, 5275.0, '犬山'),
        '天竜川': (150.0, 5090.0, '鹿島'),
        '富士川': (120.0, 3990.0, '清水端'),
        '阿賀野川': (280.0, 7710.0, '馬下'),
        '最上川': (240.0, 7040.0, '高屋'),
        '北上川': (180.0, 10150.0, '登米'),
        '石狩川': (330.0, 14330.0, '石狩大橋'),
        '筑後川': (100.0, 2860.0, '瀬の下'),
        '四万十川': (80.0, 2270.0, '具同'),
        '吉野川': (120.0, 3750.0, '岩津'),
        '江の川': (90.0, 3870.0, '川本'),
        '球磨川': (75.0, 1880.0, '人吉'),
    }
    
    # 河川タイプ別の平均比流量 (m³/s/km²)
    SPECIFIC_DISCHARGE = {
        'mountain': 0.035,  # 山岳渓流
        'midstream': 0.025,  # 中流域
        'downstream': 0.018,  # 下流域
    }
    
    def __init__(self, cache_dir: Optional[Path] = None):
        self.cache_dir = cache_dir or DATA_DIR / "water_info"
        self.cache_dir.mkdir(exist_ok=True)
        self.stations: Dict[str, FlowMeasurement] = {}
        self._load_cached_data()
    
    def _load_cached_data(self):
        """キャッシュされた観測所データを読み込む"""
        cache_file = self.cache_dir / "stations.json"
        if cache_file.exists():
            try:
                with open(cache_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    for k, v in data.items():
                        self.stations[k] = FlowMeasurement(**v)
            except Exception as e:
                print(f"⚠ 観測所キャッシュ読み込みエラー: {e}")
    
    def _save_cached_data(self):
        """観測所データをキャッシュに保存"""
        cache_file = self.cache_dir / "stations.json"
        data = {k: v.__dict__ for k, v in self.stations.items()}
        with open(cache_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    
    def get_flow_for_river(self, river_name: str) -> Optional[Tuple[float, float]]:
        """
        河川名から流量と集水域面積を取得
        
        Returns:
            (平均流量 m³/s, 集水域面積 km²) or None
        """
        # 完全一致
        if river_name in self.MAJOR_RIVER_FLOWS:
            flow, area, _ = self.MAJOR_RIVER_FLOWS[river_name]
            return (flow, area)
        
        # 部分一致
        for key, (flow, area, _) in self.MAJOR_RIVER_FLOWS.items():
            if key in river_name or river_name in key:
                return (flow, area)
        
        return None
    
    def estimate_flow_from_area(self, catchment_area_km2: float, 
                                 elevation: float = 500) -> float:
        """
        集水域面積から流量を推定
        
        Args:
            catchment_area_km2: 集水域面積 (km²)
            elevation: 平均標高 (m)
        
        Returns:
            推定流量 (m³/s)
        """
        if elevation > 1000:
            specific_q = self.SPECIFIC_DISCHARGE['mountain']
        elif elevation > 300:
            specific_q = self.SPECIFIC_DISCHARGE['midstream']
        else:
            specific_q = self.SPECIFIC_DISCHARGE['downstream']
        
        return catchment_area_km2 * specific_q
    
    def find_nearest_station(self, lat: float, lon: float, 
                              max_distance_km: float = 50) -> Optional[FlowMeasurement]:
        """最寄りの観測所を検索"""
        from geopy.distance import geodesic
        
        nearest = None
        min_dist = float('inf')
        
        for station in self.stations.values():
            dist = geodesic((lat, lon), (station.lat, station.lon)).kilometers
            if dist < min_dist and dist <= max_distance_km:
                min_dist = dist
                nearest = station
        
        return nearest


# ============================================================
# 国土数値情報 流域メッシュデータ アクセスクラス
# ============================================================

class KSJCatchmentData:
    """
    国土数値情報 流域メッシュデータへのアクセス
    
    データソース: https://nlftp.mlit.go.jp/ksj/
    """
    
    # 流域メッシュダウンロードURL（GeoJSON形式）
    # 実際のURLは国土数値情報サイトから取得
    BASE_URL = "https://nlftp.mlit.go.jp/ksj/gml/data/W07/"
    
    def __init__(self, cache_dir: Optional[Path] = None):
        self.cache_dir = cache_dir or DATA_DIR / "ksj_catchment"
        self.cache_dir.mkdir(exist_ok=True)
        self.catchment_data: Dict = {}
        self._load_cached_data()
    
    def _load_cached_data(self):
        """キャッシュされた流域データを読み込む"""
        cache_file = self.cache_dir / "catchments.json"
        if cache_file.exists():
            try:
                with open(cache_file, 'r', encoding='utf-8') as f:
                    self.catchment_data = json.load(f)
            except Exception as e:
                print(f"⚠ 流域キャッシュ読み込みエラー: {e}")
    
    def get_catchment_for_point(self, lat: float, lon: float) -> Optional[CatchmentInfo]:
        """
        指定座標の集水域情報を取得
        
        実際の実装では、流域メッシュのシェープファイルを読み込んで
        空間検索を行う
        """
        # キャッシュにある場合
        key = f"{lat:.4f},{lon:.4f}"
        if key in self.catchment_data:
            data = self.catchment_data[key]
            return CatchmentInfo(**data)
        
        return None
    
    def download_catchment_data(self, prefecture_code: str) -> bool:
        """
        都道府県別の流域メッシュデータをダウンロード
        
        Args:
            prefecture_code: 都道府県コード（例: "20" = 長野県）
        """
        # 実際の実装ではここでデータをダウンロード
        # 現時点ではプレースホルダー
        print(f"  流域メッシュデータのダウンロードは手動で行ってください")
        print(f"  URL: {self.BASE_URL}")
        return False


# ============================================================
# DEM解析による集水域計算 クラス
# ============================================================

class DEMCatchmentAnalyzer:
    """
    DEMデータからの集水域解析
    pyshedsライブラリを使用
    """
    
    def __init__(self, dem_path: Optional[str] = None):
        self.dem_path = dem_path
        self.grid = None
        self.dem = None
        self.fdir = None
        self.acc = None
        self._is_initialized = False
    
    def initialize(self, dem_path: str) -> bool:
        """DEMデータを読み込んで初期化"""
        try:
            from pysheds.grid import Grid
            
            self.grid = Grid.from_raster(dem_path)
            self.dem = self.grid.read_raster(dem_path)
            
            # ピット埋め
            pit_filled_dem = self.grid.fill_pits(self.dem)
            
            # フラット解消
            flooded_dem = self.grid.fill_depressions(pit_filled_dem)
            inflated_dem = self.grid.resolve_flats(flooded_dem)
            
            # 流向計算
            self.fdir = self.grid.flowdir(inflated_dem)
            
            # 流量累積計算
            self.acc = self.grid.accumulation(self.fdir)
            
            self._is_initialized = True
            print(f"✓ DEM解析初期化完了: {dem_path}")
            return True
            
        except ImportError:
            print("⚠ pyshedsがインストールされていません")
            return False
        except Exception as e:
            print(f"⚠ DEM解析初期化エラー: {e}")
            return False
    
    def get_catchment_area(self, lat: float, lon: float, 
                           snap_distance: int = 5) -> Optional[float]:
        """
        指定座標の集水域面積を計算
        
        Args:
            lat, lon: 座標
            snap_distance: スナップ距離（ピクセル）
        
        Returns:
            集水域面積 (km²) or None
        """
        if not self._is_initialized:
            return None
        
        try:
            # 座標をピクセルに変換
            x, y = self.grid.nearest_cell(lon, lat)
            
            # 最も流量累積の大きいセルにスナップ
            x_snap, y_snap = self.grid.snap_to_mask(
                self.acc > 100,  # 最低累積閾値
                (x, y),
                snap_distance
            )
            
            # 集水域をデリニエーション
            catch = self.grid.catchment(
                x=x_snap,
                y=y_snap,
                fdir=self.fdir,
                xytype='index'
            )
            
            # 面積計算（ピクセル数 × ピクセル面積）
            cell_area_km2 = abs(self.grid.affine.a * self.grid.affine.e) * (111 ** 2)
            area_km2 = catch.sum() * cell_area_km2
            
            return area_km2
            
        except Exception as e:
            print(f"⚠ 集水域計算エラー ({lat}, {lon}): {e}")
            return None
    
    def get_flow_accumulation(self, lat: float, lon: float) -> Optional[int]:
        """指定座標の流量累積値を取得"""
        if not self._is_initialized or self.acc is None:
            return None
        
        try:
            x, y = self.grid.nearest_cell(lon, lat)
            return int(self.acc[y, x])
        except:
            return None


# ============================================================
# 統合データプロバイダー
# ============================================================

class HydroDataProvider:
    """
    水文データの統合プロバイダー
    
    複数のデータソースを優先度順に照会し、
    最も信頼性の高いデータを返す
    """
    
    def __init__(self, dem_path: Optional[str] = None):
        self.water_info_db = WaterInfoDatabase()
        self.ksj_catchment = KSJCatchmentData()
        self.dem_analyzer = DEMCatchmentAnalyzer()
        
        if dem_path and os.path.exists(dem_path):
            self.dem_analyzer.initialize(dem_path)
        
        self.data_source_priority = [
            'water_info_db',  # 水文水質データベース（実測）
            'ksj',            # 国土数値情報
            'dem',            # DEM解析
            'estimated'       # 推定
        ]
    
    def get_flow_data(self, lat: float, lon: float, 
                      river_name: Optional[str] = None,
                      river_length_km: float = 1.0,
                      elevation: float = 500,
                      precipitation_mm: float = 1500) -> Dict[str, Any]:
        """
        指定座標の流量データを取得
        
        Returns:
            {
                'flow': 流量 (m³/s),
                'catchment_area': 集水域面積 (km²),
                'source': データソース,
                'confidence': 信頼度 (0-1)
            }
        """
        result = {
            'flow': 0.0,
            'catchment_area': 0.0,
            'source': 'estimated',
            'confidence': 0.3
        }
        
        # 1. 水文水質データベースから実測流量を取得
        if river_name:
            flow_data = self.water_info_db.get_flow_for_river(river_name)
            if flow_data:
                result['flow'] = flow_data[0]
                result['catchment_area'] = flow_data[1]
                result['source'] = 'water_info_db'
                result['confidence'] = 1.0
                return result
        
        # 2. 国土数値情報から集水域データを取得
        catchment_info = self.ksj_catchment.get_catchment_for_point(lat, lon)
        if catchment_info:
            result['catchment_area'] = catchment_info.area_km2
            result['flow'] = self.water_info_db.estimate_flow_from_area(
                catchment_info.area_km2, elevation
            )
            result['source'] = 'ksj'
            result['confidence'] = 0.8
            return result
        
        # 3. DEM解析から集水域を計算
        dem_area = self.dem_analyzer.get_catchment_area(lat, lon)
        if dem_area:
            result['catchment_area'] = dem_area
            result['flow'] = self.water_info_db.estimate_flow_from_area(
                dem_area, elevation
            )
            result['source'] = 'dem'
            result['confidence'] = 0.6
            return result
        
        # 4. 従来の推定ロジック（フォールバック）
        result['catchment_area'] = self._estimate_catchment_from_length(river_length_km)
        result['flow'] = self._estimate_flow_legacy(
            result['catchment_area'], precipitation_mm, elevation
        )
        result['source'] = 'estimated'
        result['confidence'] = 0.3
        
        return result
    
    def _estimate_catchment_from_length(self, length_km: float) -> float:
        """河川長から集水域面積を推定（既存ロジック）"""
        length_km = max(length_km, 0.5)
        return 2.0 * (length_km ** 1.8)
    
    def _estimate_flow_legacy(self, catchment_area_km2: float,
                               precipitation_mm: float,
                               elevation: float) -> float:
        """従来の推定ロジックによる流量計算"""
        # 流出係数
        if elevation > 1000:
            runoff_coef = 0.7
        elif elevation > 300:
            runoff_coef = 0.5
        else:
            runoff_coef = 0.3
        
        # Q = A(km²) × P(mm/年) × C / (365 × 24 × 3600)
        seconds_per_year = 365 * 24 * 3600
        flow = (catchment_area_km2 * 1e6) * (precipitation_mm / 1000) * runoff_coef / seconds_per_year
        
        return max(0.5, min(flow, 100.0))
    
    def get_data_source_stats(self) -> Dict[str, int]:
        """データソース別の使用統計"""
        return {
            'water_info_db_stations': len(self.water_info_db.stations),
            'ksj_cached_points': len(self.ksj_catchment.catchment_data),
            'dem_initialized': self.dem_analyzer._is_initialized
        }


# ============================================================
# テスト用
# ============================================================

if __name__ == "__main__":
    print("=== 水文データプロバイダー テスト ===")
    
    provider = HydroDataProvider()
    
    # テスト1: 主要河川の流量取得
    print("\n1. 主要河川の流量取得:")
    for river in ['千曲川', '犀川', '梓川']:
        data = provider.get_flow_data(
            lat=36.2, lon=137.9,
            river_name=river
        )
        print(f"  {river}: 流量={data['flow']:.1f} m³/s, "
              f"集水域={data['catchment_area']:.1f} km², "
              f"ソース={data['source']}")
    
    # テスト2: フォールバック推定
    print("\n2. フォールバック推定:")
    data = provider.get_flow_data(
        lat=36.2, lon=137.9,
        river_name=None,
        river_length_km=5.0,
        elevation=800,
        precipitation_mm=1000
    )
    print(f"  流量={data['flow']:.2f} m³/s, "
          f"集水域={data['catchment_area']:.1f} km², "
          f"ソース={data['source']}, 信頼度={data['confidence']}")
    
    print("\n✓ テスト完了")
