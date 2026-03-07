# SwiftUI アーキテクチャガイド

このガイドでは、SwiftUI アプリケーションの推奨アーキテクチャパターンとベストプラクティスを解説します。

## 基本原則

### 1. 単一責任の原則（Single Responsibility Principle）

各 View、Manager、Model は1つの責任のみを持つべきです。

```swift
// ❌ 悪い例: 1つのViewが多くの責任を持つ
struct DashboardView: View {
    @State private var users: [User] = []
    @State private var posts: [Post] = []
    @State private var analytics: Analytics?

    var body: some View {
        // 複雑なUI...
    }

    func fetchUsers() { }
    func fetchPosts() { }
    func fetchAnalytics() { }
}

// ✅ 良い例: 責任を分離
struct DashboardView: View {
    var body: some View {
        VStack {
            UserListView()
            PostListView()
            AnalyticsView()
        }
    }
}

struct UserListView: View {
    @StateObject private var manager = UserManager()
    // ...
}
```

### 2. データフローの一方向性

データは上位から下位へ、イベントは下位から上位へ流れるべきです。

```
親View
  ├─ @State / @StateObject（データの所有者）
  │
  └─> 子View
       ├─ データを受け取る（@Binding, @ObservedObject）
       └─ イベントをクロージャーで通知
```

## State Management パターン

### パターン1: @State（ローカル状態）

**使用ケース**: View 内で完結する簡単な状態

```swift
struct ToggleView: View {
    @State private var isOn = false

    var body: some View {
        Toggle("Enable", isOn: $isOn)
    }
}
```

**特徴**:
- ✅ シンプル
- ✅ View のライフサイクルに紐づく
- ❌ 他の View と共有できない

### パターン2: @StateObject + ObservableObject

**使用ケース**: 複雑な状態管理、ビジネスロジックの分離

```swift
// Manager
@MainActor
class WeatherManager: ObservableObject {
    @Published var temperature: Double = 0
    @Published var isLoading = false

    func fetchWeather() async {
        isLoading = true
        // API呼び出し
        isLoading = false
    }
}

// View
struct WeatherView: View {
    @StateObject private var manager = WeatherManager()

    var body: some View {
        VStack {
            if manager.isLoading {
                ProgressView()
            } else {
                Text("\(manager.temperature)°C")
            }
        }
        .task {
            await manager.fetchWeather()
        }
    }
}
```

**特徴**:
- ✅ テストしやすい
- ✅ ビジネスロジックを分離
- ✅ 複雑な状態を管理できる
- ❌ 少しボイラープレートが増える

### パターン3: @ObservedObject（親から受け取る）

**使用ケース**: 親 View が所有する Manager を子 View で使う

```swift
struct ParentView: View {
    @StateObject private var manager = WeatherManager()

    var body: some View {
        VStack {
            TemperatureView(manager: manager)
            HumidityView(manager: manager)
        }
    }
}

struct TemperatureView: View {
    @ObservedObject var manager: WeatherManager

    var body: some View {
        Text("\(manager.temperature)°C")
    }
}
```

**特徴**:
- ✅ 親子で状態を共有
- ✅ 親がライフサイクルを管理
- ❌ 親への依存が生まれる

### パターン4: Singleton（グローバル状態）

**使用ケース**: アプリ全体で共有する状態

```swift
class LocationManager: ObservableObject {
    static let shared = LocationManager()

    @Published var location: CLLocation?

    private init() {
        // 初期化
    }

    func startUpdating() {
        // 位置情報の更新開始
    }
}

struct MapView: View {
    @ObservedObject var locationManager = LocationManager.shared

    var body: some View {
        Map(coordinateRegion: .constant(...))
    }
}
```

**特徴**:
- ✅ どこからでもアクセス可能
- ✅ 状態を1箇所で管理
- ❌ テストが難しい
- ❌ 依存関係が見えにくい

### パターン5: @EnvironmentObject（依存性注入）

**使用ケース**: アプリ全体の設定、テーマなど

