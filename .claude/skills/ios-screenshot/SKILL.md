---
name: ios-screenshot
description: App Store用のスクリーンショットを生成・管理します。Use when ユーザーが「スクリーンショット撮って」「App Storeのスクショ更新して」「snapshotして」と言ったとき。
---

# iOS Screenshot

App Store 用のスクリーンショットを生成・管理するスキルです。fastlane snapshot を使った自動生成、または手動撮影したスクリーンショットの管理をサポートします。

## ワークフロー概要

```
方法1: 手動でスクリーンショット撮影
  1. シミュレーターでアプリ起動
  2. Cmd+S でスクリーンショット撮影
  3. fastlane/screenshots/ に配置
  4. fastlane deliver でアップロード

方法2: fastlane snapshot で自動生成
  1. UI Test でスクリーンショット撮影ロジック作成
  2. Snapfile で設定
  3. fastlane snapshot 実行
  4. 自動で fastlane/screenshots/ に保存
```

## 指示

### Step 1: スクリーンショット要件の確認

App Store で必要なスクリーンショットサイズを確認：

**iPhone (必須)**:
- 6.9" (iPhone 16 Pro Max): 1320 x 2868 px
- 6.7" (iPhone 15 Plus/Pro Max): 1290 x 2796 px
- 5.5" (iPhone 8 Plus): 1242 x 2208 px

**iPad (必須、ユニバーサルアプリの場合)**:
- 13" (iPad Pro 13"): 2048 x 2732 px
- 12.9" (iPad Pro 12.9"): 2048 x 2732 px

**必要枚数**: 各サイズで 1〜10 枚（推奨: 3〜5枚）

### Step 2: 手動でスクリーンショットを撮影

#### 2a. シミュレーターの準備

```bash
# 利用可能なシミュレーターを確認
xcrun simctl list devices | grep "iPhone\|iPad"

# 特定のシミュレーターを起動
open -a Simulator --args -CurrentDeviceUDID <UDID>

# または、Xcodeから起動
# Xcode > Product > Destination > 対象デバイスを選択
```

#### 2b. スクリーンショットの撮影

1. **シミュレーターでアプリを起動**
2. **撮影したい画面に遷移**
3. **Cmd + S** でスクリーンショット保存
   - 保存先: デスクトップ
   - ファイル名: `Simulator Screenshot - iPhone 16 Pro Max - 2026-02-08 at 15.30.42.png`

#### 2c. ファイル名のリネーム

App Store の命名規則に従ってリネーム：

```bash
# ディレクトリ構造を作成
mkdir -p fastlane/screenshots/ja-JP
mkdir -p fastlane/screenshots/en-US

# ファイル名を変更（例）
# ja-JP/01-speed-view.png
# ja-JP/02-map-view.png
# ja-JP/03-settings.png
```

**命名規則**:
- 数字のプレフィックス（01, 02, 03...）で表示順を制御
- 分かりやすい名前をつける
- 言語ごとにディレクトリを分ける

### Step 3: fastlane snapshot で自動生成（オプション）

#### 3a. snapshot の初期化

```bash
# snapshot のセットアップ
fastlane snapshot init
```

生成されるファイル:
- `fastlane/Snapfile` - デバイス設定
- `SnapshotHelper.swift` - UI Test用ヘルパー

#### 3b. Snapfile の設定

```ruby
# fastlane/Snapfile
devices([
  "iPhone 16 Pro Max",
  "iPhone 15 Plus",
  "iPhone 8 Plus",
  "iPad Pro (13-inch) (M4)"
])

languages([
  "ja-JP",
  "en-US"
])

scheme("speedmeter")  # UI Test スキームを指定

output_directory("./fastlane/screenshots")
clear_previous_screenshots(true)
```

#### 3c. UI Test の作成

UI Test ターゲットにスクリーンショット撮影ロジックを追加：

```swift
import XCTest

class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)  // SnapshotHelper
        app.launch()
    }

    func testTakeScreenshots() throws {
        let app = XCUIApplication()

        // 画面1: スピード表示
        snapshot("01-speed-view")
        sleep(2)

        // 画面2: マップ表示
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(2)
        snapshot("02-map-view")

        // 画面3: 設定画面
        app.buttons["settingsButton"].tap()
        sleep(2)
        snapshot("03-settings")
    }
}
```

