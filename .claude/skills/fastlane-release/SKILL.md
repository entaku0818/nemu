---
name: fastlane-release
description: xcodebuildとfastlaneでiOSアプリをビルド・アーカイブし、App Store/TestFlightに申請します。Use when ユーザーが「TestFlightにアップして」「App Storeに申請して」「リリースして」と言ったとき。
---

# Fastlane Release

コマンドラインでiOSアプリをビルド・アーカイブし、fastlaneでApp Store Connectにアップロード・審査申請するスキルです。

## ワークフロー概要

```
1. バージョン番号更新
   └─ MARKETING_VERSION & BUILD_NUMBER

2. xcodebuild でアーカイブ作成
   └─ Distribution証明書で署名

3. exportArchive で IPA 生成
   └─ App Store用にエクスポート

4. altool または fastlane でアップロード
   └─ App Store Connect に送信

5. fastlane deliver で審査申請
   └─ メタデータ + リリースノート更新
```

## 指示

### Step 1: バージョン番号の確認と更新

現在のバージョンを確認：

```bash
# project.pbxprojからバージョン確認
grep "MARKETING_VERSION = " project.pbxproj | head -1
grep "CURRENT_PROJECT_VERSION = " project.pbxproj | head -1
```

バージョン番号の更新（必要に応じて）：

```bash
# MARKETING_VERSION (例: 1.1.0 → 1.1.1)
sed -i '' 's/MARKETING_VERSION = 1\.1\.0;/MARKETING_VERSION = 1.1.1;/g' project.pbxproj

# BUILD_NUMBER は fastlane の increment_build_number で自動更新も可能
```

### Step 2: xcodebuild でアーカイブ作成

**重要**: fastlane gymではなくxcodebuildを直接使用することを推奨。fastlane gymは`xcodebuild -showBuildSettings`でタイムアウトする問題が発生することがあります。

```bash
cd iOS/speedmeter  # プロジェクトディレクトリ

xcodebuild archive \
  -project speedmeter.xcodeproj \
  -scheme speedmeter \
  -configuration Release \
  -archivePath build/speedmeter.xcarchive \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID
```

**重要なポイント**:
- ✅ `DEVELOPMENT_TEAM=YOUR_TEAM_ID` で自動署名を有効化
- ✅ `-allowProvisioningUpdates` でプロビジョニングプロファイルを自動更新
- ❌ `CODE_SIGN_IDENTITY` を手動指定すると自動署名と競合するため避ける
- ✅ Release configuration を使用

**Team ID の確認方法**:
```bash
# Distribution証明書からTeam IDを取得
security find-identity -v -p codesigning | grep "Apple Distribution"
# 出力例: Apple Distribution: Your Name (4YZQY4C47E)
#         ↑ このカッコ内がTeam ID
```

**エラー対処**:
- `Signing for "GoogleUtilities_GoogleUtilities-Network" requires a development team`
  → DEVELOPMENT_TEAM パラメータが必要
- `speedmeter has conflicting provisioning settings`
  → CODE_SIGN_IDENTITY を削除し、DEVELOPMENT_TEAM のみ使用

### Step 3: IPA のエクスポート

アーカイブから App Store 用 IPA を生成：

```bash
# ExportOptions.plist を作成
cat > build/AppStoreExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

# IPA をエクスポート
xcodebuild -exportArchive \
  -archivePath build/speedmeter.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist build/AppStoreExportOptions.plist \
  -allowProvisioningUpdates
```

**成功確認**:
```bash
ls -lh build/export/speedmeter.ipa
# 出力例: -rw-r--r--  1 user  staff   7.2M Feb  9 09:19 speedmeter.ipa
```

### Step 4: App Store Connect へアップロード

#### 方法A: altool でアップロード（推奨・シンプル）

```bash
cd build/export

xcrun altool --upload-app \
  --type ios \
  --file speedmeter.ipa \
  --apiKey YOUR_API_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID
```