```swift
class AppSettings: ObservableObject {
    @Published var isDarkMode = false
    @Published var fontSize: Double = 16
}

@main
struct MyApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Text("Hello")
            .font(.system(size: settings.fontSize))
    }
}
```

**特徴**:
- ✅ 明示的な渡しが不要
- ✅ 深い階層でも簡単にアクセス
- ✅ テスト時に差し替え可能
- ❌ 暗黙的な依存関係

## アーキテクチャパターン

### MVVM (Model-View-ViewModel)

SwiftUI で最も推奨されるパターン。

```
┌─────────────┐
│    View     │ SwiftUI View
│  (UI Layer) │
└──────┬──────┘
       │ @StateObject / @ObservedObject
       │
┌──────▼──────────┐
│   ViewModel     │ ObservableObject
│ (Presentation)  │ @Published properties
└──────┬──────────┘
       │
┌──────▼──────┐
│    Model    │ Data structures
│ (Data Layer)│
└─────────────┘
```

**実装例**:

```swift
// Model
struct Article: Identifiable, Codable {
    let id: Int
    let title: String
    let content: String
}

// ViewModel
@MainActor
class ArticleListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let apiService: APIService

    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    func loadArticles() async {
        isLoading = true
        error = nil

        do {
            articles = try await apiService.fetchArticles()
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

// View
struct ArticleListView: View {
    @StateObject private var viewModel = ArticleListViewModel()

    var body: some View {
        List(viewModel.articles) { article in
            ArticleRow(article: article)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadArticles()
        }
        .alert(item: $viewModel.error) { error in
            Alert(title: Text("Error"), message: Text(error.localizedDescription))
        }
    }
}
```

### Repository パターン

データ取得を抽象化し、テストしやすくする。

```swift
protocol ArticleRepository {
    func fetchArticles() async throws -> [Article]
    func fetchArticle(id: Int) async throws -> Article
}

class APIArticleRepository: ArticleRepository {
    func fetchArticles() async throws -> [Article] {
        // API 実装
    }

    func fetchArticle(id: Int) async throws -> Article {
        // API 実装
    }
}

class MockArticleRepository: ArticleRepository {
    func fetchArticles() async throws -> [Article] {
        // モックデータを返す
        return [
            Article(id: 1, title: "Test", content: "Content")
        ]
    }

    func fetchArticle(id: Int) async throws -> Article {
        return Article(id: id, title: "Test", content: "Content")
    }
}

// ViewModel
@MainActor
class ArticleListViewModel: ObservableObject {
    private let repository: ArticleRepository

    init(repository: ArticleRepository = APIArticleRepository()) {
        self.repository = repository
    }

    func loadArticles() async {
        do {
            articles = try await repository.fetchArticles()
        } catch {
            self.error = error
        }
    }
}
```

## ディレクトリ構造

### 推奨構造（機能ベース）

```
YourApp/
├── App/
│   ├── YourAppApp.swift
│   └── ContentView.swift
│
├── Features/
│   ├── Dashboard/
│   │   ├── Views/
│   │   │   ├── DashboardView.swift
│   │   │   └── DashboardItemView.swift
│   │   ├── ViewModels/
│   │   │   └── DashboardViewModel.swift
│   │   └── Models/
│   │       └── DashboardItem.swift
│   │
│   ├── Profile/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   │
│   └── Settings/
│       └── Views/
│           └── SettingsView.swift
│
├── Shared/
│   ├── Components/
│   │   ├── LoadingView.swift
│   │   └── ErrorView.swift
│   ├── Managers/
│   │   └── LocationManager.swift
│   ├── Services/
│   │   └── APIService.swift
│   └── Extensions/
│       ├── View+Extensions.swift
│       └── Color+Extensions.swift
│
├── Models/
│   ├── User.swift
│   └── APIResponse.swift
│
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### 代替構造（レイヤーベース）

```
YourApp/
├── Presentation/
│   ├── Views/
│   └── ViewModels/
├── Domain/
│   ├── Models/
│   └── UseCases/
├── Data/
│   ├── Repositories/
│   └── Services/
└── Resources/
```

## ベストプラクティス

### 1. View の分割

**ルール**: View のコードが100行を超えたら分割を検討

```swift
// ❌ 悪い例: 1つのViewに全て詰め込む
struct ProfileView: View {
    var body: some View {
        VStack {
            // ヘッダー（50行）
            // プロフィール情報（100行）
            // 設定セクション（50行）
            // フッター（30行）
        }
    }
}

