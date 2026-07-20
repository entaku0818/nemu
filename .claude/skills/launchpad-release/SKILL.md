---
name: launchpad-release
description: xcodebuildとlaunchpad CLIでiOSアプリをビルド・アーカイブし、App Store/TestFlightに申請します（旧fastlaneから移行済み、issue #23）。Use when ユーザーが「TestFlightにアップして」「App Storeに申請して」「リリースして」と言ったとき。
---

# Launchpad Release

nemu（Slumber）をビルド・アーカイブし、[launchpad](https://github.com/entaku0818/launchpad) CLI（entaku0818 自作のfastlane代替ツール）で App Store Connect へアップロード・審査申請するスキルです。以前は fastlane（Fastfile/Appfile）を使っていましたが issue #23 で launchpad に移行しました。

## 前提

- `launchpad` コマンドがインストール済みであること。未インストールなら:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/entaku0818/launchpad/main/install.sh | sh
  ```
- `ios/nemu/.launchpadrc`（プロジェクト設定）・`ios/nemu/.env`（App Store Connect API認証情報、gitignore対象）が設定済み
- 動作確認（読み取り専用・安全に実行可）:
  ```bash
  cd ios/nemu && launchpad doctor
  ```
  Android関連の警告は nemu が iOS 専用アプリのため無視してよい。

## ワークフロー概要

```
1. バージョン番号更新
   └─ project.pbxproj の MARKETING_VERSION / CURRENT_PROJECT_VERSION

2. launchpad ios build
   └─ アーカイブ作成 + IPAエクスポートを一括実行（.launchpadrc の scheme/exportMethod を使用）

3. launchpad ios upload
   └─ TestFlight / App Store へアップロード

4. launchpad ios metadata / launchpad ios screenshots
   └─ fastlane/metadata/, fastlane/screenshots/ をそのまま利用（互換ディレクトリ、リネーム不要）

5. launchpad ios submit
   └─ 審査提出
```

## 指示

### Step 1: バージョン番号の確認と更新

```bash
cd ios/nemu
grep "MARKETING_VERSION = " nemu.xcodeproj/project.pbxproj | head -1
grep "CURRENT_PROJECT_VERSION = " nemu.xcodeproj/project.pbxproj | head -1
```

更新は `sed` で直接編集するか、`launchpad ios version-bump` を使う（`agvtool` が必要。未インストール環境では sed 編集を推奨）。

```bash
sed -i '' 's/MARKETING_VERSION = 1\.1;/MARKETING_VERSION = 1.2;/g' nemu.xcodeproj/project.pbxproj
```

### Step 2: ビルド・アーカイブ・IPAエクスポート

```bash
cd ios/nemu
launchpad ios build
```

`.launchpadrc` の `ios.project`/`ios.scheme`/`ios.output`/`ios.exportMethod` を使ってアーカイブ〜エクスポートまで一括実行します（出力先: `build/export/`）。個別に上書きしたい場合は `--project`/`--scheme`/`--output`/`--export-method` を指定。

### Step 3: TestFlightへアップロード

```bash
launchpad ios upload
```

`.launchpadrc` の `ios.scheme` からビルド出力のIPAパスを自動解決します。別のIPAを使う場合は `--ipa <path>` を指定。

### Step 4: メタデータ・スクリーンショットの反映

```bash
# fastlane/metadata/ の内容をApp Store Connectに反映
launchpad ios metadata

# fastlane/screenshots/ のスクリーンショットをアップロード
launchpad ios screenshots
launchpad ios screenshots --overwrite   # 既存を削除してから上書き
```

### Step 5: 審査提出

```bash
launchpad ios submit
```

`--version` を省略すると xcodeproj から自動取得されます。

### ワンショット実行

```bash
# ビルド → アップロード → 審査提出を一括実行
launchpad release --ios

# 何が実行されるかだけ確認（実行はしない）
launchpad release --ios --dry-run

# ビルド済みのIPAがある場合はビルドをスキップ
launchpad release --ios --skip-build
```

### Git での管理

```bash
git add ios/nemu/nemu.xcodeproj/project.pbxproj ios/nemu/fastlane/metadata
git commit -m "Release v1.2.0: メタデータ更新・App Store申請"
git tag v1.2.0
git push origin main && git push origin v1.2.0
```

## 注意事項

- **実際のTestFlightアップロード・審査提出は本番のApp Store Connectを操作する。ユーザーの明示的な依頼なしに自動実行しない。**
- リリースノート（What's New）は `fastlane/metadata/{locale}/release_notes.txt` に必須。`launchpad release-notes` で git ログから自動生成もできる。
- キーワードは100バイト以内（超過すると審査申請が失敗する）:
  ```bash
  echo -n "$(cat fastlane/metadata/ja/keywords.txt)" | wc -c
  ```

## トラブルシューティング

### `agvtool: command not found`
`launchpad ios version-bump` は agvtool に依存。未インストールなら Step 1 の sed 編集で代替する。

### `KEY_CONTENT invalid PEM`（`launchpad doctor` で検出）
`.env` の `APP_STORE_CONNECT_API_KEY_CONTENT` の改行が `\n` エスケープされ1行になっているか確認する。

### `You must provide a value for the attribute 'whatsNew'`
リリースノートが未設定。`fastlane/metadata/{locale}/release_notes.txt` を作成する。

### `The version number has been previously used`
バージョン番号が既に App Store Connect に存在する。`project.pbxproj` の `MARKETING_VERSION` をインクリメントする。

## 参考資料

- [launchpad README](https://github.com/entaku0818/launchpad) — 全コマンドリファレンス（ローカルクローン: `~/repository/launchpad`）
- App Store Connect API: https://developer.apple.com/documentation/appstoreconnectapi
