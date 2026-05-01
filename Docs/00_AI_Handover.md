# PayMap - AI引き継ぎ用マスタードキュメント

**作成日**: 2026-05-01  
**プロジェクトリポジトリ**: `/Users/youki/SourceCSN/paymap`  
**対象**: 次に開発を引き継ぐ生成AIへの完全な引き継ぎ情報

---

## 1. プロジェクト概要

### アプリのコンセプト
飲食店・コンビニ・自動販売機などの店舗で「どの決済手段が使えるか」をGoogleマップ上に可視化するiOSアプリ。
情報はユーザーが協力して登録・更新するクラウドソーシング型。複数ユーザーの申請が **80%以上一致した時点** でその決済手段を有効化するコンセンサス方式を採用する。

### 基本情報

| 項目 | 内容 |
|---|---|
| **アプリ名** | PayMap |
| **Bundle ID** | `com.csn.Paymap` |
| **ターゲット** | iOS 16.0 以上 / 専用 |
| **言語** | Swift / SwiftUI |
| **アーキテクチャ** | MVVM |
| **バックエンド** | Firebase (無料枠) |
| **地図** | Google Maps SDK for iOS |
| **認証** | Firebase Auth (Appleサインイン・Googleサインイン) |
| **課金** | RevenueCat (未実装) |
| **Xcodeプロジェクト** | `Paymap.xcodeproj` |
| **プロジェクト管理** | xcodegen (`project.yml`) |

---

## 2. フォルダ構成

```
/Users/youki/SourceCSN/paymap/
├── Docs/
│   ├── 00_AI_Handover.md                # ★ このファイル（引き継ぎ文書）
│   ├── 01_Requirements_Definition.md    # 要件定義書（確定版）
│   ├── 02_Database_Schema.md            # Firestoreデータベース設計
│   ├── 03_Design_Specification.md       # UIデザイン仕様書
│   └── 04_GoogleMaps_API_Guide.md       # Google Maps APIキー取得手順
├── Paymap/
│   └── Sources/
│       ├── App/
│       │   ├── PaymapApp.swift           # エントリポイント（Firebase.configure & GMSServices初期化）
│       │   └── ContentView.swift         # TabViewのルートビュー
│       ├── Models/
│       │   ├── Store.swift               # 店舗モデル + StoreCategory Enum
│       │   └── PaymentMethod.swift       # 決済手段モデル
│       ├── ViewModels/
│       │   ├── MapViewModel.swift        # マップのロジック（Firestore/モック両対応）
│       │   └── AuthViewModel.swift       # Firebase Auth（Apple/Google/モック対応）
│       ├── Views/
│       │   ├── AuthView.swift            # ログイン画面（実Firebase Auth統合済み）
│       │   ├── ContentView.swift         # TabViewによる画面切り替え
│       │   ├── MapView.swift             # マップ・詳細シート・申請フォーム
│       │   ├── GoogleMapView.swift       # Google Maps SDKのUIViewRepresentableラッパー
│       │   └── ProfileView.swift         # マイページ・バッジ・プレミアム画面
│       ├── Services/
│       │   ├── PlacesService.swift       # 店舗データ取得（モック実装。実API化はTODO）
│       │   └── StoreService.swift        # ★NEW: Firestoreとの本CRUD・80%トランザクション
│       └── Utils/
│           └── DesignSystem.swift        # ブランドカラー・グラスモーフィズム・ボタンスタイル
├── Pods/                              # CocoaPods（GoogleMaps v9, GooglePlaces v9）
├── Paymap.xcworkspace                 # ★ ビルド時はこちらを使用！（pod install後）
├── Paymap.xcodeproj                   # xcodegen生成（直接は使わない）
├── Podfile                            # CocoaPods定義（GoogleMaps, GooglePlaces）
└── project.yml                        # xcodegen設定ファイル
```

---

## 3. 技術スタック・依存関係

### Swift Package Manager (SPM) 依存関係

| パッケージ | バージョン | 用途 |
|---|---|---|
| `firebase-ios-sdk` | 10.22.0〜 | Auth / Firestore |
| `GoogleSignIn-iOS` | 7.0.0〜 | Googleサインイン |

