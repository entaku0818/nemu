---
name: xcode-config
description: Xcode Build Configuration (.xcconfig) を管理します。Use when ユーザーが「xcconfig設定して」「ビルド設定変更して」「環境変数管理して」と言ったとき。
---

# Xcode Config

Xcode Build Configuration (.xcconfig ファイル) の作成・管理するスキルです。Debug/Release の設定分離、環境変数管理、ビルド設定の一元管理をサポートします。

## xcconfig を使うメリット

```
✅ ビルド設定をファイルで管理（Git管理可能）
✅ Debug/Release で異なる設定を簡単に切り替え
✅ APIキー、URLなどの環境変数を一元管理
✅ Xcode GUI での設定ミスを防ぐ
✅ チーム全体で設定を統一
```

## 指示

### Step 1: 現在のビルド設定を確認

まず、プロジェクトの現在の設定を確認します：

```bash
# プロジェクトファイルを確認
find . -name "*.xcodeproj" -maxdepth 2

# 既存の xcconfig ファイルを確認
find . -name "*.xcconfig" -type f
```

Xcode で確認：
1. プロジェクトファイルを開く
2. プロジェクト設定 > Info タブ
3. Configurations セクションを確認

### Step 2: xcconfig ファイルの作成

#### 2a. ディレクトリ構造の準備

```bash
# Config ディレクトリを作成
mkdir -p Config

# xcconfig ファイルを作成
touch Config/Debug.xcconfig
touch Config/Release.xcconfig
touch Config/Shared.xcconfig  # オプション: 共通設定
```

#### 2b. Shared.xcconfig（共通設定）

全ビルド構成で共通の設定：

```ruby
// Config/Shared.xcconfig

// MARK: - Swift Settings
SWIFT_VERSION = 5.9
SWIFT_OPTIMIZATION_LEVEL = -Onone

// MARK: - iOS Deployment
IPHONEOS_DEPLOYMENT_TARGET = 17.0

// MARK: - Code Signing
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = YOUR_TEAM_ID

// MARK: - Common Bundle Settings
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.$(PRODUCT_NAME:rfc1034identifier)
```

#### 2c. Debug.xcconfig

開発用の設定：

```ruby
// Config/Debug.xcconfig

#include "Shared.xcconfig"

// MARK: - Configuration
CONFIGURATION = Debug

// MARK: - App Settings
PRODUCT_NAME = $(TARGET_NAME)
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.$(PRODUCT_NAME:rfc1034identifier).debug

// MARK: - Versioning
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1

// MARK: - API Keys (Development)
API_BASE_URL = https:/$()/dev.api.example.com
API_KEY = dev_api_key_12345

// MARK: - AdMob (Test IDs)
ADMOB_APP_ID = ca-app-pub-3940256099942544~1458002511
ADMOB_BANNER_ID = ca-app-pub-3940256099942544/2934735716

// MARK: - Build Settings
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG
GCC_PREPROCESSOR_DEFINITIONS = DEBUG=1

// MARK: - Optimization
SWIFT_OPTIMIZATION_LEVEL = -Onone
GCC_OPTIMIZATION_LEVEL = 0

// MARK: - Debug Flags
ENABLE_TESTABILITY = YES
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
```

#### 2d. Release.xcconfig

本番用の設定：

```ruby
// Config/Release.xcconfig

#include "Shared.xcconfig"

// MARK: - Configuration
CONFIGURATION = Release

// MARK: - App Settings
PRODUCT_NAME = $(TARGET_NAME)
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.$(PRODUCT_NAME:rfc1034identifier)

// MARK: - Versioning
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1

// MARK: - API Keys (Production)
API_BASE_URL = https:/$()/api.example.com
API_KEY = prod_api_key_67890

// MARK: - AdMob (Production IDs)
ADMOB_APP_ID = ca-app-pub-XXXXXXXXXXXX~YYYYYYYYYY
ADMOB_BANNER_ID = ca-app-pub-XXXXXXXXXXXX/ZZZZZZZZZZ

// MARK: - Build Settings
SWIFT_ACTIVE_COMPILATION_CONDITIONS = RELEASE

// MARK: - Optimization
SWIFT_OPTIMIZATION_LEVEL = -O
SWIFT_COMPILATION_MODE = wholemodule
GCC_OPTIMIZATION_LEVEL = s

// MARK: - Release Flags
ENABLE_TESTABILITY = NO
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
VALIDATE_PRODUCT = YES
```

### Step 3: Xcode プロジェクトに xcconfig を適用

#### 3a. Xcode でファイルを追加

1. Xcode でプロジェクトを開く
2. Config ディレクトリをプロジェクトに追加
   - ファイル > Add Files to "ProjectName"
   - Config フォルダを選択
   - "Create folder references" を選択（重要）
   - ターゲットのチェックは**外す**（xcconfig はターゲットに含めない）

#### 3b. Configuration に xcconfig を設定

