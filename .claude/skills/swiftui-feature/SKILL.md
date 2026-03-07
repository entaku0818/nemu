---
name: swiftui-feature
description: SwiftUIアプリに新機能を追加します。Use when ユーザーが「新しい画面追加して」「機能実装して」「Viewを作って」と言ったとき。
---

# SwiftUI Feature

SwiftUI アプリに新機能を追加する際の定型フローを提供するスキルです。View、ViewModel/Manager、State Management、テストコードの追加をベストプラクティスに従って実装します。

## アーキテクチャパターン

このスキルは、以下のパターンをサポートします：

```
1. View + ObservableObject パターン
   View.swift
   └─ @StateObject var manager: FeatureManager

2. View + Singleton パターン
   View.swift
   └─ @ObservedObject var store: FeatureStore.shared

3. View + @State パターン（シンプルな画面用）
   View.swift
   └─ @State private var data

4. View + Environment パターン
   View.swift
   └─ @EnvironmentObject var settings: AppSettings
```

## 指示

### Step 1: 既存のアーキテクチャを確認

プロジェクトの既存パターンを確認：

```bash
# プロジェクト構造を確認
find . -name "*.swift" -type f | grep -E "(View|Manager|Store)" | head -20

# 既存のStateパターンを確認
grep -r "@StateObject\|@ObservedObject\|@EnvironmentObject" --include="*.swift" | head -10
```

**確認事項**:
- ✅ 既存の View の命名規則
- ✅ Manager/Store の配置場所
- ✅ State Management のパターン
- ✅ ディレクトリ構造

### Step 2: 機能の要件を整理

ユーザーと以下を確認：

1. **機能の目的**: 何をする画面/機能か
2. **データソース**: どこからデータを取得するか
   - API呼び出し
   - CoreData/UserDefaults
   - Singleton
   - 親Viewから渡される
3. **状態管理**: どのパターンを使うか
   - `@StateObject` - View が Manager を所有
   - `@ObservedObject` - 親から渡される
   - Singleton パターン - 共有状態
4. **ナビゲーション**: どこから遷移するか
   - Tab
   - Sheet/FullScreenCover
   - NavigationLink
   - 既存画面に統合

### Step 3: ファイル構造の作成

#### 3a. 基本的なView（@State パターン）

シンプルな画面の場合：

```swift
// Views/FeatureView.swift
import SwiftUI

struct FeatureView: View {
    @State private var data: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                Text(data)
            }
        }
        .navigationTitle("Feature")
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // データ取得ロジック
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        data = "Loaded"
    }
}

#Preview {
    NavigationStack {
        FeatureView()
    }
}
```

#### 3b. ObservableObject パターン

複雑な状態管理が必要な場合：

```swift
// Managers/FeatureManager.swift
import Foundation
import Combine

@MainActor
class FeatureManager: ObservableObject {
    @Published var data: [Item] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // データ取得ロジック
            try await Task.sleep(nanoseconds: 1_000_000_000)
            data = [Item(id: 1, name: "Item 1")]
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func addItem(_ item: Item) {
        data.append(item)
    }

    func deleteItem(at offsets: IndexSet) {
        data.remove(atOffsets: offsets)
    }
}

// Models/Item.swift
struct Item: Identifiable {
    let id: Int
    var name: String
}
```

```swift
// Views/FeatureView.swift
import SwiftUI

struct FeatureView: View {
    @StateObject private var manager = FeatureManager()

    var body: some View {
        List {
            ForEach(manager.data) { item in
                Text(item.name)
            }
            .onDelete(perform: manager.deleteItem)
        }
        .navigationTitle("Feature")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", action: addItem)
            }
        }
        .task {
            await manager.loadData()
        }
        .overlay {
            if manager.isLoading {
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(manager.errorMessage != nil)) {
            Button("OK") { manager.errorMessage = nil }
        } message: {
            if let error = manager.errorMessage {
                Text(error)
            }
        }
    }

    private func addItem() {
        let newItem = Item(id: manager.data.count + 1, name: "New Item")
        manager.addItem(newItem)
    }
}
```

#### 3c. Singleton パターン

アプリ全体で共有する状態の場合：

