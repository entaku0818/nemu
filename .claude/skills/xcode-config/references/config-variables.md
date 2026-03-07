# Xcode Build Configuration 変数一覧

よく使用される Xcode Build Settings の変数とその用途を解説します。

## 基本情報

### プロダクト設定

| 変数名 | 説明 | 例 |
|--------|------|---|
| `PRODUCT_NAME` | プロダクトの名前 | `MyApp` |
| `PRODUCT_BUNDLE_IDENTIFIER` | Bundle Identifier | `com.company.myapp` |
| `MARKETING_VERSION` | マーケティングバージョン (ユーザーに表示) | `1.2.0` |
| `CURRENT_PROJECT_VERSION` | ビルド番号 | `42` |
| `PRODUCT_MODULE_NAME` | モジュール名（Swiftで使用） | `MyApp` |

**使用例**:
```ruby
PRODUCT_NAME = MyApp
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.$(PRODUCT_NAME:rfc1034identifier)
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
```

### デプロイメント設定

| 変数名 | 説明 | 例 |
|--------|------|---|
| `IPHONEOS_DEPLOYMENT_TARGET` | 最小iOS バージョン | `17.0` |
| `MACOSX_DEPLOYMENT_TARGET` | 最小macOS バージョン | `14.0` |
| `TVOS_DEPLOYMENT_TARGET` | 最小tvOS バージョン | `17.0` |
| `WATCHOS_DEPLOYMENT_TARGET` | 最小watchOS バージョン | `10.0` |
| `TARGETED_DEVICE_FAMILY` | 対象デバイス | `1,2` (iPhone, iPad) |

**デバイスファミリー**:
- `1` - iPhone
- `2` - iPad
- `1,2` - Universal

**使用例**:
```ruby
IPHONEOS_DEPLOYMENT_TARGET = 17.0
TARGETED_DEVICE_FAMILY = 1,2
```

## Swift Settings

| 変数名 | 説明 | 値 |
|--------|------|---|
| `SWIFT_VERSION` | Swift バージョン | `5.9`, `5.10` |
| `SWIFT_OPTIMIZATION_LEVEL` | 最適化レベル | `-Onone`, `-O`, `-Osize` |
| `SWIFT_COMPILATION_MODE` | コンパイルモード | `singlefile`, `wholemodule` |
| `SWIFT_ACTIVE_COMPILATION_CONDITIONS` | コンパイル条件 | `DEBUG`, `RELEASE` |

**最適化レベル**:
- `-Onone` - 最適化なし（Debug用）
- `-O` - 速度優先の最適化（Release用）
- `-Osize` - サイズ優先の最適化

**使用例**:
```ruby
// Debug.xcconfig
SWIFT_VERSION = 5.9
SWIFT_OPTIMIZATION_LEVEL = -Onone
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG

// Release.xcconfig
SWIFT_OPTIMIZATION_LEVEL = -O
SWIFT_COMPILATION_MODE = wholemodule
SWIFT_ACTIVE_COMPILATION_CONDITIONS = RELEASE
```

## Code Signing

| 変数名 | 説明 | 値 |
|--------|------|---|
| `CODE_SIGN_STYLE` | 署名スタイル | `Automatic`, `Manual` |
| `CODE_SIGN_IDENTITY` | 署名証明書 | `Apple Development`, `Apple Distribution` |
| `DEVELOPMENT_TEAM` | チームID | `ABCDE12345` |
| `PROVISIONING_PROFILE_SPECIFIER` | プロビジョニングプロファイル | プロファイル名 |

**使用例**:
```ruby
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = ABCDE12345

// または Manual
CODE_SIGN_STYLE = Manual
CODE_SIGN_IDENTITY = Apple Distribution
PROVISIONING_PROFILE_SPECIFIER = MyApp AppStore Profile
```

## ビルド最適化

### GCC (Objective-C / C++)

| 変数名 | 説明 | 値 |
|--------|------|---|
| `GCC_OPTIMIZATION_LEVEL` | 最適化レベル | `0`, `1`, `2`, `3`, `s` |
| `GCC_PREPROCESSOR_DEFINITIONS` | プリプロセッサ定義 | `DEBUG=1` |
| `GCC_GENERATE_DEBUGGING_SYMBOLS` | デバッグシンボル生成 | `YES`, `NO` |

**最適化レベル**:
- `0` - 最適化なし
- `1`-`3` - 速度優先（数字が大きいほど最適化強）
- `s` - サイズ優先

**使用例**:
```ruby
// Debug
GCC_OPTIMIZATION_LEVEL = 0
GCC_PREPROCESSOR_DEFINITIONS = DEBUG=1

// Release
GCC_OPTIMIZATION_LEVEL = s
```

