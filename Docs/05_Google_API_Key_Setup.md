# Google Maps API キー制限 手順書

**重要**: 現在のAPIキーは無制限状態です。不正利用されると GCP に課金が発生します。  
**必ずリリース前に以下の手順でキーを制限してください。**

---

## 現在のAPIキー情報

| 項目 | 値 |
|------|-----|
| Maps/Places APIキー | `AIzaSyCEUXvgia4w1DzQTNL8mYcoljVcczMsR44` |
| AdMob App ID | `ca-app-pub-4490113823639458~5211821465` |
| Bundle ID | `com.csn.Paymap` |

---

## Step 1: Google Cloud Console にアクセス

1. [https://console.cloud.google.com](https://console.cloud.google.com) を開く
2. 左上のプロジェクト選択で、PayMap 用のプロジェクトを選択
3. 左メニュー → **「APIとサービス」** → **「認証情報」** をクリック

---

## Step 2: APIキーの制限設定

1. 認証情報一覧から `AIzaSyCEUXvgia4w1DzQTNL8mYcoljVcczMsR44` をクリック
2. **「キーの制限」** セクションで：
   - アプリケーションの制限：**「iOS アプリ」** を選択
   - 「iOS バンドル ID を追加」をクリック
   - `com.csn.Paymap` と入力して **「完了」**

3. **「API の制限」** セクションで：
   - 「キーを制限する」を選択
   - 以下の API にチェックを入れる：
     - ✅ Maps SDK for iOS
     - ✅ Places API (New)
     - ✅ Geocoding API

4. 右下の **「保存」** をクリック

---

## Step 3: API キーの確認

制限設定後、iOSシミュレーターでアプリを起動して地図・場所検索が正常に動作することを確認してください。

---

## Step 4: 使用量アラートの設定（推奨）

1. GCP コンソール → **「お支払い」** → **「予算とアラート」**
2. 「予算を作成」→ 月額 ¥1,000 などの上限を設定
3. 不正利用早期検知のため **80%・100%** でメール通知を設定

---

## Step 5: Google Places API の確認

[PlacesService.swift](../Paymap/Sources/Services/PlacesService.swift) は APIキーが正しく設定されていれば自動で実 API を呼び出します。  
APIキー未設定またはエラー時はモック5店舗（新宿周辺）にフォールバックします。

### Places API 動作確認方法

1. Xcodeでアプリを起動
2. 現在地を新宿周辺に設定（シミュレーター：Features → Location → Custom Location → 35.6900, 139.7000）
3. マップ画面でコンビニ・カフェのピンが表示されれば実 API 取得成功

---

## AdMob テスト ID について

現在使用中の AdMob ID はテスト用です：
- App ID: `ca-app-pub-4490113823639458~5211821465`
- バナー Unit ID: （確認要）
- インタースティシャル Unit ID: `ca-app-pub-4490113823639458/8255863769`

**本番リリース時は実際の AdMob アカウントで本番 Unit ID を取得して置き換えてください。**