```swift
// Stores/FeatureStore.swift
import Foundation
import Combine

class FeatureStore: ObservableObject {
    static let shared = FeatureStore()

    @Published var items: [Item] = []

    private init() {
        loadFromUserDefaults()
    }

    func addItem(_ item: Item) {
        items.append(item)
        saveToUserDefaults()
    }

    private func loadFromUserDefaults() {
        // UserDefaults からロード
    }

    private func saveToUserDefaults() {
        // UserDefaults に保存
    }
}
```

```swift
// Views/FeatureView.swift
struct FeatureView: View {
    @ObservedObject var store = FeatureStore.shared

    var body: some View {
        List(store.items) { item in
            Text(item.name)
        }
    }
}
```

### Step 4: 既存画面への統合

#### 4a. TabViewに追加

```swift
// MainTabView.swift
TabView {
    ExistingView()
        .tabItem {
            Label("Existing", systemImage: "house")
        }

    FeatureView()  // 新しく追加
        .tabItem {
            Label("Feature", systemImage: "star")
        }
}
```

#### 4b. NavigationLinkで遷移

```swift
NavigationStack {
    List {
        NavigationLink("Go to Feature") {
            FeatureView()
        }
    }
}
```

#### 4c. Sheetで表示

```swift
struct ParentView: View {
    @State private var showFeature = false

    var body: some View {
        Button("Show Feature") {
            showFeature = true
        }
        .sheet(isPresented: $showFeature) {
            FeatureView()
        }
    }
}
```

### Step 5: テストの追加

```swift
// Tests/FeatureManagerTests.swift
import XCTest
@testable import YourApp

@MainActor
final class FeatureManagerTests: XCTestCase {
    var manager: FeatureManager!

    override func setUp() {
        super.setUp()
        manager = FeatureManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testLoadData() async {
        // 初期状態
        XCTAssertEqual(manager.data.count, 0)
        XCTAssertFalse(manager.isLoading)

        // データロード
        await manager.loadData()

        // 結果確認
        XCTAssertGreaterThan(manager.data.count, 0)
        XCTAssertFalse(manager.isLoading)
    }

    func testAddItem() {
        let item = Item(id: 1, name: "Test")
        manager.addItem(item)

        XCTAssertEqual(manager.data.count, 1)
        XCTAssertEqual(manager.data.first?.name, "Test")
    }

    func testDeleteItem() {
        manager.addItem(Item(id: 1, name: "Item 1"))
        manager.addItem(Item(id: 2, name: "Item 2"))

        manager.deleteItem(at: IndexSet(integer: 0))

        XCTAssertEqual(manager.data.count, 1)
        XCTAssertEqual(manager.data.first?.name, "Item 2")
    }
}
```

### Step 6: 動作確認

```bash
# ビルドして実行
xcodebuild -project YourApp.xcodeproj -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 16' build

# テスト実行
xcodebuild -project YourApp.xcodeproj -scheme YourApp test -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## 使用例

### 例 1: シンプルな設定画面を追加

**ユーザーが言うこと**: "設定画面を追加して"

**実行されること**:
1. 既存の Settings 関連ファイルを確認
2. `SettingsView.swift` を作成（@State パターン）
3. TabView に追加
4. Preview で動作確認

**結果**: タブに設定画面が追加され、基本的な設定項目が表示される

### 例 2: データ取得を伴う一覧画面

**ユーザーが言うこと**: "ユーザー一覧画面を作って、APIからデータ取得する"

**実行されること**:
1. `Models/User.swift` を作成
2. `Managers/UserManager.swift` を作成（ObservableObject）
3. `Views/UserListView.swift` を作成
4. API呼び出しロジックを実装
5. テストコード `UserManagerTests.swift` を作成

**結果**: APIからユーザーデータを取得して一覧表示する画面が完成

### 例 3: アプリ全体で共有する状態

**ユーザーが言うこと**: "お気に入り機能を追加して、どの画面からでもアクセスできるようにして"

**実行されること**:
1. `Stores/FavoriteStore.swift` を Singleton で作成
2. UserDefaults で永続化
3. 既存の各 View に「お気に入り追加」ボタンを追加
4. `FavoriteListView.swift` を作成
5. テストコードを追加

**結果**: アプリ全体でお気に入り状態が共有され、どの画面からでもアクセス可能

### 例 4: 既存機能の拡張

**ユーザーが言うこと**: "SpeedView にダークモード切り替えを追加して"

**実行されること**:
1. 既存の `SpeedView.swift` を確認
2. `@AppStorage` でダークモード設定を管理
3. Toggle UI を追加
4. `.preferredColorScheme()` で反映

**結果**: SpeedView にダークモード切り替えが追加される

---

## トラブルシューティング

### エラー: `Cannot find 'FeatureManager' in scope`

**原因**: Manager ファイルが Target に追加されていない

**解決方法**:
1. Xcode で該当ファイルを選択
2. File Inspector（右側パネル）を開く
3. "Target Membership" でアプリのターゲットにチェック
4. Clean Build Folder（Cmd+Shift+K）してリビルド

### エラー: `@StateObject` 初期化エラー

**原因**: `@StateObject` は定数（let）または初期値が必要

**解決方法**:
```swift
// ❌ 間違い
@StateObject var manager: FeatureManager