**API Key の設定**:
1. App Store Connect > Users and Access > Keys タブ
2. "+" ボタンで新しいキー作成（Admin または App Manager 権限）
3. AuthKey_XXXXXXXX.p8 をダウンロード
4. Key ID と Issuer ID をメモ

**環境変数での管理（推奨）**:
```bash
# .env ファイルに保存
APP_STORE_CONNECT_API_KEY_KEY_ID=YOUR_API_KEY_ID
APP_STORE_CONNECT_API_KEY_ISSUER_ID=YOUR_ISSUER_ID
APP_STORE_CONNECT_API_KEY_CONTENT="-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
-----END PRIVATE KEY-----"
```

#### 方法B: fastlane upload_to_testflight

```bash
fastlane run upload_to_testflight \
  ipa:"build/export/speedmeter.ipa" \
  skip_waiting_for_build_processing:true
```

**成功メッセージ例**:
```
UPLOAD SUCCEEDED with no errors
Delivery UUID: ff765fc7-1daf-4b28-a749-b64b93a4ca05
Transferred 7523033 bytes in 2.122 seconds (3.5MB/s)
```

### Step 5: メタデータとリリースノートの準備

App Store 審査には**リリースノート（What's New）が必須**です。

```bash
# ディレクトリ構造
fastlane/metadata/
├── en-US/
│   ├── description.txt
│   ├── keywords.txt          # 最大100文字
│   ├── release_notes.txt     # 必須！
│   ├── name.txt
│   └── subtitle.txt
└── ja/
    ├── description.txt
    ├── keywords.txt          # 最大100文字
    ├── release_notes.txt     # 必須！
    ├── name.txt
    └── subtitle.txt
```

**リリースノートの作成**:
```bash
# 日本語版
cat > fastlane/metadata/ja/release_notes.txt << 'EOF'
アプリの検索性を向上させました。
軽微なバグ修正と改善を行いました。
EOF

# 英語版
cat > fastlane/metadata/en-US/release_notes.txt << 'EOF'
Improved app discoverability in search.
Minor bug fixes and improvements.
EOF
```

**キーワードの文字数制限**:
```bash
# キーワードが100文字以下か確認
echo -n "$(cat fastlane/metadata/en-US/keywords.txt)" | wc -c
# 出力例: 93 (100以下ならOK)
```

### Step 6: Fastfile の設定

App Store Connect API 認証を使用する Fastfile:

```ruby
require 'dotenv'
Dotenv.load

default_platform(:ios)

platform :ios do
  # 各レーンで共通して実行する認証処理
  before_all do
    app_store_connect_api_key(
      key_id: ENV["APP_STORE_CONNECT_API_KEY_KEY_ID"],
      issuer_id: ENV["APP_STORE_CONNECT_API_KEY_ISSUER_ID"],
      key_content: ENV["APP_STORE_CONNECT_API_KEY_CONTENT"]
    )
  end

  # 既にアップロード済みのビルドを審査提出
  desc "Submit already uploaded build for review"
  lane :submit_build do
    version_number = get_version_number(
      xcodeproj: "iOS/speedmeter/speedmeter.xcodeproj",
      target: "speedmeter"
    )

    deliver(
      skip_binary_upload: true,           # バイナリは既にアップロード済み
      skip_app_version_update: false,
      app_version: version_number,
      skip_metadata: false,               # メタデータをアップロード
      skip_screenshots: true,
      force: true,
      submit_for_review: true,            # 審査に提出
      automatic_release: false,           # 手動でリリース
      run_precheck_before_submit: false,
      precheck_include_in_app_purchases: false,
      ignore_language_directory_validation: true,
      submission_information: {
        add_id_info_uses_idfa: true,
        export_compliance_uses_encryption: false,
        export_compliance_platform: "ios"
      }
    )

    UI.success("Build submitted for review!")
  end
end
```

### Step 7: 審査申請の実行

```bash
# .env ファイルがプロジェクトルートにあることを確認
ls -la .env

# 審査申請を実行
fastlane submit_build
```

