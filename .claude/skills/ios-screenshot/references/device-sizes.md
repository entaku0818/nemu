# App Store スクリーンショット デバイスサイズ一覧

## 必須サイズ（2026年2月時点）

App Store Connect では、以下のデバイスサイズのスクリーンショットが必須です。

### iPhone

| デバイス | サイズ (px) | 対応機種 | シミュレーター名 |
|---------|------------|---------|----------------|
| 6.9" Display | 1320 x 2868 | iPhone 16 Pro Max | iPhone 16 Pro Max |
| 6.7" Display | 1290 x 2796 | iPhone 15 Plus, 15 Pro Max, 14 Plus, 14 Pro Max | iPhone 15 Plus |
| 6.5" Display | 1242 x 2688 | iPhone 11 Pro Max, XS Max | iPhone 11 Pro Max |
| 5.5" Display | 1242 x 2208 | iPhone 8 Plus, 7 Plus, 6s Plus | iPhone 8 Plus |

**注意**:
- **6.9" と 6.7" のどちらか1つは必須**
- **5.5" は互換性のため推奨**（古いiOSバージョンをサポートする場合）

### iPad

| デバイス | サイズ (px) | 対応機種 | シミュレーター名 |
|---------|------------|---------|----------------|
| 13" Display | 2048 x 2732 | iPad Pro 13" (M4) | iPad Pro 13-inch (M4) |
| 12.9" Display | 2048 x 2732 | iPad Pro 12.9" (第3-6世代) | iPad Pro (12.9-inch) (6th generation) |

**注意**:
- **ユニバーサルアプリの場合は必須**
- iPhone専用アプリの場合は不要

## 推奨アップロード構成

### 最小構成（iPhone専用アプリ）

```
fastlane/screenshots/
├── ja-JP/
│   ├── iPhone 16 Pro Max/
│   │   ├── 01-screenshot.png (1320 x 2868)
│   │   ├── 02-screenshot.png
│   │   └── 03-screenshot.png
│   └── iPhone 8 Plus/
│       ├── 01-screenshot.png (1242 x 2208)
│       ├── 02-screenshot.png
│       └── 03-screenshot.png
└── en-US/
    ├── iPhone 16 Pro Max/
    └── iPhone 8 Plus/
```

### 完全構成（ユニバーサルアプリ）

```
fastlane/screenshots/
├── ja-JP/
│   ├── iPhone 16 Pro Max/
│   ├── iPhone 15 Plus/
│   ├── iPhone 8 Plus/
│   └── iPad Pro (13-inch)/
└── en-US/
    ├── iPhone 16 Pro Max/
    ├── iPhone 15 Plus/
    ├── iPhone 8 Plus/
    └── iPad Pro (13-inch)/
```

## Snapfile 設定例

### 最小構成

```ruby
devices([
  "iPhone 16 Pro Max",
  "iPhone 8 Plus"
])

languages([
  "ja-JP",
  "en-US"
])
```

### 推奨構成

```ruby
devices([
  "iPhone 16 Pro Max",  # 最新の大型iPhone
  "iPhone 15 Plus",     # 6.7インチディスプレイ
  "iPhone 8 Plus",      # 互換性のため
  "iPad Pro (13-inch) (M4)"  # ユニバーサルアプリの場合
])

languages([
  "ja-JP",
  "en-US"
])
```

## デバイスサイズの自動スケーリング

App Store Connect は、以下のルールで自動的にスクリーンショットをスケーリングします：

### iPhone の場合

アップロードしたサイズに基づいて、他のサイズに自動適用：

- **6.9" をアップロード** → 6.7", 6.5", 6.1" に自動適用
- **5.5" をアップロード** → 5.8", 5.5", 4.7", 4" に自動適用

**推奨**: 6.9" と 5.5" の両方をアップロードすると、すべてのiPhoneデバイスでベストな表示

### iPad の場合

- **12.9" または 13" をアップロード** → すべてのiPadサイズに自動適用

## シミュレーター起動コマンド

```bash
# iPhone 16 Pro Max
xcrun simctl boot "iPhone 16 Pro Max"
open -a Simulator

# iPhone 15 Plus
xcrun simctl boot "iPhone 15 Plus"
open -a Simulator

# iPhone 8 Plus
xcrun simctl boot "iPhone 8 Plus"
open -a Simulator

# iPad Pro 13"
xcrun simctl boot "iPad Pro (13-inch) (M4)"
open -a Simulator
```

## スクリーンショット撮影時の設定

### シミュレーターの表示設定

```
Window > Physical Size  # 実際のピクセルサイズで表示（推奨）
Window > Pixel Accurate # 正確なピクセル表示
```

### ステータスバーのカスタマイズ

```bash
# 時刻を9:41に、バッテリーを100%に設定
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --cellularMode active \
  --cellularBars 4 \
  --wifiBars 3
```

## App Preview 動画サイズ

App Preview（動画プレビュー）の解像度要件：

| デバイス | 解像度 | アスペクト比 |
|---------|--------|------------|
| iPhone 16 Pro Max | 1320 x 2868 | 9:19.5 |
| iPhone 15 Plus | 1290 x 2796 | 9:19.5 |
| iPhone 8 Plus | 1920 x 1080 | 16:9 |
| iPad Pro 13" | 1200 x 1600 | 3:4 |

**要件**:
- 形式: H.264 または HEVC (.mp4 または .mov)
- 長さ: 15〜30秒
- ファイルサイズ: 500MB以下
- フレームレート: 最大30fps

## 歴史的な変遷（参考）

| 発売年 | デバイス | サイズ |
|-------|---------|--------|
| 2024 | iPhone 16 Pro Max | 1320 x 2868 |
| 2023 | iPhone 15 Pro Max | 1290 x 2796 |
| 2022 | iPhone 14 Pro Max | 1290 x 2796 |
| 2021 | iPhone 13 Pro Max | 1284 x 2778 |
| 2020 | iPhone 12 Pro Max | 1284 x 2778 |
| 2019 | iPhone 11 Pro Max | 1242 x 2688 |
| 2017 | iPhone X | 1125 x 2436 |
| 2014 | iPhone 6 Plus | 1242 x 2208 |

## よくある質問

### Q: 全てのサイズを用意する必要がありますか？

A: いいえ。必須は以下のみ：
- iPhone: 6.9" または 6.7"（どちらか1つ）
- iPad: 12.9" または 13"（ユニバーサルアプリの場合）

ただし、5.5"も追加すると、古いデバイスでの表示が最適化されます。

### Q: アスペクト比が異なるデバイスはどうすれば？

A: App Store Connect が自動的にスケーリングしますが、重要な要素が切れないように、セーフエリアを意識した画面設計が重要です。

### Q: スクリーンショットは毎回全て更新する必要がありますか？

A: いいえ。変更がないデバイスサイズのスクリーンショットは再利用できます。`fastlane deliver --skip_binary_upload` でアップロード時に、既存のスクリーンショットは保持されます。

### Q: 実機でスクリーンショットを撮影できますか？

A: はい。実機で撮影したスクリーンショットもアップロード可能です。ただし、ステータスバーの時刻やバッテリー表示を調整できないため、シミュレーターの使用を推奨します。

## 参考リンク

- [App Store Connectヘルプ - スクリーンショット仕様](https://help.apple.com/app-store-connect/#/devd274dd925)
- [Human Interface Guidelines - App Icon and Image Sizes](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [fastlane snapshot ドキュメント](https://docs.fastlane.tools/actions/snapshot/)
