<?php
// ============================================================
// データベース接続設定
// さくらインターネット コントロールパネルで確認した値を入力してください
// ============================================================

define('DB_HOST', 'mysqlXXX.db.sakura.ne.jp'); // さくらのMySQL接続先（コントロールパネルで確認）
define('DB_NAME', 'アカウント名_paymap');       // データベース名（アカウント名_paymap が推奨）
define('DB_USER', 'アカウント名');              // データベースユーザー名
define('DB_PASS', 'パスワード');                // データベースパスワード
define('DB_CHARSET', 'utf8mb4');

// 写真アップロード設定
define('UPLOAD_DIR', __DIR__ . '/../uploads/');   // アップロード先ディレクトリ
define('UPLOAD_BASE_URL', 'https://yourserver.sakura.ne.jp/paymap/uploads/'); // 公開URL

// JWT シークレット（Firebase UID の簡易検証 or 独自認証用）
define('JWT_SECRET', 'your_jwt_secret_here');

// ============================================================
// データベース接続
// ============================================================
function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=' . DB_CHARSET;
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    }
    return $pdo;
}

// ============================================================
// レスポンス共通関数
// ============================================================
function jsonResponse(array $data, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function errorResponse(string $msg, int $code = 400): void {
    jsonResponse(['error' => $msg], $code);
}

// リクエストボディ（JSON）の取得
function getRequestBody(): array {
    $raw = file_get_contents('php://input');
    return json_decode($raw, true) ?? [];
}