### デバッグ設定

| 変数名 | 説明 | 値 |
|--------|------|---|
| `DEBUG_INFORMATION_FORMAT` | デバッグ情報の形式 | `dwarf`, `dwarf-with-dsym` |
| `ENABLE_TESTABILITY` | テスト可能にする | `YES`, `NO` |
| `VALIDATE_PRODUCT` | プロダクトの検証 | `YES`, `NO` |
| `ENABLE_BITCODE` | Bitcode有効化（非推奨） | `YES`, `NO` |

**使用例**:
```ruby
// Debug
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
ENABLE_TESTABILITY = YES

// Release
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
ENABLE_TESTABILITY = NO
VALIDATE_PRODUCT = YES
```

## パス設定

| 変数名 | 説明 |
|--------|------|
| `PROJECT_DIR` | プロジェクトディレクトリ |
| `SRCROOT` | ソースルート（= PROJECT_DIR） |
| `BUILD_DIR` | ビルド出力ディレクトリ |
| `BUILT_PRODUCTS_DIR` | ビルド生成物ディレクトリ |
| `TARGET_BUILD_DIR` | ターゲットのビルドディレクトリ |
| `CONFIGURATION` | 現在のConfiguration名 |
| `EFFECTIVE_PLATFORM_NAME` | プラットフォーム名 (`-iphoneos`, `-iphonesimulator`) |

**使用例**:
```ruby
// カスタムスクリプトのパスを指定
SCRIPT_PATH = $(SRCROOT)/Scripts/generate.sh

// 出力先を指定
OUTPUT_FILE = $(TARGET_BUILD_DIR)/Generated.swift
```

## Info.plist 設定

| 変数名 | 説明 | Info.plist キー |
|--------|------|----------------|
| `INFOPLIST_FILE` | Info.plist のパス | - |
| `INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents` | 間接入力イベント | `UIApplicationSupportsIndirectInputEvents` |
| `INFOPLIST_KEY_UILaunchScreen_Generation` | Launch Screen自動生成 | - |
| `INFOPLIST_KEY_UISupportedInterfaceOrientations` | 対応する画面向き | `UISupportedInterfaceOrientations` |

**使用例**:
```ruby
INFOPLIST_FILE = $(SRCROOT)/Info.plist
INFOPLIST_KEY_UILaunchScreen_Generation = YES
```

## カスタム変数

### ユーザー定義変数

独自の変数を定義して使用できます。

**命名規則**:
- 大文字とアンダースコアを使用
- プレフィックスをつけると分かりやすい（`APP_`, `API_`, `CONFIG_`など）

**使用例**:
```ruby
// API設定
API_BASE_URL = https:/$()/api.example.com
API_KEY = your_api_key_here
API_TIMEOUT = 30

// Feature Flags
FEATURE_DARK_MODE = YES
FEATURE_ANALYTICS = YES

// AdMob
ADMOB_APP_ID = ca-app-pub-1234567890123456~0987654321
ADMOB_BANNER_ID = ca-app-pub-1234567890123456/1234567890

// Firebase
FIREBASE_PLIST_PATH = $(SRCROOT)/Firebase/$(CONFIGURATION)/GoogleService-Info.plist
```

### Info.plist でカスタム変数を使用

```xml
<key>APIBaseURL</key>
<string>$(API_BASE_URL)</string>

<key>APIKey</key>
<string>$(API_KEY)</string>

<key>GADApplicationIdentifier</key>
<string>$(ADMOB_APP_ID)</string>
```

### Swift で読み取る

```swift
enum Config {
    static let apiBaseURL: String = {
        Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as! String
    }()

    static let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "APIKey") as! String
    }()
}
```

## 変数の変換・修飾子

### 文字列変換

| 修飾子 | 説明 | 例 |
|--------|------|---|
| `:rfc1034identifier` | RFC1034準拠の識別子に変換（スペースを削除など） | `My App` → `MyApp` |
| `:lower` | 小文字に変換 | `MyApp` → `myapp` |
| `:upper` | 大文字に変換 | `MyApp` → `MYAPP` |
| `:identifier` | C識別子に変換 | `My-App` → `My_App` |

**使用例**:
```ruby
// PRODUCT_NAME = "My Cool App"
BUNDLE_ID = com.company.$(PRODUCT_NAME:rfc1034identifier)
// → com.company.MyCoolApp

CONSTANT_NAME = APP_$(PRODUCT_NAME:upper:identifier)
// → APP_MY_COOL_APP
```

### パス操作