1. プロジェクトファイルを選択
2. **プロジェクト**（ターゲットではない）を選択
3. Info タブ > Configurations
4. Debug の横のドロップダウン > Config/Debug.xcconfig を選択
5. Release の横のドロップダウン > Config/Release.xcconfig を選択

#### 3c. ターゲットの設定をクリア

xcconfig を正しく機能させるため、ターゲットの設定をクリア：

1. ターゲットを選択
2. Build Settings タブ
3. 左下の "Levels" を選択
4. xcconfig で管理する設定の Target 列の値を削除（Delete キー）
   - 例: PRODUCT_BUNDLE_IDENTIFIER, MARKETING_VERSION など

### Step 4: Info.plist で変数を使用

Info.plist で xcconfig の変数を参照：

```xml
<!-- Info.plist -->
<key>CFBundleDisplayName</key>
<string>$(PRODUCT_NAME)</string>

<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

<key>CFBundleShortVersionString</key>
<string>$(MARKETING_VERSION)</string>

<key>CFBundleVersion</key>
<string>$(CURRENT_PROJECT_VERSION)</string>

<!-- カスタム変数 -->
<key>APIBaseURL</key>
<string>$(API_BASE_URL)</string>

<key>GADApplicationIdentifier</key>
<string>$(ADMOB_APP_ID)</string>
```

### Step 5: Swift コードで xcconfig の値を読み取る

#### 5a. Info.plist から読み取る

```swift
// Config.swift
enum Config {
    static let apiBaseURL: String = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String else {
            fatalError("APIBaseURL not found in Info.plist")
        }
        return urlString
    }()

    static let apiKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "APIKey") as? String else {
            fatalError("APIKey not found in Info.plist")
        }
        return key
    }()

    static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
}

// 使用例
let url = "\(Config.apiBaseURL)/users"
```

#### 5b. Compilation Conditions を使用

```swift
#if DEBUG
let apiURL = "https://dev.api.example.com"
#else
let apiURL = "https://api.example.com"
#endif
```

### Step 6: 設定の検証

```bash
# Debug ビルド
xcodebuild -project YourApp.xcodeproj \
  -scheme YourApp \
  -configuration Debug \
  -showBuildSettings | grep -E "PRODUCT_BUNDLE_IDENTIFIER|MARKETING_VERSION|API_BASE_URL"

# Release ビルド
xcodebuild -project YourApp.xcodeproj \
  -scheme YourApp \
  -configuration Release \
  -showBuildSettings | grep -E "PRODUCT_BUNDLE_IDENTIFIER|MARKETING_VERSION|API_BASE_URL"
```

期待される出力:
```
Debug:
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.YourApp.debug
MARKETING_VERSION = 1.0.0
API_BASE_URL = https://dev.api.example.com

Release:
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.YourApp
MARKETING_VERSION = 1.0.0
API_BASE_URL = https://api.example.com
```

---

## 使用例

### 例 1: AdMob の Test ID と Production ID を分ける

**ユーザーが言うこと**: "AdMobのIDをDebugとReleaseで分けたい"

**実行されること**:
1. Config/Debug.xcconfig に Test ID を設定
2. Config/Release.xcconfig に Production ID を設定
3. Info.plist で `$(ADMOB_APP_ID)` を参照
4. ビルドして確認

**結果**: Debug ビルドでは Test ID、Release ビルドでは Production ID が使用される

### 例 2: API エンドポイントの切り替え

**ユーザーが言うこと**: "開発環境と本番環境でAPIのURLを切り替えたい"

**実行されること**:
1. xcconfig に `API_BASE_URL` を定義
2. Info.plist で `APIBaseURL` キーを追加
3. Swift コードで `Bundle.main.object(forInfoDictionaryKey:)` で取得

**結果**: ビルド構成によって自動的に適切な API URL が使用される

### 例 3: バージョン番号の一元管理

**ユーザーが言うこと**: "バージョン番号を xcconfig で管理したい"

**実行されること**:
1. xcconfig に `MARKETING_VERSION` と `CURRENT_PROJECT_VERSION` を定義
2. Info.plist で `$(MARKETING_VERSION)` を参照
3. fastlane から xcconfig を編集してバージョン更新

**結果**: バージョン番号を xcconfig ファイルで一元管理できる

### 例 4: 複数の環境（Dev / Staging / Production）

**ユーザーが言うこと**: "Dev、Staging、Productionの3つの環境が欲しい"

**実行されること**:
1. `Config/Dev.xcconfig`, `Config/Staging.xcconfig`, `Config/Production.xcconfig` を作成
2. Xcode で新しい Configuration を追加（Info > Configurations > + ボタン）
3. 各 Configuration に対応する xcconfig を割り当て
4. スキームを複製して各環境用のスキームを作成

**結果**: 3つの環境を簡単に切り替えられる

---

## トラブルシューティング

### 問題: xcconfig の設定が反映されない

