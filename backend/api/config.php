<?php
// ============================================================
// データベース接続設定
// ⚠️  本番パスワードが含まれます — 公開リポジトリにコミットしないこと
// ============================================================

define('DB_HOST',    'mysql3115.db.sakura.ne.jp');
define('DB_NAME',    'coussinet_paymap');
define('DB_USER',    'coussinet');
define('DB_PASS',    'midori0812');
define('DB_CHARSET', 'utf8mb4');

// 写真アップロード設定
define('UPLOAD_DIR',      __DIR__ . '/../uploads/');
define('UPLOAD_BASE_URL', 'https://coussinet.sakura.ne.jp/paymap/uploads/');

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

// 店舗行を API レスポンス形式に変換する共通ヘルパー
function storeRowToArray(array $row): array {
    return [
        'id'                      => $row['id'],
        'name'                    => $row['name'],
        'nameEn'                  => $row['name_en'],
        'category'                => $row['category'],
        'location'                => [
            'latitude'  => (float)$row['latitude'],
            'longitude' => (float)$row['longitude'],
        ],
        'address'                 => $row['address'],
        'addressEn'               => $row['address_en'],
        'photoURL'                => $row['photo_url'],
        'registeredByUid'         => $row['registered_by'],
        'hasWifi'                 => $row['has_wifi']  === null ? null : (bool)$row['has_wifi'],
        'hasPower'                => $row['has_power'] === null ? null : (bool)$row['has_power'],
        'supportedPaymentMethods' => $row['confirmed_methods']
                                        ? explode(',', $row['confirmed_methods'])
                                        : [],
    ];
}
