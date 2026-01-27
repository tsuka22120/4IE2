# 📊 使用データソース一覧

本システムで使用しているデータとその情報源、用途を以下にまとめます。

| データ種別                | 情報源                             | URL/出典                            | 用途                             | 信頼度 |
| ------------------------- | ---------------------------------- | ----------------------------------- | -------------------------------- | ------ |
| **座標・境界**            | Nominatim API (OpenStreetMap)      | https://nominatim.openstreetmap.org | 地名から座標・行政区画境界を取得 | 高     |
| **標高**                  | Open-Elevation API                 | https://open-elevation.com          | 各地点の標高データを取得         | 中〜高 |
| **河川**                  | Overpass API (OpenStreetMap)       | https://overpass-api.de             | 河川の位置・形状・名称を取得     | 高     |
| **道路**                  | Overpass API (OpenStreetMap)       | https://overpass-api.de             | 主要道路（国道・県道等）を取得   | 高     |
| **送電線**                | Overpass API (OpenStreetMap)       | https://overpass-api.de             | 送電線の位置を取得               | 中     |
| **保護区域**              | Overpass API (OpenStreetMap)       | https://overpass-api.de             | 国立公園・保護区を取得           | 中     |
| **既存ダム**              | Overpass API (OpenStreetMap)       | https://overpass-api.de             | ダム・堰堤の位置を取得           | 中     |
| **年間降水量**            | 気象庁統計データ                   | 都道府県別の平年値を使用            | 河川流量の推定に使用             | 高     |
| **河川流量（実測）**      | 水文水質データベース（国土交通省） | http://www1.river.go.jp             | 主要河川の実測流量データ         | 最高   |
| **流域メッシュ**          | 国土数値情報（国土交通省）         | https://nlftp.mlit.go.jp/ksj/       | 集水域面積の算出に使用           | 高     |
| **DEM（数値標高モデル）** | ローカルファイル（merge.tif）      | JAXA ALOS等から取得可能             | 集水域解析のフォールバック       | 高     |

## 流量データの優先度

```
1. 水文水質データベース（実測値）→ 信頼度: 1.0
2. 国土数値情報 流域メッシュ    → 信頼度: 0.8
3. DEM解析による集水域計算     → 信頼度: 0.6
4. 河川長からの推定（従来方式） → 信頼度: 0.3
```

---