// ✅ 正しい
@StateObject private var manager = FeatureManager()
```

### 問題: Preview が動かない

**原因**: Preview で必要な依存関係が不足

**解決方法**:
```swift
#Preview {
    NavigationStack {
        FeatureView()
            .environmentObject(AppSettings.shared)  // 必要な Environment を追加
    }
}
```

### 問題: @Published の変更が UI に反映されない

**原因**: メインスレッドで更新されていない

**解決方法**:
```swift
@MainActor
class FeatureManager: ObservableObject {
    @Published var data: [Item] = []

    func loadData() async {
        // @MainActor により自動的にメインスレッドで実行される
        data = await fetchData()
    }
}
```

### 問題: Singleton の状態が保存されない

**原因**: UserDefaults への保存タイミングが適切でない

**解決方法**:
```swift
class FeatureStore: ObservableObject {
    @Published var items: [Item] = [] {
        didSet {
            saveToUserDefaults()  // 変更時に自動保存
        }
    }
}
```

---

## 参考資料

- 詳細なアーキテクチャガイドは `references/architecture-guide.md` を参照
- **SwiftUI公式ドキュメント**: [developer.apple.com/documentation/swiftui](https://developer.apple.com/documentation/swiftui/)
- **State and Data Flow**: [Managing Model Data](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- **Testing**: [Testing SwiftUI Views](https://developer.apple.com/videos/play/wwdc2023/10102/)

---

## 注意事項

### State Management の選び方

| パターン | 使用ケース | 例 |
|---------|----------|---|
| `@State` | View 内で完結する簡単な状態 | Toggle、TextField の値 |
| `@StateObject` | View が所有する複雑な状態 | API Manager、Form Manager |
| `@ObservedObject` | 親から渡される状態 | 共有 Manager |
| `@EnvironmentObject` | アプリ全体で共有する設定 | Theme、User Session |
| Singleton | アプリ全体で永続化する状態 | UserDefaults ベースの Store |

### ベストプラクティス

- ✅ **1つの View につき1つの責任** - 複雑になったら分割
- ✅ **@MainActor を明示** - UI更新は必ずメインスレッド
- ✅ **Preview を必ず作成** - 開発効率が大幅に向上
- ✅ **async/await を使用** - コールバック地獄を避ける
- ✅ **エラーハンドリングを忘れずに** - ユーザーにフィードバック

### 避けるべきパターン

- ❌ **View に直接 API 呼び出し** - Manager に分離
- ❌ **複雑な @State のネスト** - ObservableObject を使用
- ❌ **Singleton の乱用** - 本当に共有が必要か検討
- ❌ **テストなしで複雑なロジック** - 最低限のテストを追加
- ❌ **メインスレッド以外での UI 更新** - クラッシュの原因

### パフォーマンス

- `@Published` は変更時に View を再描画するため、頻繁に変わる値は注意
- リスト表示は `ForEach` + `Identifiable` を使用
- 重い計算は `@State` の `didSet` や computed property は避け、専用メソッドで実行
- 画像のロードは `AsyncImage` を使用

### アクセシビリティ

- `.accessibilityLabel()` でラベルを追加
- `.accessibilityHint()` で操作のヒントを追加
- ボタンは十分なタップエリアを確保（最低44x44pt）