**原因**: ターゲットの Build Settings で値が上書きされている

**解決方法**:
1. ターゲット > Build Settings > Levels を表示
2. xcconfig で設定した項目の Target 列を確認
3. Target 列に値がある場合は削除（Delete キー）
4. Resolved 列に xcconfig の値が表示されることを確認

### 問題: `$(VARIABLE_NAME)` が展開されない

**原因**: Info.plist のフォーマットが正しくない、または変数名のタイポ

**解決方法**:
```bash
# ビルド設定を確認
xcodebuild -showBuildSettings | grep VARIABLE_NAME

# Info.plist の値を確認
/usr/libexec/PlistBuddy -c "Print :KeyName" Info.plist
```

### 問題: 複数の xcconfig でコンフリクト

**原因**: `#include` で読み込んだファイルと設定が重複

**解決方法**:
- 優先度: **後から定義したものが優先**される
- 構造化する:
  ```
  Shared.xcconfig（共通設定）
  ├── Debug.xcconfig（#include "Shared.xcconfig"）
  └── Release.xcconfig（#include "Shared.xcconfig"）
  ```

### エラー: `Unable to load contents of file list`

**原因**: xcconfig ファイルがターゲットに追加されている

**解決方法**:
1. プロジェクトナビゲーターで xcconfig ファイルを選択
2. File Inspector > Target Membership をすべて外す
3. xcconfig はプロジェクトレベルで参照されるべき

### 問題: Info.plist の変数が空文字列になる

**原因**: Info.plist のプロパティが `User-Defined` として認識されていない

**解決方法**:
1. Build Settings で Custom フラグを定義
   ```
   INFOPLIST_OTHER_PREPROCESSOR_FLAGS = -traditional
   ```
2. または、Info.plist を Source Code として開いて確認

---

## 参考資料

- 詳細な変数一覧は `references/config-variables.md` を参照
- **Xcode Build Configuration Files**: [NSHipster記事](https://nshipster.com/xcconfig/)
- **Apple Documentation**: [Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)

---

## 注意事項

### セキュリティ

- ⚠️ **APIキーや秘密情報を xcconfig に直接書かない**
  - xcconfig は Git にコミットされる
  - `.gitignore` に追加するか、環境変数から読み込む
  ```ruby
  // Secrets.xcconfig (Gitignore対象)
  API_KEY = $(API_KEY_ENV)
  ```

- ✅ **本番用の秘密情報の管理方法**:
  1. CI/CD で環境変数として注入
  2. `.xcconfig.template` をリポジトリに保存
  3. ローカルでコピーして実際の値を入力
  ```bash
  # .gitignore
  Config/Secrets.xcconfig

  # リポジトリには Secrets.xcconfig.template を保存
  ```

### ベストプラクティス

- ✅ **共通設定を Shared.xcconfig に抽出**
- ✅ **MARK コメントで整理**
  ```ruby
  // MARK: - API Settings
  // MARK: - Build Settings
  ```
- ✅ **変数名は大文字とアンダースコア**
  - `API_BASE_URL` ✅
  - `apiBaseUrl` ❌
- ✅ **プロジェクトレベルで設定、ターゲットレベルは空にする**
- ✅ **ドキュメントとして xcconfig を活用**（コメントで説明を追加）

### xcconfig の制限事項

- ❌ **条件分岐ができない**（if文は使えない）
  - 代替: 複数の xcconfig ファイルを作成
- ❌ **計算や文字列操作ができない**
  - 代替: ビルドフェーズスクリプトで処理
- ❌ **配列や辞書は扱えない**
  - 代替: スペース区切りの文字列
  ```ruby
  SUPPORTED_LANGUAGES = en ja zh
  ```

### 変数の参照方法

```ruby
// 他の変数を参照
BASE_BUNDLE_ID = com.yourcompany
PRODUCT_BUNDLE_IDENTIFIER = $(BASE_BUNDLE_ID).$(PRODUCT_NAME:rfc1034identifier)

// 環境変数を参照
API_KEY = $(API_KEY_FROM_ENV)

// システム変数を参照
OUTPUT_PATH = $(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
```

### CI/CD での活用

```yaml
# GitHub Actions example
- name: Update xcconfig
  run: |
    echo "API_KEY = ${{ secrets.API_KEY }}" >> Config/Secrets.xcconfig
    echo "API_BASE_URL = ${{ secrets.API_URL }}" >> Config/Secrets.xcconfig

- name: Build
  run: |
    xcodebuild -configuration Release \
      -xcconfig Config/Release.xcconfig \
      build
```

### トラブルシューティングコマンド

```bash
# すべてのビルド設定を表示
xcodebuild -showBuildSettings

# 特定の変数を確認
xcodebuild -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER

# xcconfig の構文チェック（エラーがあればビルドで確認）
xcodebuild -project YourApp.xcodeproj -showBuildSettings > /dev/null
```