#### 3d. snapshot の実行

```bash
# スクリーンショット生成
fastlane snapshot

# または、特定のデバイスのみ
fastlane snapshot --devices "iPhone 16 Pro Max"
```

**期待される結果**:
```
fastlane/screenshots/
├── ja-JP/
│   ├── 01-speed-view.png (iPhone 16 Pro Max)
│   ├── 02-map-view.png
│   └── ...
├── en-US/
│   ├── 01-speed-view.png
│   └── ...
└── screenshots.html  # プレビュー用HTML
```

### Step 4: スクリーンショットの確認

```bash
# プレビューHTMLを開く
open fastlane/screenshots/screenshots.html

# または、ディレクトリを確認
ls -lh fastlane/screenshots/ja-JP/
```

**確認事項**:
- ✅ 各デバイスサイズで撮影されているか
- ✅ 画像が鮮明か（ぼやけていないか）
- ✅ UI要素が正しく表示されているか
- ✅ ステータスバーの時刻が綺麗か（9:41推奨）
- ✅ テキストが読みやすいか

### Step 5: App Store Connect へのアップロード

#### 5a. メタデータと一緒にアップロード

```bash
# スクリーンショットとメタデータを一緒にアップロード
fastlane deliver

# または、スクリーンショットのみ
fastlane deliver --skip_binary_upload --skip_metadata
```

#### 5b. 特定の言語のみアップロード

```bash
fastlane deliver \
  --skip_binary_upload \
  --languages "ja-JP"
```

#### 5c. 強制上書き

```bash
# 既存のスクリーンショットを上書き
fastlane deliver \
  --skip_binary_upload \
  --overwrite_screenshots
```

### Step 6: App Store Connect で確認

```bash
# App Store Connectを開く
open "https://appstoreconnect.apple.com/"
```

**確認事項**:
1. App Store タブを開く
2. 「スクリーンショット」セクションを確認
3. 各デバイスサイズで表示されているか確認
4. 順序が正しいか確認

---

## 使用例

### 例 1: 手動でスクリーンショットを撮影してアップロード

**ユーザーが言うこと**: "App Store用のスクリーンショット撮って"

**実行されること**:
1. シミュレーターで iPhone 16 Pro Max を起動
2. アプリを起動して各画面でCmd+Sで撮影
3. ファイルを `fastlane/screenshots/ja-JP/` にリネームして配置
4. `fastlane deliver --skip_binary_upload` でアップロード

**結果**: 新しいスクリーンショットが App Store Connect に反映される

### 例 2: fastlane snapshot で自動生成

**ユーザーが言うこと**: "snapshotで自動的にスクリーンショット生成して"

**実行されること**:
1. UI Test に撮影ロジックを追加
2. Snapfile でデバイスと言語を設定
3. `fastlane snapshot` を実行
4. 全デバイス・全言語で自動生成
5. `fastlane deliver --skip_binary_upload` でアップロード

**結果**:
```
✅ 生成完了:
  - iPhone 16 Pro Max: 3枚
  - iPhone 15 Plus: 3枚
  - iPhone 8 Plus: 3枚
  - iPad Pro 13": 3枚
📁 fastlane/screenshots/screenshots.html で確認
```

### 例 3: 既存のスクリーンショットをダウンロード

**ユーザーが言うこと**: "App Store Connectのスクリーンショットをダウンロードして"

**実行されること**:
```bash
fastlane deliver --download_screenshots
```

**結果**: 現在の App Store のスクリーンショットがローカルに保存される

### 例 4: プレビュー動画の追加

**ユーザーが言うこと**: "App Previewも追加したい"

**実行されること**:
1. App Preview 動画を作成（最大30秒、.mov または .mp4）
2. `fastlane/screenshots/ja-JP/` に配置
   - ファイル名: `iPhoneProMax-01.mp4`
3. `fastlane deliver --skip_binary_upload` でアップロード

