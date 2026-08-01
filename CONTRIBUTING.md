# コントリビューションガイド

## CI 方針

**GitHub Actions で実行するのは ubuntu 上の軽量チェック（SwiftLint）のみ。**
iOS の build / test は GitHub Actions では実行しない。**コミット前にローカルで確認する運用**。

| チェック | 実行場所 | タイミング |
| --- | --- | --- |
| SwiftLint | GitHub Actions (`ubuntu-latest`) | push / PR で自動 |
| Build | ローカル | コミット前に手動 |
| Test (`nemuTests`) | ローカル | コミット前に手動 |

### なぜ macOS ランナーを使わないか

- macOSランナーは Linux ランナーに対して課金レートが 10倍。`xcodebuild build` + `test` を
  push / PR ごとにフル実行するとコストが大きい
- シミュレータ名・Xcodeバージョンのドリフト（`iPhone 16` が消える、SDKが上がる等）で
  プロダクトコードと無関係に赤くなり、ゲートとしての信頼性が低い

`.github/workflows/ci.yml` に macOS ランナーのジョブを追加しないこと。
過去に2回追加され、いずれもコスト浪費と環境ドリフトによる赤化を招いている
（`b6529ae` で削除 → `75b0ff4` で再追加 → 2026-07-20 に複数回失敗）。

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

- build / test は CI が見ていないため、**ローカルハーネスが唯一のゲート**になる。
  「たぶん動く」でコミットしない。実際にコマンドを実行して緑を確認する
- CLAUDE.md の「緑でない変更を main に入れない」はこの前提で読むこと
