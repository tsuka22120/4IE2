# ============================================================
# 水力発電候補地選定システム V2 - 改良版
# ============================================================

import folium
from folium import plugins
import numpy as np
import pandas as pd
import requests
from geopy.geocoders import Nominatim
from geopy.distance import geodesic
from scipy.ndimage import gaussian_filter
import matplotlib.pyplot as plt
from tqdm.notebook import tqdm
import time
from datetime import datetime
from itertools import combinations
import warnings
from shapely.geometry import Point, Polygon, MultiPolygon, LineString
from shapely.ops import unary_union
import sys
import os
import threading
import matplotlib

warnings.filterwarnings('ignore')

# ============================================================
# 定数定義（V2）
# ============================================================

# 物理定数
GRAVITY = 9.8
WATER_DENSITY = 1000
TURBINE_EFFICIENCY = 0.8

# API設定
ELEVATION_BATCH_SIZE = 100
ELEVATION_RETRY = 2
API_TIMEOUT = 60

# 地域別年間降水量 (mm/年)
PRECIPITATION_BY_REGION = {
    '北海道': 1100,
    '青森': 1300, '岩手': 1300, '宮城': 1200, '秋田': 1700, '山形': 1400, '福島': 1300,
    '茨城': 1400, '栃木': 1500, '群馬': 1200, '埼玉': 1400, '千葉': 1600, '東京': 1500, '神奈川': 1700,
    '新潟': 1900, '富山': 2300, '石川': 2400, '福井': 2500,
    '山梨': 1100, '長野': 1000, '岐阜': 2000, '静岡': 2300, '愛知': 1600,
    '三重': 1800, '滋賀': 1600, '京都': 1500, '大阪': 1300, '兵庫': 1200, '奈良': 1400, '和歌山': 1500,
    '鳥取': 1900, '島根': 1700, '岡山': 1100, '広島': 1500, '山口': 1800,
    '徳島': 1600, '香川': 1100, '愛媛': 1400, '高知': 2500,
    '福岡': 1600, '佐賀': 1900, '長崎': 1900, '熊本': 2000, '大分': 1700, '宮崎': 2500, '鹿児島': 2300,
    '沖縄': 2000,
    'default': 1500
}

# 流出係数
RUNOFF_COEFFICIENTS = {
    'mountain': 0.7,  # 山岳地域 (>1000m)
    'hill': 0.5,      # 丘陵地域 (300-1000m)
    'plain': 0.3      # 平野部 (<300m)
}

# スコアリング重み（V2）
WATER_SOURCE_WEIGHTS_V2 = {
    'elevation': 0.30,
    'river_proximity': 0.25,
    'flow': 0.20,
    'infrastructure': 0.15,
    'stability': 0.10
}

INTAKE_WEIGHTS_V2 = {
    'river_proximity': 0.40,
    'middle_elevation': 0.30,
    'gentle_slope': 0.20,
    'infrastructure': 0.10
}

POWERHOUSE_WEIGHTS_V2 = {
    'low_elevation': 0.30,
    'gentle_slope': 0.25,
    'infrastructure': 0.25,
    'river_proximity': 0.20
}

# 可視化設定
DISPLAY_TOP_N_ON_MAP = 3
MAP_COLORS = ['red', 'blue', 'green', 'purple', 'orange']
GRAPH_DPI = 150