### CocoaPods 依存関係 (`Podfile`)

| Pod | バージョン | 用途 |
|---|---|---|
| `GoogleMaps` | ~> 9.0 | Google Maps表示 |
| `GooglePlaces` | ~> 9.0 | 店舗情報取得（未使用・今後実装） |

### 外部APIキー

| サービス | キー | 設定場所 |
|---|---|---|
| Google Maps / Places API | `AIzaSyCEUXvgia4w1DzQTNL8mYcoljVcczMsR44` | `PaymapApp.swift` の `GMSServices.provideAPIKey()` |
| Firebase | 未設定（要取得） | `GoogleService-Info.plist`（`Paymap/`直下に配置） |

> [!WARNING]
> Google Maps APIキーは現在「無制限」状態です。本番リリース前に、GCPコンソールで**iOSアプリ（Bundle ID: `com.csn.Paymap`）限定の制限**を設定すること。

---

## 4. 実装済み機能（現在の状態）

### ✅ 完了・実装済み

| 機能 | ファイル | 状態 |
|---|---|---|
| アプリ起動・画面遷移（TabView） | `PaymapApp.swift`, `ContentView.swift` | ✅ 完了 |
| Firebase Auth - 認証状態の永続化 | `AuthViewModel.swift` | ✅ 本実装済み |
| Firebase Auth - Apple サインイン（Nonce対応） | `AuthViewModel.signInWithApple()` | ✅ 本実装済み |
| Firebase Auth - Google サインイン | `AuthViewModel.signInWithGoogle()` | ✅ 本実装済み |
| Firebase未設定時のモックフォールバック | `AuthViewModel` / `MapViewModel` | ✅ 完了 |
| Google Mapsの表示基盤（CocoaPods v9） | `GoogleMapView.swift` | ✅ 完了 |
| 店舗のカテゴリ別カスタムピン | `Store.swift`, `MapView.swift` | ✅ 完了 |
| 店舗タップで決済手段表示（BottomSheet） | `StoreDetailSheet` in `MapView.swift` | ✅ 完了 |
| 決済手段の申請・報告フォーム | `ReportPaymentMethodView` in `MapView.swift` | ✅ UIのみ |
| 80% コンセンサスの Firestore トランザクション | `StoreService.submitPaymentReport()` | ✅ 本実装済み |
| Firestoreからの店舗データ取得（フォールバック付き） | `MapViewModel.fetchStores()` | ✅ 本実装済み |
| マイページ・バッジUI | `ProfileView.swift` | ✅ UIのみ |
| プレミアムプラン紹介画面 | `PremiumFeatureView` in `ProfileView.swift` | ✅ UIのみ |
| デザインシステム（ブランドカラー・グラスモーフィズム） | `DesignSystem.swift` | ✅ 完了 |
| Firestoreデータベース設計書 | `Docs/02_Database_Schema.md` | ✅ 設計書のみ |

---

## 5. 未実装・TODO（今後の開発予定）

### 🔴 最優先（アプリを実際に動かすために必須）

1. **Firebase プロジェクトの設定**
   - Firebaseコンソールでプロジェクト作成 → iOS アプリ追加
   - `GoogleService-Info.plist` を `Paymap/` 直下に配置
   - `PaymapApp.swift` に `FirebaseApp.configure()` を追加
   - 手順書: `Docs/01_Requirements_Definition.md` 参照

2. **Firebase Auth の実装**
   - `AuthViewModel.signInWithApple()` の本実装
   - `AuthViewModel.signInWithGoogle()` の本実装（`GIDSignIn` API使用）
   - 認証状態の永続化（`Auth.auth().addStateDidChangeListener`）

3. **Firestore への接続**
   - `PlacesService.swift` のモック実装を、Firestore + Google Places API の実呼び出しに置き換え
   - `MapViewModel.submitConsensusReport()` を Firestore への書き込み処理に置き換え
   - 80%ルールを Cloud Functions（またはクライアント側ロジック）で自動計算・フィールド更新

### 🟡 中優先（コア体験の向上）

