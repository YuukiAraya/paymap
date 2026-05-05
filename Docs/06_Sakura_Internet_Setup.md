# さくらインターネット バックエンド セットアップガイド

PayMap のデータベースをさくらインターネットのサーバーに構築する手順書です。

---

## 構成概要

```
iOSアプリ (PayMap)
    │
    ├── Firebase Auth        ← 認証のみ（そのまま使用）
    │
    └── さくらインターネット  ← データベース・API・写真保存
           ├── MySQL         ← 店舗・ユーザー・決済データ
           ├── PHP API       ← REST APIエンドポイント
           └── uploads/      ← 店舗写真保存先
```

---

## Step 1: さくらインターネット コントロールパネルで MySQL を作成

1. [https://secure.sakura.ad.jp/menu/](https://secure.sakura.ad.jp/menu/) にログイン
2. **「データベースの設定」** をクリック
3. **「データベースの追加」** をクリック
4. 以下を設定して「作成する」をクリック：

| 項目 | 設定値 |
|------|--------|
| データベース名 | `アカウント名_paymap`（例: `yourname_paymap`） |
| データベースパスワード | 任意のパスワード（メモしておく） |
| 文字コード | UTF-8 |

5. 作成後、接続情報を確認：
   - **接続先サーバー（ホスト名）**: `mysqlXXX.db.sakura.ne.jp` ← コントロールパネルで確認

---

## Step 2: phpMyAdmin でスキーマを作成

1. コントロールパネル → **「phpMyAdmin を開く」**
2. 左サイドバーで作成したデータベース名をクリック
3. 上部タブ **「SQL」** をクリック
4. [backend/sql/schema.sql](../backend/sql/schema.sql) の内容を全て貼り付けて **「実行」**

---

## Step 3: API ファイルをサーバーにアップロード

### FTP 設定（さくらのコントロールパネルで確認）

| 項目 | 値 |
|------|-----|
| FTPサーバー | `ftpXXX.sakura.ne.jp` |
| ユーザー名 | さくらアカウント名 |
| パスワード | さくらのパスワード |

### アップロード先

```
public_html/
  └── paymap/
        └── api/
              ├── config.php
              ├── stores.php
              ├── reports.php
              ├── users.php
              └── upload.php
```

アップロード先は `public_html/paymap/api/` です。  
FTP クライアント（FileZilla など）で `backend/api/` の内容をそのままアップロードしてください。

---

## Step 4: config.php を編集

アップロード後、サーバー上の `config.php` を編集して接続情報を設定してください：

```php
define('DB_HOST', 'mysqlXXX.db.sakura.ne.jp'); // コントロールパネルで確認した値
define('DB_NAME', 'yourname_paymap');           // 作成したDB名
define('DB_USER', 'yourname');                  // さくらアカウント名
define('DB_PASS', 'your_db_password');          // Step 1 で設定したパスワード

define('UPLOAD_BASE_URL', 'https://yourserver.sakura.ne.jp/paymap/uploads/');
```

---

## Step 5: uploads ディレクトリを作成

```
public_html/
  └── paymap/
        └── uploads/     ← このフォルダを作成（FTPで作成）
```

FTPで `public_html/paymap/uploads/` フォルダを作成し、パーミッションを **755** に設定してください。

---

## Step 6: API動作確認

ブラウザで以下のURLにアクセスして動作確認：

```
https://yourserver.sakura.ne.jp/paymap/api/stores.php?lat=35.69&lng=139.70&radius=5
```

以下のようなJSONが返れば成功です：
```json
{"stores":[]}
```

---

## Step 7: iOS アプリの接続設定（将来の移行時）

現在のアプリはFirestoreを使用しています。さくらインターネットのAPIに移行する場合は：

1. `Paymap/Sources/Services/StoreService.swift` の Firestore 呼び出しを  
   上記 PHP API への URLSession リクエストに置き換える

2. APIのベースURL を `PaymapApp.swift` に定数として追加：
   ```swift
   let apiBaseURL = "https://yourserver.sakura.ne.jp/paymap/api"
   ```

3. 写真アップロードは `StoreService.uploadStorePhoto()` メソッドが既に実装済みです。  
   `uploadBaseURL` に上記 URL を渡すだけで動作します：
   ```swift
   let photoUrl = try await storeService.uploadStorePhoto(
       storeId: store.id,
       imageData: imageData,
       uploadBaseURL: "https://yourserver.sakura.ne.jp/paymap/api"
   )
   ```

---

## Step 8: Firestore セキュリティルール（現在の Firebase 設定）

さくらインターネットに完全移行するまでの間、Firebase Firestore のセキュリティルールを設定してください：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /stores/{storeId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

Firebase コンソール → Firestore → ルール から設定してください。

---

## 料金目安（さくらインターネット）

| プラン | 月額 | MySQL DB数 | ストレージ |
|--------|------|-----------|-----------|
| スタンダード | ¥524 | 1個 | 100GB |
| プレミアム | ¥1,571 | 5個 | 200GB |
| ビジネス | ¥4,223 | 10個 | 400GB |

スタンダードプランで十分です（MySQL1個・100GBで PayMap の運用に十分）。
