# Google Maps API キーの取得手順

iOSアプリで Google Maps を表示するためには、Google Cloud Platform (GCP) から「API キー」を取得し、アプリ内に設定する必要があります。

以下の手順に沿って取得を進めてください。

## 手順 1: Google Cloud Console にアクセスする
1. ブラウザで [Google Cloud Console](https://console.cloud.google.com/) にアクセスします。
2. Google アカウントでログインします（開発用のGoogleアカウントをご使用ください）。

## 手順 2: 新しいプロジェクトを作成する
1. 画面左上の「プロジェクトの選択」ドロップダウンをクリックします。
2. 右上の「新しいプロジェクト」をクリックします。
3. プロジェクト名（例: `PaymapApp`）を入力し、「作成」をクリックします。
4. 数秒待つとプロジェクトが作成されるので、作成したプロジェクトを選択します。

## 手順 3: Maps SDK for iOS を有効にする
1. 画面左上のハンバーガーメニュー（≡）を開き、**「API とサービス」 > 「ライブラリ」** をクリックします。
2. 検索バーに **「Maps SDK for iOS」** と入力して検索します。
3. 検索結果から「Maps SDK for iOS」を選択し、**「有効にする」** ボタンをクリックします。

*(※ 今後の開発で店舗情報を取得するために、「**Places API (New)**」も同様の手順で有効にしておくことを推奨します)*

## 手順 4: API キーを作成する
1. 再度メニュー（≡）を開き、**「API とサービス」 > 「認証情報」** をクリックします。
2. 画面上部の **「＋ 認証情報を作成」** をクリックし、**「API キー」** を選択します。
3. 「API キーを作成しました」というポップアップが表示され、**API キー（文字列）** が表示されます。
   （例: `AIzaSyB...` のような文字列です）
4. この文字列をコピーして、Xcodeプロジェクトの `PaymapApp.swift` に貼り付けます。

## 手順 5: アプリに組み込む
Xcodeを開き、`/Users/youki/SourceCSN/paymap/Paymap/Sources/App/PaymapApp.swift` を以下のように修正します。

```swift
import SwiftUI
import GoogleMaps

@main
struct PaymapApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // コピーしたAPIキーをここに貼り付けます
        GMSServices.provideAPIKey("AIzaSyB*******************")
    }
    
    // ...
}
```

---

> [!WARNING]
> ### （重要）APIキーの制限設定について
> 初期状態のAPIキーは誰でも利用できてしまうため、悪用を防ぐために以下の設定を必ず行ってください。
> 1. 先ほどの「認証情報」画面で、作成したAPIキーの名前をクリックします。
> 2. 「アプリケーションの制限」セクションで **「iOS アプリ」** を選択します。
> 3. 「バンドルIDを追加」をクリックし、アプリのBundle ID（例: `com.csn.Paymap`）を入力します。
> 4. 「APIの制限」セクションで「キーを制限」を選択し、「Maps SDK for iOS」と「Places API (New)」にのみチェックを入れます。
> 5. 「保存」をクリックします。

これで、あなたのアプリからしかこのAPIキーを使えなくなり、安全に運用できるようになります！
