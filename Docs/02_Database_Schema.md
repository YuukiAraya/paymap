# Firestore データベース設計 (Database Schema)

## 概要
ユーザーからの投稿によって決済手段の情報を構築し、情報の正確性を「コンセンサス方式（複数ユーザーの一致）」で担保するためのデータ構造です。

---

## 1. コレクション: `stores`
店舗ごとの情報を管理します。基本情報はGoogle Places APIから取得したものをキャッシュとして保持し、決済手段はユーザー投稿を基に算出された「確定情報」を保持します。

*   **Document ID**: Google Places API の `place_id`
*   **Fields**:
    *   `name`: String (店舗名)
    *   `category`: String (カテゴリ、例: "コンビニ")
    *   `location`: GeoPoint (緯度経度)
    *   `confirmedPaymentMethods`: Array of Strings (確定した決済手段のIDリスト)
    *   `lastUpdated`: Timestamp (最終更新日時)

---

## 2. コレクション: `stores/{place_id}/payment_reports`
各店舗の決済手段に対するユーザーからの「報告・申請」を管理するサブコレクションです。
全体の報告数のうち「使える」という報告が **80%以上** を占めた場合のみ、`stores` の `confirmedPaymentMethods` に反映・有効化されます。

*   **Document ID**: 決済手段ID（例: `paypay`, `suica`, `visa` など）
*   **Fields**:
    *   `methodId`: String (決済手段ID)
    *   `totalReports`: Number (この決済手段に対する総報告数)
    *   `supportedCount`: Number (「使える（正しい）」と報告した数)
    *   `unsupportedCount`: Number (「使えない（間違っている）」と報告した数)
    *   `approvalRate`: Number (0.0 ~ 1.0, `supportedCount / totalReports` で計算)
    *   `isActive`: Boolean (approvalRate が 0.8 以上であれば true になり、UI上で有効として表示される)
    *   `reporters`: Map<String, Boolean> (key: uid, value: true=使える/false=使えない。二重投票防止および報告変更用)

---

## 3. コレクション: `users`
ユーザーのプロフィール情報、貢献度（インセンティブ機能用）を管理します。

*   **Document ID**: Firebase Auth の `uid`
*   **Fields**:
    *   `displayName`: String (表示名)
    *   `contributionPoints`: Number (貢献ポイント総数)
    *   `badges`: Array of Strings (獲得したバッジIDのリスト)
    *   `isPremium`: Boolean (有料プラン加入フラグ)
    *   `createdAt`: Timestamp

---

## 4. コレクション: `contributions` (オプション)
ユーザーがいつ、どの店舗のどの決済手段に投票したかの履歴。ランキング算出や個人のアクティビティ表示に使用。

*   **Document ID**: Auto-generated
*   **Fields**:
    *   `userId`: String (uid)
    *   `storeId`: String (place_id)
    *   `methodId`: String
    *   `action`: String (`upvote`, `downvote`, `first_discovery`)
    *   `pointsEarned`: Number (この行動で得たポイント)
    *   `timestamp`: Timestamp