**結果**: スクリーンショットと動画が一緒にアップロードされる

---

## トラブルシューティング

### エラー: `No screenshots found`

**原因**: fastlane/screenshots/ ディレクトリが空またはファイル名が不正

**解決方法**:
```bash
# ディレクトリ構造を確認
ls -R fastlane/screenshots/

# 正しい構造:
# fastlane/screenshots/ja-JP/01-screenshot.png
# fastlane/screenshots/en-US/01-screenshot.png
```

### エラー: snapshot 実行時に `UI Test target not found`

**原因**: UI Test ターゲットが存在しないか、スキーム設定が間違っている

**解決方法**:
1. Xcode で UI Test ターゲットを作成
2. Snapfile の `scheme` を正しい UI Test スキームに設定
3. スキームの Test アクションに UI Test が含まれているか確認

### 問題: スクリーンショットがぼやけている

**原因**: シミュレーターの解像度設定

**解決方法**:
1. シミュレーター > Window > Physical Size を選択
2. または、実機でスクリーンショットを撮影
3. snapshot 使用時は自動的に正しい解像度で撮影される

### 問題: ステータスバーに不要な情報が表示される

**原因**: シミュレーターのステータスバーがそのまま表示されている

**解決方法**:

**方法1: SimulatorStatusMagic（Xcode 12以前）**
```bash
# インストール
brew install SimulatorStatusMagic

# 実行
xcrun simctl status_bar booted override \
  --time "9:41" \
  --batteryLevel 100 \
  --cellularMode active
```

**方法2: snapshot の機能を使う**
```ruby
# Snapfile
override_status_bar(true)
status_bar_override({
  time: "9:41 AM",
  battery: 100,
  carrier: "Carrier"
})
```

### 問題: App Preview 動画のフォーマットエラー

**原因**: ファイル形式またはサイズが App Store の要件に合っていない

**解決方法**:
- **形式**: H.264 または HEVC コーデックの .mp4 または .mov
- **長さ**: 15秒〜30秒
- **解像度**: デバイスのネイティブ解像度
- **ファイルサイズ**: 500MB以下

変換コマンド:
```bash
ffmpeg -i input.mov -c:v libx264 -crf 23 -preset medium output.mp4
```

---

## 参考資料

- 詳細なデバイスサイズ一覧は `references/device-sizes.md` を参照
- **App Store スクリーンショット仕様**: [Apple公式ドキュメント](https://help.apple.com/app-store-connect/#/devd274dd925)
- **fastlane snapshot**: [docs.fastlane.tools/actions/snapshot](https://docs.fastlane.tools/actions/snapshot/)
- **App Preview ガイドライン**: [Apple公式ガイドライン](https://developer.apple.com/app-store/app-previews/)

---

## 注意事項

### スクリーンショット要件
- **最小枚数**: 各デバイスサイズで最低1枚
- **推奨枚数**: 3〜5枚（ユーザーに主要機能を伝える）
- **最大枚数**: 10枚
- **ファイル形式**: PNG または JPG（PNG推奨）
- **カラープロファイル**: sRGB または Display P3

### ベストプラクティス
- ✅ 最初のスクリーンショットが最も重要（検索結果で表示される）
- ✅ アプリの主要機能を順番に見せる
- ✅ テキストオーバーレイは控えめに（Apple の審査ガイドライン）
- ✅ 実際のアプリ画面を使用（モックアップは避ける）
- ✅ ステータスバーを綺麗に（9:41、フル充電、Wi-Fi接続）

### 多言語対応
- 各言語で別々のスクリーンショットを用意
- 翻訳だけでなく、文化的な配慮も必要
- 最低限、英語と日本語を用意（日本市場向けの場合）

### App Preview 動画
- スクリーンショットの前に再生される
- 音声なしでも内容が分かるようにする
- 最初の3秒が最も重要
- 各デバイスサイズで個別に用意する必要がある

### 更新頻度
- アプリのUIが大きく変わったら必ず更新
- 新機能追加時に更新を検討
- 競合アプリと比較して見劣りしないか定期的にチェック