// ✅ 良い例: 責任ごとに分割
struct ProfileView: View {
    var body: some View {
        ScrollView {
            ProfileHeaderView()
            ProfileInfoView()
            ProfileSettingsView()
            ProfileFooterView()
        }
    }
}
```

### 2. @MainActor の使用

UI更新はメインスレッドで行う必要があるため、`@MainActor` を明示的に付ける。

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var data: [Item] = []

    func loadData() async {
        // 自動的にメインスレッドで実行される
        data = await fetchData()
    }
}
```

### 3. Preview の活用

開発効率を上げるために、必ず Preview を作成。

```swift
#Preview("Default") {
    ArticleListView()
}

#Preview("Loading") {
    ArticleListView()
        .onAppear {
            // ローディング状態をシミュレート
        }
}

#Preview("Error") {
    ArticleListView()
        .onAppear {
            // エラー状態をシミュレート
        }
}
```

### 4. Dependency Injection

テストしやすくするため、依存関係は外部から注入。

```swift
// ❌ 悪い例: 直接依存
class ViewModel: ObservableObject {
    private let api = APIService()  // ハードコーディング
}

// ✅ 良い例: 注入可能
class ViewModel: ObservableObject {
    private let api: APIService

    init(api: APIService = .shared) {
        self.api = api
    }
}

// テストで差し替え可能
let mockAPI = MockAPIService()
let viewModel = ViewModel(api: mockAPI)
```

### 5. エラーハンドリング

ユーザーにフィードバックを提供する。

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var error: AppError?

    func loadData() async {
        do {
            try await fetchData()
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = .unknown(error)
        }
    }
}

enum AppError: LocalizedError, Identifiable {
    case networkError
    case unauthorized
    case unknown(Error)

    var id: String {
        errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unauthorized:
            return "認証が必要です"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
```

## パフォーマンス最適化

### 1. 不要な再描画を避ける

```swift
// ❌ 悪い例: 親Viewの変更で子も再描画
struct ParentView: View {
    @State private var counter = 0

    var body: some View {
        VStack {
            Text("\(counter)")
            ChildView()  // counter変更で再描画される
        }
    }
}

// ✅ 良い例: Equatableで最適化
struct ChildView: View, Equatable {
    static func == (lhs: ChildView, rhs: ChildView) -> Bool {
        true  // 常に同じ
    }

    var body: some View {
        Text("Child")
    }
}

// 使用時
.equatable()  // 追加
```

### 2. LazyStack の使用

大量のデータは LazyVStack/LazyHStack を使用。

```swift
// ✅ 画面に表示される分だけ描画
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### 3. Task の適切な管理

```swift
struct ArticleView: View {
    @StateObject private var viewModel = ArticleViewModel()

    var body: some View {
        // ...
        .task {
            await viewModel.loadArticles()
        }
        // Viewが消えると自動的にキャンセルされる
    }
}
```

## テストのベストプラクティス

### ViewModel のテスト

```swift
@MainActor
final class ArticleViewModelTests: XCTestCase {
    var viewModel: ArticleViewModel!
    var mockRepository: MockArticleRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockArticleRepository()
        viewModel = ArticleViewModel(repository: mockRepository)
    }

    func testLoadArticles() async {
        await viewModel.loadArticles()

        XCTAssertEqual(viewModel.articles.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }

    func testLoadArticlesError() async {
        mockRepository.shouldFail = true

        await viewModel.loadArticles()

        XCTAssertTrue(viewModel.articles.isEmpty)
        XCTAssertNotNil(viewModel.error)
    }
}
```

## 参考リンク

- [Apple - SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [WWDC - Data Essentials in SwiftUI](https://developer.apple.com/videos/play/wwdc2020/10040/)
- [Point-Free - Modern SwiftUI](https://www.pointfree.co/collections/swiftui)
