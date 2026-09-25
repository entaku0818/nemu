# コントリビューションガイド

## CI 方針

| チェック | 実行場所 | タイミング |
| --- | --- | --- |
| SwiftLint | GitHub Actions `ci.yml`（`ubuntu-latest`） | main への push / PR |
| Build | GitHub Actions `ios-ci.yml`（self-hosted runner: entaku の Mac, Xcode 27） | 全ブランチへの push / PR / 手動 |
| Test (`nemuTests`) | 同上 | 同上 |

- `ios-ci.yml` は `runs-on: [self-hosted, macOS, xcode27]`。専用シミュレータ `CI-nemu`（iOS 27.0）を使い、
  無ければ自動作成する。DerivedData は runner の作業ディレクトリ配下に置く
- フォークからの PR では実行しない（public リポジトリ + self-hosted runner のため）
- **GitHub-hosted の `macos-*` ランナーのジョブは追加しないこと**（Linux の10倍の課金レート。
  過去に追加 → コスト浪費と環境ドリフトによる赤化を招いた）。macOS が必要なジョブは self-hosted（`ios-ci.yml`）のみ可
- Xcode Cloud は使わない

## コミット前に実行するコマンド

以下がこのリポジトリのハーネス（検証ゲート）。**すべて緑にしてからコミット/PRする。**

### 1. Lint

```sh
cd ios/nemu && swiftlint lint
```

GitHub Actions でも同じチェックが走るので、ここが赤いと CI も赤くなる。

### 2. Build

```sh
xcodebuild build \
  -project ios/nemu/nemu.xcodeproj \
  -scheme nemu \
  -destination "platform=iOS Simulator,name=<Simulator名>" \
  CODE_SIGNING_ALLOWED=NO
```

### 3. Test

```sh
xcodebuild test \
  -project ios/nemu/nemu.xcodeproj \
  -scheme nemu \
  -destination "platform=iOS Simulator,name=<Simulator名>" \
  -only-testing:nemuTests \
  CODE_SIGNING_ALLOWED=NO
```

`<Simulator名>` は手元で利用可能なものに置き換える。一覧は次で確認できる:

```sh
xcrun simctl list devices available | grep iPhone
```

出力を読みやすくしたい場合は `| xcbeautify` を付ける（`brew install xcbeautify`）。

## 注意

- CI（`ios-ci.yml`）は push 後に走るため、**コミット前のローカル確認は引き続き必須**。
  「たぶん動く」でコミットしない。実際にコマンドを実行して緑を確認する
- self-hosted runner（entaku の Mac）がオフラインだと `ios-ci.yml` はキュー待ちになる
