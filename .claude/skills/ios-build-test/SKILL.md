---
name: ios-build-test
description: iOS/iPadOSプロジェクトのビルドとテストを実行します。Use when ユーザーが「ビルドして」「テスト実行して」「テストを走らせて」と言ったとき、またはiOSアプリのビルド・テストが必要なとき。
---

# iOS Build & Test

Xcodeプロジェクトのビルドとテストを自動化するスキルです。xcodebuildコマンドを使用して、プロジェクトのビルド、全テストの実行、または特定のテストケースのみの実行をサポートします。

## 指示

### Step 1: プロジェクト情報の確認

まず、プロジェクトの構造を確認します：

```bash
# .xcodeprojファイルを探す
find . -name "*.xcodeproj" -maxdepth 3

# スキーム一覧を確認
xcodebuild -list -project path/to/Project.xcodeproj
```

期待される出力: プロジェクトファイルのパスと利用可能なスキーム一覧

### Step 2: ビルドの実行

プロジェクトをビルドします：

```bash
xcodebuild -project path/to/Project.xcodeproj \
  -scheme YourScheme \
  -configuration Debug \
  build
```

**重要**:
- `-configuration` には `Debug` または `Release` を指定
- エラーが発生した場合は、ログの最後の部分を確認してエラー内容を特定

期待される出力: `BUILD SUCCEEDED` のメッセージ

### Step 3: テストの実行

#### 3a. 全テストを実行する場合

```bash
xcodebuild -project path/to/Project.xcodeproj \
  -scheme YourScheme \
  test \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

#### 3b. 特定のテストのみ実行する場合

```bash
xcodebuild -project path/to/Project.xcodeproj \
  -scheme YourScheme \
  test \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:YourTestTarget/TestClassName/testMethodName
```

期待される出力:
- テスト結果のサマリー
- `Test Suite 'All tests' passed`（成功時）
- 失敗したテストの詳細（失敗時）

### Step 4: 結果の確認

テスト結果を確認し、ユーザーに報告します：

- 成功したテストケース数
- 失敗したテストケースがあれば、その詳細
- ビルドエラーがあれば、その内容と修正方法の提案

---

## 使用例

### 例 1: プロジェクト全体のビルドとテスト

**ユーザーが言うこと**: "ビルドしてテスト実行して"

**実行されること**:
1. プロジェクトファイルとスキームを確認
2. Debugビルドを実行
3. 全テストをiPhone 16シミュレーターで実行
4. 結果をサマリーで報告

**結果**: ビルドが成功し、全テストが通ったことを確認。またはエラー内容を報告。

### 例 2: 特定のテストのみ実行

**ユーザーが言うこと**: "testSpeedConversionだけテストして"

**実行されること**:
1. テストターゲットとクラス名を特定
2. `-only-testing` オプションで該当テストのみ実行
3. 結果を報告

**結果**: 指定したテストケースの実行結果を報告。

### 例 3: リリースビルドの確認

**ユーザーが言うこと**: "Releaseビルドできるか確認して"

**実行されること**:
1. `-configuration Release` でビルド実行
2. ビルドログを確認
3. 成功/失敗を報告

**結果**: リリースビルドが問題なく完了したことを確認。

---

## トラブルシューティング

### エラー: `xcodebuild: error: Unable to find a destination matching the provided destination specifier`

**原因**: 指定したシミュレーターが利用できない

**解決方法**:
1. 利用可能なシミュレーターを確認: `xcrun simctl list devices`
2. 存在するデバイス名を使用する（例: iPhone 15, iPhone 16, iPad Pro など）
3. または `platform=iOS Simulator,OS=latest` を使用

### エラー: `Testing failed: Test target YourTestTarget encountered an error`

**原因**: テストコードのコンパイルエラーまたは依存関係の問題

**解決方法**:
1. エラーログの `error:` 部分を確認
2. 該当ファイルのコンパイルエラーを修正
3. 必要に応じて `xcodebuild clean` を実行してから再ビルド

### エラー: `Command PhaseScriptExecution failed with a nonzero exit code`

**原因**: ビルドスクリプトの実行失敗（SwiftLint、Code Generationなど）

**解決方法**:
1. ログで失敗したスクリプトを特定
2. スクリプトの内容を確認し、依存ツールがインストールされているか確認
3. 必要に応じてツールをインストール（例: `brew install swiftlint`）

---

## 参考資料

- Apple公式: [xcodebuild man page](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)
- より詳細なスクリプト例は `scripts/run-tests.sh` を参照

---

## 注意事項

- テスト実行にはシミュレーターが必要です（Xcodeのインストールが必須）
- 初回のテスト実行は、シミュレーターの起動に時間がかかる場合があります
- `-only-testing` オプションは `TargetName/ClassName/methodName` の形式で指定
- 複数のテストを指定する場合は、`-only-testing` を複数回使用可能
- ビルドに時間がかかる場合は、ユーザーに進捗状況を伝えることを推奨