**成功メッセージ例**:
```
[09:24:31]: Successfully submitted the app for review!
[09:24:31]: Build submitted for review!
[09:24:31]: fastlane.tools finished successfully 🎉
```

**処理の流れ**:
1. App Store Connect API で認証
2. プロジェクトからバージョン番号取得（例: 1.1.1）
3. メタデータファイルを読み込み
   - description.txt
   - keywords.txt
   - release_notes.txt
4. ビルド処理待機（アップロード後10-30秒）
5. ビルドを選択（例: 1.1.1 - 10）
6. 審査に提出

### Step 8: Git での管理

リリースをバージョン管理：

```bash
# 変更をコミット
git add iOS/speedmeter/speedmeter.xcodeproj/project.pbxproj
git add fastlane/metadata
git commit -m "Release v1.1.1: Update metadata and submit to App Store

- Updated Japanese keywords (98 chars) for better discoverability
- Updated English keywords (93 chars) with relevant terms
- Added version 1.1.1 release notes (JP/EN)
- Build number incremented to 10
- Successfully uploaded and submitted for App Store review

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# タグを作成
git tag v1.1.1

# リモートにプッシュ
git push origin main
git push origin v1.1.1
```

---

## トラブルシューティング

### エラー: `xcodebuild -showBuildSettings timed out`

**原因**: fastlane gym が xcodebuild -showBuildSettings を実行してタイムアウト

**解決方法**: fastlane gym の代わりに xcodebuild を直接使用（Step 2参照）

```bash
# ❌ 避ける（タイムアウトする）
fastlane run build_app

# ✅ 推奨（直接実行）
xcodebuild archive ...
```

### エラー: `Signing for "speedmeter" has conflicting provisioning settings`

**原因**: CODE_SIGN_IDENTITY を手動指定して自動署名と競合

**解決方法**: CODE_SIGN_IDENTITY を削除し、DEVELOPMENT_TEAM のみ指定

```bash
# ❌ 避ける
xcodebuild archive ... CODE_SIGN_IDENTITY="Apple Distribution: ..."

# ✅ 推奨
xcodebuild archive ... DEVELOPMENT_TEAM=4YZQY4C47E
```

### エラー: `You must provide a value for the attribute 'whatsNew'`

**原因**: リリースノート（What's New）が未設定

**解決方法**: release_notes.txt を作成（Step 5参照）

```bash
# 各言語のリリースノートを作成
echo "軽微なバグ修正と改善を行いました。" > fastlane/metadata/ja/release_notes.txt
echo "Minor bug fixes and improvements." > fastlane/metadata/en-US/release_notes.txt
```

### エラー: `Keywords cannot be longer than 100 characters`

**原因**: キーワードが100文字を超えている

**解決方法**: キーワードを100文字以内に調整

```bash
# 文字数確認
echo -n "$(cat fastlane/metadata/en-US/keywords.txt)" | wc -c

# キーワードを編集して100文字以内に
# 例: speedometer,speed,GPS,car,bike,drive,cycling,workout,sport,navigation,odometer,hud
```

### エラー: `Precheck cannot check In-app purchases with API Key`

**原因**: App Store Connect API では IAP のプリチェックができない

**解決方法**: precheck を無効化

```ruby
deliver(
  run_precheck_before_submit: false,
  precheck_include_in_app_purchases: false,
  # ...
)
```

### エラー: `The version number has been previously used`

**原因**: バージョン番号が既に App Store Connect に存在

**解決方法**: バージョン番号をインクリメント

```bash
# 1.1.0 → 1.1.1 に変更
sed -i '' 's/MARKETING_VERSION = 1\.1\.0;/MARKETING_VERSION = 1.1.1;/g' project.pbxproj
```

### エラー: `Unauthorized Access` (2FA)

**原因**: 2要素認証が必要だが、非対話環境で実行している

**解決方法**: App Store Connect API キーを使用（Step 4参照）

```bash
# API認証を使用すると2FAが不要
xcrun altool --upload-app \
  --apiKey YOUR_API_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID \
  ...
```