# ============================================================
# HydroSiteSelectorV2 クラス
# ============================================================
class HydroSiteSelectorV2:
    """水力発電候補地選定クラス（改良版）"""
    
    def __init__(self, location_name):
        self.location_name = location_name
        self.center_lat = None
        self.center_lon = None
        self.boundary_coords = None
        self.boundary_polygon = None
        self.grid_points = []
        self.elevation_data = None
        self.river_data = []
        self.river_flow_estimates = {}
        self.candidates = {'water_sources': [], 'intakes': [], 'powerhouses': []}
        self.best_combinations = []
        self.area_km2 = 0
        self._status = {'stage': 'init', 'progress': 0, 'message': '初期化完了'}
        
        # V2 新規属性
        self.roads = []
        self.power_lines = []
        self.protected_areas = []
        self.existing_dams = []
        self.region_name = None
        self.precipitation = None
    
    def update_status(self, stage=None, progress=None, message=None):
        if stage:
            self._status['stage'] = stage
        if progress is not None:
            self._status['progress'] = progress
        if message:
            self._status['message'] = message
        print(f"STATUS: stage={self._status['stage']}, progress={self._status['progress']}%, msg={self._status['message']}")
    
    def get_status(self):
        return self._status.copy()
    
    # ============================================================
    # 座標・境界取得
    # ============================================================
    def get_location_coordinates(self):
        """地名から座標と境界を取得"""
        print(f"地域情報取得中: {self.location_name}")
        self.update_status(stage='geocode', progress=5, message='座標取得中')
        
        geolocator = Nominatim(user_agent="hydro_power_v2")
        
        try:
            location = geolocator.geocode(self.location_name, timeout=10)
            if not location:
                print(f"エラー: '{self.location_name}' の座標が見つかりません")
                return False
            
            self.center_lat = location.latitude
            self.center_lon = location.longitude
            print(f"✓ 中心座標: ({self.center_lat:.4f}, {self.center_lon:.4f})")
            
            # 地域名を抽出（降水量データ用）
            self._detect_region()
            
            time.sleep(1)
            
            location_with_geom = geolocator.geocode(
                self.location_name,
                geometry='geojson',
                timeout=10
            )
            
            if location_with_geom and hasattr(location_with_geom, 'raw'):
                geojson = location_with_geom.raw.get('geojson', {})
                geom_type = geojson.get('type', '')
                coords = geojson.get('coordinates', [])
                
                if geom_type == 'Polygon' and coords:
                    exterior = coords[0]
                    self.boundary_coords = [(lat, lon) for lon, lat in exterior]
                    self.boundary_polygon = Polygon([(lon, lat) for lat, lon in self.boundary_coords])
                    self.area_km2 = self._calculate_area()
                    print(f"✓ 行政区画境界取得: {len(self.boundary_coords)}点")
                    print(f"✓ 概算面積: {self.area_km2:.1f} km²")
                    
                elif geom_type == 'MultiPolygon' and coords:
                    all_coords = []
                    polygons = []
                    for polygon_coords in coords:
                        exterior = polygon_coords[0]
                        poly_points = [(lat, lon) for lon, lat in exterior]
                        all_coords.extend(poly_points)
                        polygons.append(Polygon([(lon, lat) for lat, lon in poly_points]))
                    
                    self.boundary_coords = all_coords
                    self.boundary_polygon = MultiPolygon(polygons)
                    self.area_km2 = self._calculate_area()
                    print(f"✓ 複合行政区画境界取得: {len(coords)}ポリゴン, 計{len(self.boundary_coords)}点")
                    print(f"✓ 概算面積: {self.area_km2:.1f} km²")
                else:
                    self._create_default_boundary()
            else:
                self._create_default_boundary()
            
            return True
            
        except Exception as e:
            print(f"座標取得エラー: {e}")
            return False
    
    def _detect_region(self):
        """地名から地域を検出して降水量を設定"""
        for region, precip in PRECIPITATION_BY_REGION.items():
            if region in self.location_name:
                self.region_name = region
                self.precipitation = precip
                print(f"✓ 地域検出: {region} (年間降水量: {precip}mm)")
                return
        
        # デフォルト値
        self.region_name = 'default'
        self.precipitation = PRECIPITATION_BY_REGION['default']
        print(f"⚠ 地域未検出 → デフォルト降水量を使用: {self.precipitation}mm")
    
    def _create_default_boundary(self, radius_km=5):
        """デフォルトの円形境界を作成"""
        print(f"  境界情報なし → 半径{radius_km}kmの探索範囲を設定")
        deg_per_km = 1 / 111
        n_points = 36
        self.boundary_coords = []
        
        for i in range(n_points):
            angle = 2 * np.pi * i / n_points
            lat = self.center_lat + radius_km * deg_per_km * np.cos(angle)
            lon = self.center_lon + radius_km * deg_per_km * np.sin(angle) / np.cos(np.radians(self.center_lat))
            self.boundary_coords.append((lat, lon))
        
        self.boundary_polygon = Polygon([(lon, lat) for lat, lon in self.boundary_coords])
        self.area_km2 = np.pi * radius_km ** 2
    
    def _calculate_area(self):
        if self.boundary_polygon:
            area_deg2 = self.boundary_polygon.area
            km_per_deg = 111
            return area_deg2 * (km_per_deg ** 2)
        return 0
    
    def is_point_in_boundary(self, lat, lon):
        if self.boundary_polygon:
            return self.boundary_polygon.contains(Point(lon, lat))
        return True
    
    # ============================================================
    # グリッド生成
    # ============================================================
    def generate_grid_points(self, grid_size=20):
        """グリッドポイント生成"""
        print(f"\nグリッドポイント生成中 ({grid_size}x{grid_size})...")
        self.update_status(stage='grid', progress=15, message='グリッド生成中')
        
        if self.boundary_coords:
            lats = [c[0] for c in self.boundary_coords]
            lons = [c[1] for c in self.boundary_coords]
            min_lat, max_lat = min(lats), max(lats)
            min_lon, max_lon = min(lons), max(lons)
        else:
            offset = 0.1
            min_lat, max_lat = self.center_lat - offset, self.center_lat + offset
            min_lon, max_lon = self.center_lon - offset, self.center_lon + offset
        
        lat_points = np.linspace(min_lat, max_lat, grid_size)
        lon_points = np.linspace(min_lon, max_lon, grid_size)
        
        self.grid_points = []
        for lat in lat_points:
            for lon in lon_points:
                if self.is_point_in_boundary(lat, lon):
                    self.grid_points.append((lat, lon))
        
        print(f"✓ {len(self.grid_points)}点生成 (境界内のみ)")
        return self.grid_points
    
    # ============================================================
    # 標高データ取得
    # ============================================================
    def fetch_elevation_data(self, batch_size=100):
        """標高データ取得"""
        print(f"\n標高データ取得中...")
        self.update_status(stage='elevation', progress=25, message='標高データ取得中')
        
        self.elevation_data = np.zeros(len(self.grid_points))
        
        for i in tqdm(range(0, len(self.grid_points), batch_size), desc="標高取得"):
            batch = self.grid_points[i:i+batch_size]
            locations = "|".join([f"{lat},{lon}" for lat, lon in batch])
            url = f"https://api.open-elevation.com/api/v1/lookup?locations={locations}"
            
            for attempt in range(ELEVATION_RETRY + 1):
                try:
                    response = requests.get(url, timeout=30)
                    if response.status_code == 200:
                        data = response.json()
                        for j, result in enumerate(data.get('results', [])):
                            self.elevation_data[i + j] = result.get('elevation', 0)
                        break
                except Exception as e:
                    if attempt == ELEVATION_RETRY:
                        print(f"\n標高取得失敗(バッチ{i//batch_size}): {e}")
                    time.sleep(1)
            
            time.sleep(0.2)
        
        valid_elevations = self.elevation_data[self.elevation_data != 0]
        if len(valid_elevations) > 0:
            print(f"✓ 標高データ取得完了: {len(valid_elevations)}点")
            print(f"  標高範囲: {valid_elevations.min():.1f}m ~ {valid_elevations.max():.1f}m")
        
        return self.elevation_data
    
    # ============================================================
    # 河川データ取得（V2改良版）
    # ============================================================
    def fetch_river_data(self):
        """河川データ取得"""
        print(f"\n河川データ取得中...")
        self.update_status(stage='fetch_rivers', progress=32, message='河川データ取得中')
        
        try:
            if self.boundary_coords:
                lats = [c[0] for c in self.boundary_coords]
                lons = [c[1] for c in self.boundary_coords]
                min_lat, max_lat = min(lats), max(lats)
                min_lon, max_lon = min(lons), max(lons)
            else:
                offset = 0.1
                min_lat, max_lat = self.center_lat - offset, self.center_lat + offset
                min_lon, max_lon = self.center_lon - offset, self.center_lon + offset
            
            query = f"""
            [out:json][timeout:{API_TIMEOUT}];
            (
              way["waterway"~"river|stream|canal"]({min_lat},{min_lon},{max_lat},{max_lon});
            );
            out body;
            >;
            out skel qt;
            """
            
            response = requests.post(
                "https://overpass-api.de/api/interpreter",
                data=query,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 200:
                data = response.json()
                elements = data.get('elements', [])
                
                nodes = {}
                ways = []
                
                for element in elements:
                    if element['type'] == 'node':
                        nodes[element['id']] = (element['lat'], element['lon'])
                    elif element['type'] == 'way':
                        ways.append(element)
                
                self.river_data = []
                
                for element in ways:
                    node_ids = element.get('nodes', [])
                    coords = []
                    for nid in node_ids:
                        if nid in nodes:
                            lat, lon = nodes[nid]
                            coords.append((lon, lat))
                    
                    if len(coords) >= 2:
                        try:
                            line = LineString(coords)
                            if self.boundary_polygon:
                                intersection = self.boundary_polygon.intersection(line)
                                if not intersection.is_empty:
                                    river_info = {
                                        'id': element.get('id'),
                                        'name': element.get('tags', {}).get('name', 'unnamed'),
                                        'type': element.get('tags', {}).get('waterway', 'river'),
                                        'geometry': line,
                                        'length_km': line.length * 111
                                    }
                                    self.river_data.append(river_info)
                        except:
                            continue
                
                print(f"✓ {len(self.river_data)}本の河川データを取得")
                
                # 河川タイプ別集計
                river_types = {}
                for river in self.river_data:
                    rtype = river['type']
                    river_types[rtype] = river_types.get(rtype, 0) + 1
                
                print(f"  河川タイプ内訳:")
                for rtype, count in river_types.items():
                    print(f"    {rtype}: {count}本")
                
                # V2: 集水域ベースの流量推定
                self._estimate_river_flows_v2()
                
                return True
            else:
                print(f"警告: 河川データの取得に失敗")
                return False
        except Exception as e:
            print(f"警告: 河川データ取得エラー - {e}")
            return False
    
    def _estimate_river_flows_v2(self):
        """V2: 集水域ベースの河川流量推定"""
        print(f"  河川流量を推定中（集水域ベース）...")
        
        # 河川タイプ別の基準流量 (m³/s)
        BASE_FLOWS = {
            'river': 5.0,    # 大河川
            'stream': 1.0,   # 小河川
            'canal': 2.0     # 用水路
        }
        
        for river in self.river_data:
            # 集水域面積の推定（河川長から概算）
            length_km = max(river['length_km'], 0.5)  # 最低0.5km
            
            # 河川タイプに基づく集水域係数
            river_type = river['type']
            if river_type == 'river':
                # 大河川は広い集水域
                catchment_area_km2 = 2.0 * (length_km ** 1.8)
            elif river_type == 'stream':
                # 小河川
                catchment_area_km2 = 1.0 * (length_km ** 1.6)
            else:
                # その他
                catchment_area_km2 = 0.5 * (length_km ** 1.5)
            
            catchment_area_km2 = max(2.0, min(catchment_area_km2, 2000.0))
            
            # 流出係数（平均標高から推定）
            avg_elevation = np.mean(self.elevation_data) if len(self.elevation_data) > 0 else 500
            if avg_elevation > 1000:
                runoff_coef = RUNOFF_COEFFICIENTS['mountain']
            elif avg_elevation > 300:
                runoff_coef = RUNOFF_COEFFICIENTS['hill']
            else:
                runoff_coef = RUNOFF_COEFFICIENTS['plain']
            
            # 流量計算
            # 方法1: 集水域ベース
            # Q = A(km²) × P(mm/年) × C / (365 × 24 × 3600)
            seconds_per_year = 365 * 24 * 3600
            flow_catchment = (catchment_area_km2 * 1e6) * (self.precipitation / 1000) * runoff_coef / seconds_per_year
            
            # 方法2: タイプベースの基準流量
            base_flow = BASE_FLOWS.get(river_type, 1.0)
            
            # 両方の平均を取る（安定した推定）
            estimated_flow = (flow_catchment + base_flow) / 2.0
            estimated_flow = max(0.5, min(estimated_flow, 100.0))
            
            river['catchment_area_km2'] = catchment_area_km2
            river['estimated_flow'] = estimated_flow
            self.river_flow_estimates[river['id']] = estimated_flow
        
        if self.river_data:
            avg_flow = np.mean(list(self.river_flow_estimates.values()))
            max_flow = max(self.river_flow_estimates.values())
            print(f"  ✓ 流量推定完了: 平均 {avg_flow:.2f} m³/s, 最大 {max_flow:.2f} m³/s")
    
    # ============================================================
    # 保護区域データ取得
    # ============================================================
    def fetch_protected_areas(self):
        """保護区域データを取得"""
        print(f"\n保護区域データ取得中...")
        self.update_status(stage='protected_areas', progress=35, message='保護区域データ取得中')
        
        try:
            if self.boundary_coords:
                lats = [c[0] for c in self.boundary_coords]
                lons = [c[1] for c in self.boundary_coords]
                min_lat, max_lat = min(lats), max(lats)
                min_lon, max_lon = min(lons), max(lons)
            else:
                return False
            
            query = f"""
            [out:json][timeout:{API_TIMEOUT}];
            (
              way["boundary"="national_park"]({min_lat},{min_lon},{max_lat},{max_lon});
              way["boundary"="protected_area"]({min_lat},{min_lon},{max_lat},{max_lon});
              relation["boundary"="national_park"]({min_lat},{min_lon},{max_lat},{max_lon});
              relation["boundary"="protected_area"]({min_lat},{min_lon},{max_lat},{max_lon});
            );
            out body;
            >;
            out skel qt;
            """
            
            response = requests.post(
                "https://overpass-api.de/api/interpreter",
                data=query,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 200:
                data = response.json()
                elements = data.get('elements', [])
                
                nodes = {}
                ways = []
                
                for element in elements:
                    if element['type'] == 'node':
                        nodes[element['id']] = (element['lat'], element['lon'])
                    elif element['type'] == 'way':
                        ways.append(element)
                
                self.protected_areas = []
                
                for element in ways:
                    node_ids = element.get('nodes', [])
                    coords = []
                    for nid in node_ids:
                        if nid in nodes:
                            lat, lon = nodes[nid]
                            coords.append((lon, lat))
                    
                    if len(coords) >= 3:
                        try:
                            poly = Polygon(coords)
                            if poly.is_valid:
                                self.protected_areas.append({
                                    'name': element.get('tags', {}).get('name', 'unnamed'),
                                    'geometry': poly
                                })
                        except:
                            continue
                
                print(f"✓ {len(self.protected_areas)}件の保護区域を取得")
                return True
            else:
                print(f"⚠ 保護区域データの取得に失敗")
                return False
        except Exception as e:
            print(f"⚠ 保護区域データ取得エラー - {e}")
            return False
    
    def is_in_protected_area(self, lat, lon):
        """指定座標が保護区域内かチェック"""
        if not self.protected_areas:
            return False
        point = Point(lon, lat)
        for area in self.protected_areas:
            if area['geometry'].contains(point):
                return True
        return False
    
    # ============================================================
    # インフラデータ取得
    # ============================================================
    def fetch_infrastructure_data(self):
        """道路・送電線データを取得"""
        print(f"\nインフラデータ取得中...")
        self.update_status(stage='infrastructure', progress=38, message='インフラデータ取得中')
        
        try:
            if self.boundary_coords:
                lats = [c[0] for c in self.boundary_coords]
                lons = [c[1] for c in self.boundary_coords]
                min_lat, max_lat = min(lats), max(lats)
                min_lon, max_lon = min(lons), max(lons)
            else:
                return False
            
            # 道路データ
            road_query = f"""
            [out:json][timeout:{API_TIMEOUT}];
            (
              way["highway"~"primary|secondary|tertiary"]({min_lat},{min_lon},{max_lat},{max_lon});
            );
            out body;
            >;
            out skel qt;
            """
            
            response = requests.post(
                "https://overpass-api.de/api/interpreter",
                data=road_query,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 200:
                data = response.json()
                elements = data.get('elements', [])
                
                nodes = {}
                for element in elements:
                    if element['type'] == 'node':
                        nodes[element['id']] = (element['lat'], element['lon'])
                
                self.roads = []
                for element in elements:
                    if element['type'] == 'way':
                        node_ids = element.get('nodes', [])
                        coords = [(nodes[nid][1], nodes[nid][0]) for nid in node_ids if nid in nodes]
                        if len(coords) >= 2:
                            try:
                                self.roads.append(LineString(coords))
                            except:
                                pass
                
                print(f"  ✓ 道路: {len(self.roads)}本")
            
            time.sleep(1)
            
            # 送電線データ
            power_query = f"""
            [out:json][timeout:{API_TIMEOUT}];
            (
              way["power"="line"]({min_lat},{min_lon},{max_lat},{max_lon});
            );
            out body;
            >;
            out skel qt;
            """
            
            response = requests.post(
                "https://overpass-api.de/api/interpreter",
                data=power_query,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 200:
                data = response.json()
                elements = data.get('elements', [])
                
                nodes = {}
                for element in elements:
                    if element['type'] == 'node':
                        nodes[element['id']] = (element['lat'], element['lon'])
                
                self.power_lines = []
                for element in elements:
                    if element['type'] == 'way':
                        node_ids = element.get('nodes', [])
                        coords = [(nodes[nid][1], nodes[nid][0]) for nid in node_ids if nid in nodes]
                        if len(coords) >= 2:
                            try:
                                self.power_lines.append(LineString(coords))
                            except:
                                pass
                
                print(f"  ✓ 送電線: {len(self.power_lines)}本")
            
            return True
        except Exception as e:
            print(f"⚠ インフラデータ取得エラー - {e}")
            return False
    
    def _calculate_infrastructure_score(self, lat, lon):
        """インフラへの近接性スコアを計算"""
        point = Point(lon, lat)
        
        # 道路への距離
        if self.roads:
            road_dist = min(point.distance(road) * 111 for road in self.roads)
        else:
            road_dist = 10.0
        
        # 送電線への距離
        if self.power_lines:
            power_dist = min(point.distance(line) * 111 for line in self.power_lines)
        else:
            power_dist = 20.0
        
        road_score = np.exp(-road_dist / 5.0)
        power_score = np.exp(-power_dist / 10.0)
        
        return 0.6 * road_score + 0.4 * power_score
    
    # ============================================================
    # 既存ダムデータ取得
    # ============================================================
    def fetch_existing_dams(self):
        """既存ダム・堰堤データを取得"""
        print(f"\n既存ダムデータ取得中...")
        
        try:
            if self.boundary_coords:
                lats = [c[0] for c in self.boundary_coords]
                lons = [c[1] for c in self.boundary_coords]
                min_lat, max_lat = min(lats), max(lats)
                min_lon, max_lon = min(lons), max(lons)
            else:
                return False
            
            query = f"""
            [out:json][timeout:{API_TIMEOUT}];
            (
              node["waterway"="dam"]({min_lat},{min_lon},{max_lat},{max_lon});
              way["waterway"="dam"]({min_lat},{min_lon},{max_lat},{max_lon});
              node["waterway"="weir"]({min_lat},{min_lon},{max_lat},{max_lon});
            );
            out center;
            """
            
            response = requests.post(
                "https://overpass-api.de/api/interpreter",
                data=query,
                timeout=API_TIMEOUT
            )
            
            if response.status_code == 200:
                data = response.json()
                elements = data.get('elements', [])
                
                self.existing_dams = []
                for element in elements:
                    lat = element.get('lat') or element.get('center', {}).get('lat')
                    lon = element.get('lon') or element.get('center', {}).get('lon')
                    if lat and lon:
                        self.existing_dams.append({
                            'lat': lat,
                            'lon': lon,
                            'name': element.get('tags', {}).get('name', 'unnamed')
                        })
                
                print(f"✓ {len(self.existing_dams)}件の既存ダム・堰堤を取得")
                return True
            else:
                return False
        except Exception as e:
            print(f"⚠ 既存ダムデータ取得エラー - {e}")
            return False
    
    def _calculate_water_rights_risk(self, lat, lon):
        """水利権競合リスクを評価"""
        if not self.existing_dams:
            return 1.0
        
        min_distance = min(
            geodesic((lat, lon), (dam['lat'], dam['lon'])).kilometers
            for dam in self.existing_dams
        )
        
        if min_distance < 1.0:
            return 0.2
        elif min_distance < 5.0:
            return 0.5
        else:
            return 1.0
    
    # ============================================================
    # 勾配計算
    # ============================================================
    def calculate_slope_optimized(self):
        """勾配計算"""
        n = len(self.grid_points)
        grid_size = int(np.sqrt(n))
        
        if grid_size ** 2 != n:
            grid_size = int(np.ceil(np.sqrt(n)))
            padded = np.pad(self.elevation_data, (0, grid_size**2 - n), mode='edge')
        else:
            padded = self.elevation_data
        
        elev_2d = padded.reshape(grid_size, grid_size)
        grad_y, grad_x = np.gradient(elev_2d)
        slope_2d = np.sqrt(grad_x**2 + grad_y**2)
        slope = slope_2d.flatten()[:n]
        
        return slope
    
    def _get_river_proximity_score(self, lat, lon):
        """河川への近接性スコアを計算"""
        if not self.river_data:
            return 0.5
        
        point = Point(lon, lat)
        min_distance = float('inf')
        
        for river in self.river_data:
            distance = point.distance(river['geometry']) * 111  # km
            if distance < min_distance:
                min_distance = distance
        
        # 距離に基づくスコア（1km以内が最高）
        return np.exp(-min_distance / 2.0)
    
    def get_river_flow_for_point(self, lat, lon):
        """指定地点に最も近い河川の流量を取得"""
        if not self.river_data:
            return 2.0  # デフォルト流量を増加
        
        point = Point(lon, lat)
        min_distance = float('inf')
        closest_river_id = None
        closest_river = None
        
        for river in self.river_data:
            distance = point.distance(river['geometry'])
            if distance < min_distance:
                min_distance = distance
                closest_river_id = river['id']
                closest_river = river
        
        distance_km = min_distance * 111
        
        # 距離に応じた流量取得
        if distance_km > 10:
            # 遠すぎる場合は小さい固定値
            return 0.5
        
        base_flow = self.river_flow_estimates.get(closest_river_id, 2.0)
        
        # 距離減衰を緩和（3km以内はほぼ減衰なし）
        if distance_km <= 1.0:
            decay_factor = 1.0
        elif distance_km <= 3.0:
            decay_factor = 0.9
        else:
            decay_factor = np.exp(-(distance_km - 3.0) / 7.0)
        
        return base_flow * decay_factor
    
    # ============================================================
    # 候補地選定（V2改良版）
    # ============================================================
    def find_water_sources(self, top_n=50):
        """水源候補選定（V2）"""
        print(f"\n水源候補地選定中 (上位{top_n}箇所)...")
        self.update_status(stage='water_source', progress=45, message='水源候補選定中')
        
        slope = self.calculate_slope_optimized()
        
        elev_norm = (self.elevation_data - self.elevation_data.min()) / \
                    max(1e-6, (self.elevation_data.max() - self.elevation_data.min()))
        slope_norm = (slope - slope.min()) / max(1e-6, (slope.max() - slope.min()))
        
        candidates_with_scores = []
        
        for idx, (lat, lon) in enumerate(self.grid_points):
            # 保護区域チェック（完全除外）
            if self.is_in_protected_area(lat, lon):
                continue
            
            if not self.is_point_in_boundary(lat, lon):
                continue
            
            # 各スコア計算
            elevation_score = elev_norm[idx]
            river_proximity = self._get_river_proximity_score(lat, lon)
            flow = self.get_river_flow_for_point(lat, lon)
            flow_score = min(1.0, flow / 10.0)
            infra_score = self._calculate_infrastructure_score(lat, lon)
            stability_score = 1.0 - min(1.0, slope_norm[idx])
            
            # 水利権リスク
            water_rights = self._calculate_water_rights_risk(lat, lon)
            
            # 総合スコア
            total_score = (
                WATER_SOURCE_WEIGHTS_V2['elevation'] * elevation_score +
                WATER_SOURCE_WEIGHTS_V2['river_proximity'] * river_proximity +
                WATER_SOURCE_WEIGHTS_V2['flow'] * flow_score +
                WATER_SOURCE_WEIGHTS_V2['infrastructure'] * infra_score +
                WATER_SOURCE_WEIGHTS_V2['stability'] * stability_score
            ) * water_rights
            
            candidates_with_scores.append({
                'idx': idx,
                'lat': lat,
                'lon': lon,
                'elevation': float(self.elevation_data[idx]),
                'score': total_score,
                'estimated_flow': flow,
                'river_proximity': river_proximity,
                'type': 'water_source'
            })
        
        # スコアでソート
        candidates_with_scores.sort(key=lambda x: x['score'], reverse=True)
        self.candidates['water_sources'] = candidates_with_scores[:top_n]
        
        if self.candidates['water_sources']:
            avg_elev = np.mean([c['elevation'] for c in self.candidates['water_sources']])
            avg_flow = np.mean([c['estimated_flow'] for c in self.candidates['water_sources']])
            print(f"✓ {len(self.candidates['water_sources'])}箇所選定完了")
            print(f"  平均標高: {avg_elev:.1f}m, 平均推定流量: {avg_flow:.2f}m³/s")
        
        return self.candidates['water_sources']
    
    def find_intakes(self, top_n=50):
        """取水口候補選定（V2）"""
        print(f"\n取水口候補地選定中 (上位{top_n}箇所)...")
        self.update_status(stage='intake', progress=55, message='取水口候補選定中')
        
        slope = self.calculate_slope_optimized()
        
        elev_norm = (self.elevation_data - self.elevation_data.min()) / \
                    max(1e-6, (self.elevation_data.max() - self.elevation_data.min()))
        slope_norm = (slope - slope.min()) / max(1e-6, (slope.max() - slope.min()))
        
        candidates_with_scores = []
        
        for idx, (lat, lon) in enumerate(self.grid_points):
            if self.is_in_protected_area(lat, lon):
                continue
            
            if not self.is_point_in_boundary(lat, lon):
                continue
            
            # 河川近接性（取水口は最重要）
            river_proximity = self._get_river_proximity_score(lat, lon)
            
            # 中間標高
            middle_score = 1 - 4 * np.abs(elev_norm[idx] - 0.5)**2
            middle_score = max(0, middle_score)
            
            # 緩勾配
            gentle_slope = 1 - slope_norm[idx]
            
            # インフラ
            infra_score = self._calculate_infrastructure_score(lat, lon)
            
            total_score = (
                INTAKE_WEIGHTS_V2['river_proximity'] * river_proximity +
                INTAKE_WEIGHTS_V2['middle_elevation'] * middle_score +
                INTAKE_WEIGHTS_V2['gentle_slope'] * gentle_slope +
                INTAKE_WEIGHTS_V2['infrastructure'] * infra_score
            )
            
            candidates_with_scores.append({
                'idx': idx,
                'lat': lat,
                'lon': lon,
                'elevation': float(self.elevation_data[idx]),
                'score': total_score,
                'river_flow': self.get_river_flow_for_point(lat, lon),
                'river_proximity': river_proximity,
                'type': 'intake'
            })
        
        candidates_with_scores.sort(key=lambda x: x['score'], reverse=True)
        self.candidates['intakes'] = candidates_with_scores[:top_n]
        
        if self.candidates['intakes']:
            avg_elev = np.mean([c['elevation'] for c in self.candidates['intakes']])
            print(f"✓ {len(self.candidates['intakes'])}箇所選定完了")
            print(f"  平均標高: {avg_elev:.1f}m")
        
        return self.candidates['intakes']
    
    def find_powerhouses(self, top_n=50):
        """発電所候補選定（V2）"""
        print(f"\n発電所候補地選定中 (上位{top_n}箇所)...")
        self.update_status(stage='powerhouse', progress=65, message='発電所候補選定中')
        
        slope = self.calculate_slope_optimized()
        
        elev_norm = (self.elevation_data - self.elevation_data.min()) / \
                    max(1e-6, (self.elevation_data.max() - self.elevation_data.min()))
        slope_norm = (slope - slope.min()) / max(1e-6, (slope.max() - slope.min()))
        
        candidates_with_scores = []
        
        for idx, (lat, lon) in enumerate(self.grid_points):
            if self.is_in_protected_area(lat, lon):
                continue
            
            if not self.is_point_in_boundary(lat, lon):
                continue
            
            # 低標高
            low_elev = 1 - elev_norm[idx]
            
            # 緩勾配
            gentle_slope = 1 - slope_norm[idx]
            
            # インフラ
            infra_score = self._calculate_infrastructure_score(lat, lon)
            
            # 河川近接性
            river_proximity = self._get_river_proximity_score(lat, lon)
            
            total_score = (
                POWERHOUSE_WEIGHTS_V2['low_elevation'] * low_elev +
                POWERHOUSE_WEIGHTS_V2['gentle_slope'] * gentle_slope +
                POWERHOUSE_WEIGHTS_V2['infrastructure'] * infra_score +
                POWERHOUSE_WEIGHTS_V2['river_proximity'] * river_proximity
            )
            
            candidates_with_scores.append({
                'idx': idx,
                'lat': lat,
                'lon': lon,
                'elevation': float(self.elevation_data[idx]),
                'score': total_score,
                'type': 'powerhouse'
            })
        
        candidates_with_scores.sort(key=lambda x: x['score'], reverse=True)
        self.candidates['powerhouses'] = candidates_with_scores[:top_n]
        
        if self.candidates['powerhouses']:
            avg_elev = np.mean([c['elevation'] for c in self.candidates['powerhouses']])
            print(f"✓ {len(self.candidates['powerhouses'])}箇所選定完了")
            print(f"  平均標高: {avg_elev:.1f}m")
        
        return self.candidates['powerhouses']
    
    # ============================================================
    # 最適組合せ探索
    # ============================================================
    def find_best_combinations(self, top_n=20):
        """最適組合せ探索"""
        print(f"\n最適組合せ探索中...")
        self.update_status(stage='combinations', progress=75, message='組合せ探索中')
        
        water_sources = self.candidates['water_sources']
        intakes = self.candidates['intakes']
        powerhouses = self.candidates['powerhouses']
        
        total_combinations = len(water_sources) * len(intakes) * len(powerhouses)
        print(f"  総組合せ数: {total_combinations:,}")
        
        all_combinations = []
        
        for ws in tqdm(water_sources, desc="組合せ評価"):
            for intake in intakes:
                if intake['elevation'] >= ws['elevation']:
                    continue
                
                for ph in powerhouses:
                    if ph['elevation'] >= intake['elevation']:
                        continue
                    
                    head = intake['elevation'] - ph['elevation']
                    
                    if head < 10:
                        continue
                    
                    ws_intake_dist = geodesic(
                        (ws['lat'], ws['lon']),
                        (intake['lat'], intake['lon'])
                    ).kilometers
                    
                    intake_ph_dist = geodesic(
                        (intake['lat'], intake['lon']),
                        (ph['lat'], ph['lon'])
                    ).kilometers
                    
                    total_dist = ws_intake_dist + intake_ph_dist
                    
                    flow = intake.get('river_flow', ws.get('estimated_flow', 1.0))
                    
                    # 水路損失
                    flow_loss_factor = np.exp(-total_dist / 15)
                    effective_flow = flow * flow_loss_factor
                    
                    # 発電量計算
                    power_kw = TURBINE_EFFICIENCY * effective_flow * GRAVITY * head
                    
                    # 距離ペナルティ
                    distance_penalty = np.exp(-total_dist / 20)
                    score = power_kw * distance_penalty
                    
                    all_combinations.append({
                        'water_source': ws,
                        'intake': intake,
                        'powerhouse': ph,
                        'head': head,
                        'flow': effective_flow,
                        'power_kw': power_kw,
                        'total_distance': total_dist,
                        'score': score
                    })
        
        all_combinations.sort(key=lambda x: x['power_kw'], reverse=True)
        self.best_combinations = all_combinations[:top_n]
        
        print(f"✓ 上位{len(self.best_combinations)}組選定完了")
        
        if self.best_combinations:
            best = self.best_combinations[0]
            print(f"\n[最優良候補]")
            print(f"  発電量: {best['power_kw']:.1f} kW")
            print(f"  有効落差: {best['head']:.1f} m")
            print(f"  有効流量: {best['flow']:.2f} m³/s")
            print(f"  総水路長: {best['total_distance']:.2f} km")
        
        return self.best_combinations
    
    # ============================================================
    # 可視化
    # ============================================================
    def visualize_results(self):
        """結果の可視化"""
        print(f"\n可視化処理中...")
        self.update_status(stage='visualize', progress=90, message='可視化処理中')
        
        # 地図作成
        m = folium.Map(
            location=[self.center_lat, self.center_lon],
            zoom_start=10,
            tiles='OpenStreetMap'
        )
        
        # 境界ポリゴン表示
        if self.boundary_coords:
            folium.Polygon(
                locations=self.boundary_coords,
                color='gray',
                weight=2,
                fill=True,
                fill_opacity=0.1
            ).add_to(m)
        
        # 上位組合せを地図に追加
        for i, combo in enumerate(self.best_combinations[:DISPLAY_TOP_N_ON_MAP]):
            color = MAP_COLORS[i % len(MAP_COLORS)]
            ws = combo['water_source']
            intake = combo['intake']
            ph = combo['powerhouse']
            
            # 水源マーカー
            folium.Marker(
                [ws['lat'], ws['lon']],
                popup=f"水源 #{i+1}<br>標高: {ws['elevation']:.0f}m<br>流量: {ws.get('estimated_flow', 0):.2f} m³/s",
                tooltip=f"水源 #{i+1}",
                icon=folium.Icon(color=color, icon='tint', prefix='fa')
            ).add_to(m)
            
            # 取水口マーカー
            folium.Marker(
                [intake['lat'], intake['lon']],
                popup=f"取水口 #{i+1}<br>標高: {intake['elevation']:.0f}m",
                tooltip=f"取水口 #{i+1}",
                icon=folium.Icon(color=color, icon='arrow-down', prefix='fa')
            ).add_to(m)
            
            # 発電所マーカー
            folium.Marker(
                [ph['lat'], ph['lon']],
                popup=f"発電所 #{i+1}<br>標高: {ph['elevation']:.0f}m<br>発電量: {combo['power_kw']:.0f} kW",
                tooltip=f"発電所 #{i+1}",
                icon=folium.Icon(color=color, icon='bolt', prefix='fa')
            ).add_to(m)
            
            # 水路ライン
            folium.PolyLine(
                [[ws['lat'], ws['lon']], [intake['lat'], intake['lon']], [ph['lat'], ph['lon']]],
                color=color,
                weight=3,
                opacity=0.7
            ).add_to(m)
        
        # 凡例
        legend_html = '''
        <div style="position: fixed; top: 10px; right: 10px; 
                    border:2px solid grey; z-index:9999; 
                    background-color:white;
                    padding: 10px; border-radius: 5px;
                    font-size: 14px;">
            <div style="font-weight: bold; margin-bottom: 8px;">凡例</div>
        '''
        for i, color in enumerate(MAP_COLORS[:DISPLAY_TOP_N_ON_MAP]):
            if i < len(self.best_combinations):
                power = self.best_combinations[i]['power_kw']
                legend_html += f'<div>● #{i+1}: {power:.0f} kW</div>'
        legend_html += '</div>'
        m.get_root().html.add_child(folium.Element(legend_html))
        
        print(f"✓ 地図作成完了")
        
        # グラフ作成
        fig_dict = {}
        
        # 1. 標高分布
        fig1, ax1 = plt.subplots(figsize=(10, 6))
        ax1.hist(self.elevation_data, bins=50, edgecolor='black', alpha=0.7)
        ax1.set_xlabel('Elevation (m)')
        ax1.set_ylabel('Frequency')
        ax1.set_title(f'Elevation Distribution - {self.location_name}')
        ax1.grid(True, alpha=0.3)
        fig_dict['elevation'] = fig1
        
        # 2. 発電量比較
        if self.best_combinations:
            fig2, ax2 = plt.subplots(figsize=(10, 6))
            powers = [c['power_kw'] for c in self.best_combinations[:10]]
            ranks = list(range(1, len(powers) + 1))
            ax2.barh(ranks, powers, color='steelblue', edgecolor='black')
            ax2.set_xlabel('Power Output (kW)')
            ax2.set_ylabel('Rank')
            ax2.set_title(f'Top 10 Power Output - {self.location_name}')
            ax2.invert_yaxis()
            ax2.grid(True, alpha=0.3, axis='x')
            fig_dict['power'] = fig2
        
        # 3. 落差比較
        if self.best_combinations:
            fig3, ax3 = plt.subplots(figsize=(10, 6))
            heads = [c['head'] for c in self.best_combinations[:10]]
            ranks = list(range(1, len(heads) + 1))
            ax3.bar(ranks, heads, color='forestgreen', edgecolor='black')
            ax3.set_xlabel('Rank')
            ax3.set_ylabel('Effective Head (m)')
            ax3.set_title(f'Effective Head - {self.location_name}')
            ax3.grid(True, alpha=0.3, axis='y')
            fig_dict['head'] = fig3
        
        # 4. 高低差プロファイル
        if self.best_combinations:
            fig4, ax4 = plt.subplots(figsize=(12, 6))
            for i, combo in enumerate(self.best_combinations[:3]):
                ws = combo['water_source']
                intake = combo['intake']
                ph = combo['powerhouse']
                color = MAP_COLORS[i % len(MAP_COLORS)]
                positions = [0, 1, 2]
                elevations = [ws['elevation'], intake['elevation'], ph['elevation']]
                ax4.plot(positions, elevations, 'o-', color=color, linewidth=2,
                        markersize=10, label=f'#{i+1}: {combo["power_kw"]:.0f}kW')
            ax4.set_xticks([0, 1, 2])
            ax4.set_xticklabels(['Water Source', 'Intake', 'Powerhouse'])
            ax4.set_ylabel('Elevation (m)')
            ax4.set_title(f'Facility Elevation Profile - {self.location_name}')
            ax4.legend()
            ax4.grid(True, alpha=0.3)
            fig_dict['profile'] = fig4
        
        print(f"✓ グラフ作成完了")
        plt.close('all')
        
        return m, fig_dict
    
    # ============================================================
    # メイン実行
    # ============================================================
    def run_analysis(self, grid_size=None, top_n=None, candidates_per_type=None):
        """分析実行"""
        print(f"\n{'='*60}")
        print(f"水力発電候補地選定システム V2")
        print(f"{'='*60}\n")
        self.update_status(stage='start', progress=1, message='分析開始')
        
        if not self.get_location_coordinates():
            return None, None
        
        # 自動パラメータ計算
        if grid_size is None:
            total_points = max(400, min(10000, int(self.area_km2 / 15)))
            grid_size = int(np.sqrt(total_points))
            print(f"\n[AUTO] グリッドサイズ: {grid_size}x{grid_size}")
        
        if candidates_per_type is None:
            total_grid = grid_size ** 2
            candidates_per_type = max(20, min(80, int(total_grid * 0.05)))
            print(f"[AUTO] 候補数/種類: {candidates_per_type}")
        
        if top_n is None:
            total_comb = candidates_per_type ** 3
            if total_comb < 10000:
                top_n = 10
            elif total_comb < 50000:
                top_n = 20
            else:
                top_n = 30
            print(f"[AUTO] 出力数: 上位{top_n}組\n")
        
        # 各ステップ実行
        self.generate_grid_points(grid_size=grid_size)
        self.fetch_elevation_data(batch_size=ELEVATION_BATCH_SIZE)
        self.fetch_river_data()
        self.fetch_protected_areas()
        self.fetch_infrastructure_data()
        self.fetch_existing_dams()
        self.find_water_sources(top_n=candidates_per_type)
        self.find_intakes(top_n=candidates_per_type)
        self.find_powerhouses(top_n=candidates_per_type)
        self.find_best_combinations(top_n=top_n)
        map_obj, fig = self.visualize_results()
        
        print(f"\n{'='*60}")
        print(f"分析完了!")
        print(f"{'='*60}\n")
        self.update_status(stage='done', progress=100, message='分析完了')
        
        return map_obj, fig
    # ============================================================
    # 結果保存
    # ============================================================
    def save_results(self, map_obj, fig_dict, output_dir=None):
        """結果をファイルに保存"""
        print(f"\n{'='*60}")
        print(f"結果を保存中...")
        print(f"{'='*60}")
        
        timestamp = datetime.now().strftime("%Y%m%d%H%M")
        
        if output_dir is None:
            # デフォルトの保存先
            is_colab = 'google.colab' in sys.modules
            if is_colab:
                deta_base = "/content/deta"
            else:
                deta_base = os.path.join(os.path.dirname(__file__), "deta")
            output_dir = os.path.join(deta_base, timestamp)
        
        os.makedirs(output_dir, exist_ok=True)
        print(f"\n保存先: {output_dir}\n")
        
        saved_files = []
        
        # 1. HTMLマップ保存
        if map_obj:
            map_filename = f"hydro_map_{self.location_name}_{timestamp}.html"
            map_path = os.path.join(output_dir, map_filename)
            map_obj.save(map_path)
            print(f"✓ 地図保存: {map_filename}")
            saved_files.append(map_path)
        
        # 2. CSVデータ保存
        if self.best_combinations:
            csv_data = []
            for i, combo in enumerate(self.best_combinations, 1):
                ws = combo['water_source']
                intake = combo['intake']
                ph = combo['powerhouse']
                
                ws_intake_dist = geodesic((ws['lat'], ws['lon']), (intake['lat'], intake['lon'])).kilometers
                intake_ph_dist = geodesic((intake['lat'], intake['lon']), (ph['lat'], ph['lon'])).kilometers
                
                csv_data.append({
                    'Rank': i,
                    'Power_kW': combo['power_kw'],
                    'Effective_Head_m': combo['head'],
                    'Flow_m3s': combo['flow'],
                    'WaterSource_Lat': ws['lat'],
                    'WaterSource_Lon': ws['lon'],
                    'WaterSource_Elevation_m': ws['elevation'],
                    'Intake_Lat': intake['lat'],
                    'Intake_Lon': intake['lon'],
                    'Intake_Elevation_m': intake['elevation'],
                    'Powerhouse_Lat': ph['lat'],
                    'Powerhouse_Lon': ph['lon'],
                    'Powerhouse_Elevation_m': ph['elevation'],
                    'WS_Intake_Distance_km': ws_intake_dist,
                    'Intake_PH_Distance_km': intake_ph_dist,
                    'Total_Distance_km': ws_intake_dist + intake_ph_dist
                })
            
            df = pd.DataFrame(csv_data)
            csv_filename = f"hydro_sites_{self.location_name}_{timestamp}.csv"
            csv_path = os.path.join(output_dir, csv_filename)
            df.to_csv(csv_path, index=False, encoding='utf-8-sig')
            print(f"✓ CSV保存: {csv_filename} ({len(df)}行)")
            saved_files.append(csv_path)
        
        # 3. グラフ保存
        if fig_dict:
            graph_names = {
                'elevation': '1_Elevation_Distribution',
                'power': '2_Power_Output_Comparison',
                'head': '3_Effective_Head_Comparison',
                'profile': '4_Facility_Elevation_Profile'
            }
            
            for key, name in graph_names.items():
                if key in fig_dict:
                    png_filename = f"{name}_{self.location_name}_{timestamp}.png"
                    png_path = os.path.join(output_dir, png_filename)
                    fig_dict[key].savefig(png_path, dpi=GRAPH_DPI, bbox_inches='tight')
                    print(f"✓ グラフ保存: {png_filename}")
                    saved_files.append(png_path)
        
        # 4. サマリー保存
        summary_filename = f"summary_{self.location_name}_{timestamp}.txt"
        summary_path = os.path.join(output_dir, summary_filename)
        
        summary_lines = [
            "="*70,
            "水力発電候補地選定システム V2 - 結果サマリー",
            "="*70,
            "",
            f"地域名: {self.location_name}",
            f"日時: {datetime.now().strftime('%Y年%m月%d日 %H:%M:%S')}",
            f"使用システム: HydroSiteSelectorV2",
            "",
            "[基本情報]",
            f"探索面積: {self.area_km2:.1f} km²",
            f"グリッドポイント数: {len(self.grid_points)}",
            f"検出河川数: {len(self.river_data)}",
            f"標高範囲: {self.elevation_data.min():.1f}m ~ {self.elevation_data.max():.1f}m",
            f"年間降水量: {self.precipitation}mm ({self.region_name})",
            "",
            "[追加データ]",
            f"道路データ: {len(self.roads)}本",
            f"送電線データ: {len(self.power_lines)}本",
            f"保護区域: {len(self.protected_areas)}件",
            f"既存ダム・堰堤: {len(self.existing_dams)}件",
            "",
            "[候補地数]",
            f"水源候補: {len(self.candidates['water_sources'])}箇所",
            f"取水口候補: {len(self.candidates['intakes'])}箇所",
            f"発電所候補: {len(self.candidates['powerhouses'])}箇所",
            "",
            "[上位10組の発電量]"
        ]
        
        for i, combo in enumerate(self.best_combinations[:10], 1):
            summary_lines.append(
                f"#{i:2d}: {combo['power_kw']:7.1f} kW (落差: {combo['head']:6.1f}m, 流量: {combo['flow']:.2f}m³/s)"
            )
        
        with open(summary_path, 'w', encoding='utf-8-sig') as f:
            f.write('\n'.join(summary_lines))
        
        print(f"✓ サマリー保存: {summary_filename}")
        saved_files.append(summary_path)
        
        print(f"\n{'='*60}")
        print(f"保存完了! ({len(saved_files)}ファイル)")
        print(f"{'='*60}\n")
        
        return output_dir, saved_files


# ============================================================
# テスト用関数
# ============================================================
def test_hydro_selector_v2(location_name="松本市", save=True):
    """V2システムのテスト"""
    print(f"Testing HydroSiteSelectorV2 for: {location_name}")
    
    selector = HydroSiteSelectorV2(location_name)
    map_result, fig_result = selector.run_analysis(
        grid_size=20,
        candidates_per_type=20,
        top_n=10
    )
    
    if selector.best_combinations:
        print("\n" + "="*60)
        print("Top 5 Combinations:")
        print("="*60)
        for i, combo in enumerate(selector.best_combinations[:5], start=1):
            print(f"#{i}: Power={combo['power_kw']:.1f} kW, Head={combo['head']:.1f} m, Flow={combo['flow']:.2f} m³/s")
        
        if save:
            selector.save_results(map_result, fig_result)
    
    return selector, map_result, fig_result


if __name__ == "__main__":
    selector, m, f = test_hydro_selector_v2("松本市", save=True)