| 修飾子 | 説明 |
|--------|------|
| `:dir` | ディレクトリ部分を取得 |
| `:file` | ファイル名を取得 |
| `:base` | 拡張子なしのファイル名 |
| `:suffix` | 拡張子を取得 |

## 条件付き設定

xcconfig 自体に条件分岐はありませんが、以下の方法で実現できます。

### 方法1: Configuration ごとにファイルを分ける

```
Config/
├── Shared.xcconfig
├── Debug.xcconfig
├── Release.xcconfig
└── Staging.xcconfig
```

### 方法2: Xcode の `[config=...]` 記法

```ruby
// Debug のみ適用
SETTING[config=Debug] = debug_value

// Release のみ適用
SETTING[config=Release] = release_value

// SDK 指定
SETTING[sdk=iphoneos*] = device_value
SETTING[sdk=iphonesimulator*] = simulator_value

// アーキテクチャ指定
SETTING[arch=arm64] = arm_value
SETTING[arch=x86_64] = x86_value
```

### 方法3: `#include` で条件的に読み込む

```ruby
// Base.xcconfig
#include? "Secrets.xcconfig"  // ?付きでオプショナル
```

## 環境変数の利用

### CI/CD から変数を渡す

```bash
# コマンドラインから xcconfig 変数を上書き
xcodebuild \
  API_KEY="${API_KEY_SECRET}" \
  MARKETING_VERSION="${VERSION}" \
  build
```

### 環境変数を xcconfig で参照

```ruby
// 環境変数 API_KEY_ENV を参照
API_KEY = $(API_KEY_ENV)

// デフォルト値を設定
API_KEY = ${API_KEY_ENV:default_key}
```

## よくある設定パターン

### パターン1: Debug/Release で Bundle Identifier を分ける

```ruby
// Debug.xcconfig
PRODUCT_BUNDLE_IDENTIFIER = com.company.myapp.debug

// Release.xcconfig
PRODUCT_BUNDLE_IDENTIFIER = com.company.myapp
```

### パターン2: API エンドポイントの切り替え

```ruby
// Debug.xcconfig
API_BASE_URL = https:/$()/dev-api.example.com
API_DEBUG_MODE = YES

// Release.xcconfig
API_BASE_URL = https:/$()/api.example.com
API_DEBUG_MODE = NO
```

### パターン3: Feature Flag 管理

```ruby
// Debug.xcconfig
FEATURE_DEBUG_MENU = YES
FEATURE_MOCK_DATA = YES
FEATURE_VERBOSE_LOGGING = YES

// Release.xcconfig
FEATURE_DEBUG_MENU = NO
FEATURE_MOCK_DATA = NO
FEATURE_VERBOSE_LOGGING = NO
```

### パターン4: 複数環境（Dev / Staging / Prod）

```ruby
// Dev.xcconfig
ENVIRONMENT = development
API_BASE_URL = https:/$()/dev.api.example.com
BUNDLE_ID_SUFFIX = .dev

// Staging.xcconfig
ENVIRONMENT = staging
API_BASE_URL = https:/$()/staging.api.example.com
BUNDLE_ID_SUFFIX = .staging

// Production.xcconfig
ENVIRONMENT = production
API_BASE_URL = https:/$()/api.example.com
BUNDLE_ID_SUFFIX =

// 共通で使用
PRODUCT_BUNDLE_IDENTIFIER = com.company.myapp$(BUNDLE_ID_SUFFIX)
```

## トラブルシューティング

### 変数が展開されない

```bash
# ビルド設定で変数の値を確認
xcodebuild -showBuildSettings | grep VARIABLE_NAME

# Info.plist で展開されているか確認
/usr/libexec/PlistBuddy -c "Print :KeyName" \
  "$TARGET_BUILD_DIR/$INFOPLIST_PATH"
```

### コンフリクトの確認

```bash
# Levels 表示で優先順位を確認
# Xcode > Target > Build Settings > Levels

# コマンドラインで確認
xcodebuild -showBuildSettings \
  -project MyApp.xcodeproj \
  -target MyApp \
  -configuration Debug
```

### 変数の一覧を取得

```bash
# すべてのビルド設定を出力
xcodebuild -showBuildSettings > build_settings.txt

# grep で特定の変数を検索
grep "SWIFT_" build_settings.txt
```

## 参考資料

- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [xcconfig Format Specification](https://help.apple.com/xcode/mac/current/#/dev745c5c974)
- [NSHipster - xcconfig](https://nshipster.com/xcconfig/)
- [Building from the Command Line with Xcode](https://developer.apple.com/library/archive/technotes/tn2339/)