---

## 完全なリリースフロー例

### シナリオ: v1.1.1 をリリース

```bash
# 1. バージョン更新
sed -i '' 's/MARKETING_VERSION = 1\.1\.0;/MARKETING_VERSION = 1.1.1;/g' iOS/speedmeter/speedmeter.xcodeproj/project.pbxproj

# 2. リリースノート作成
cat > fastlane/metadata/ja/release_notes.txt << 'EOF'
アプリの検索性を向上させました。
軽微なバグ修正と改善を行いました。
EOF

cat > fastlane/metadata/en-US/release_notes.txt << 'EOF'
Improved app discoverability in search.
Minor bug fixes and improvements.
EOF

# 3. アーカイブ作成
cd iOS/speedmeter
xcodebuild archive \
  -project speedmeter.xcodeproj \
  -scheme speedmeter \
  -configuration Release \
  -archivePath build/speedmeter.xcarchive \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=4YZQY4C47E

# 4. IPA エクスポート
xcodebuild -exportArchive \
  -archivePath build/speedmeter.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist build/AppStoreExportOptions.plist \
  -allowProvisioningUpdates

# 5. アップロード
cd build/export
xcrun altool --upload-app \
  --type ios \
  --file speedmeter.ipa \
  --apiKey YOUR_API_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID

# 6. 審査申請
cd ../..
fastlane submit_build

# 7. Git コミット
git add iOS/speedmeter/speedmeter.xcodeproj/project.pbxproj fastlane/metadata
git commit -m "Release v1.1.1: Update metadata and submit to App Store"
git tag v1.1.1
git push origin main && git push origin v1.1.1
```

---

## チェックリスト

リリース前に確認：

### ビルド前
- [ ] バージョン番号を更新（MARKETING_VERSION）
- [ ] ビルド番号を更新（CURRENT_PROJECT_VERSION）
- [ ] リリースノートを作成（全言語）
- [ ] キーワードが100文字以内（全言語）
- [ ] Distribution 証明書が有効
- [ ] Team ID を確認

### ビルド
- [ ] xcodebuild archive が成功
- [ ] .xcarchive が作成された
- [ ] xcodebuild -exportArchive が成功
- [ ] .ipa が作成された（7-15MB程度）

### アップロード
- [ ] altool upload が成功
- [ ] Delivery UUID を取得
- [ ] App Store Connect でビルド確認

### 審査申請
- [ ] fastlane submit_build が成功
- [ ] "Successfully submitted" メッセージ確認
- [ ] App Store Connect で "審査待ち" 表示

### Git管理
- [ ] project.pbxproj をコミット
- [ ] メタデータファイルをコミット
- [ ] バージョンタグを作成
- [ ] リモートにプッシュ

---

## 参考資料

- **xcodebuild マニュアル**: `man xcodebuild`
- **fastlane deliver**: https://docs.fastlane.tools/actions/deliver/
- **App Store Connect API**: https://developer.apple.com/documentation/appstoreconnectapi
- **altool**: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow

---

## 注意事項

### 必須要件
- ✅ Apple Developer Program アカウント（年間 $99）
- ✅ Xcode インストール済み
- ✅ Distribution 証明書とプロビジョニングプロファイル
- ✅ App Store Connect API キー（推奨）

### 重要なポイント
- **xcodebuild を直接使用** - fastlane gym のタイムアウト問題を回避
- **DEVELOPMENT_TEAM を指定** - CODE_SIGN_IDENTITY との競合を避ける
- **リリースノートは必須** - 全言語で release_notes.txt を作成
- **キーワードは100文字以内** - 超過すると審査申請が失敗
- **API 認証を使用** - 2要素認証の問題を回避

### タイムライン
- **アーカイブ**: 1-3分
- **エクスポート**: 30秒-1分
- **アップロード**: 2-5分（ファイルサイズによる）
- **ビルド処理**: 10-30秒
- **審査申請**: 1-2分
- **App Store レビュー**: 1-3日（通常）