4. **Google Places API との本連携**
   - 現在地取得（`CoreLocation` + `CLLocationManager`）の実装
   - 現在地周辺の店舗を Google Places API で取得し Firestore にキャッシュ
   - `PlacesService.swift` のコメントアウトされた実際のAPI呼び出しを有効化

5. **ユーザーインセンティブシステムの実装**
   - Firestoreの `users` コレクションへのポイント加算処理
   - バッジ付与ロジック（登録件数に応じて自動付与）
   - 貢献度ランキング画面の実装

6. **マップフィルター機能**
   - 決済手段でピンを絞り込む検索・フィルターUI

### 🟢 将来的な機能（有料プラン向け）

7. **RevenueCatによる課金実装**（アプリ内課金・サブスクリプション）
8. **高度な絞り込み検索**（PayPay使用可 × 深夜営業 × カフェ などのクロス検索）
9. **オフラインマップ機能**
10. **オリジナルマップピンのカスタマイズ機能**

---

## 6. データベース設計

詳細は `Docs/02_Database_Schema.md` を参照。概要は以下の通り。

### Firestoreコレクション構成

```
stores/                         ← 店舗情報（Google Places APIから取得してキャッシュ）
  {place_id}/
    name, category, location, confirmedPaymentMethods, lastUpdated
    payment_reports/            ← 決済手段への報告（サブコレクション）
      {methodId}/
        totalReports, supportedCount, unsupportedCount, approvalRate, isActive
        reporters: { uid: true/false }

users/                          ← ユーザープロフィール・実績
  {uid}/
    displayName, contributionPoints, badges[], isPremium, createdAt

contributions/                  ← 貢献履歴（ランキング算出用）
  {autoId}/
    userId, storeId, methodId, action, pointsEarned, timestamp
```

---

## 7. デザインシステム

詳細は `Docs/03_Design_Specification.md` を参照。コード上の定義は `DesignSystem.swift`。

| 要素 | 値 |
|---|---|
| メインカラー | `premiumNavy` (R:0.1, G:0.15, B:0.3) |
| アクセントカラー | `premiumEmerald` (R:0.2, G:0.8, B:0.6) |
| カードUI | `.glassCard()` モディファイア（ウルトラシン マテリアル + 角丸16 + シャドウ）|
| ボタン（Primary） | `PrimaryButtonStyle`（エメラルドグラデーション） |
| ボタン（Secondary） | `SecondaryButtonStyle`（ネイビー系・薄い背景）|
| アニメーション | `.spring(response: 0.4, dampingFraction: 0.7)` を基本に使用 |

---

## 8. カテゴリ別マップピンのデザイン定義

```swift
// Store.swift > StoreCategory 参照
case .convenienceStore: color = .orange,  icon = "cart.fill"
case .cafe:             color = .brown,   icon = "cup.and.saucer.fill"
case .vendingMachine:   color = .cyan,    icon = "takeoutbag.and.cup.and.straw.fill"
case .drugStore:        color = .pink,    icon = "cross.case.fill"
case .restaurant:       color = .red,     icon = "fork.knife"
case .other:            color = .premiumNavy, icon = "mappin"
```

---

## 9. プロジェクト再生成の方法

ソースコードに変更を加えた後、プロジェクトを正しくXcodeに反映させるには必ず以下を実行：

```bash
cd /Users/youki/SourceCSN/paymap
xcodegen generate
```

その後、Xcodeで **Product > Clean Build Folder** (Shift + Cmd + K) を実行してからリビルド。

---

## 10. 開発環境・注意事項

- **Xcodeバージョン**: macOS上のXcode（`xcodebuild` コマンドが動作する環境）
- **シミュレータ**: iPhone 17 Pro (iOS 26.3) などを確認済み
- **ビルドエラーが出る場合**: `xcodegen generate` を実行した後、Xcodeを再起動して Clean Build Folderを実行すること
- **APIキーの扱い**: `AIzaSyCEUXvgia4w1DzQTNL8mYcoljVcczMsR44` は現在ソースコードに直書き。本番前にGCPで制限を設定すること
- **Firebase未設定**: 現状では Firebase はコードに組み込まれているが、`GoogleService-Info.plist` が未配置のため認証・DB機能はすべてモック動作
