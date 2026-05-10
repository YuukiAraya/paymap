<?php
/**
 * ユーザー API
 * GET  /api/users.php?action=ranking&limit=20    → 貢献度ランキング
 * GET  /api/users.php?uid=xxx                    → ユーザープロフィール（お気に入りID含む）
 * POST /api/users.php                            → ユーザー作成・更新
 * POST /api/users.php?action=update_profile      → displayName / email 更新
 * POST /api/users.php?action=add_points          → ポイント追加
 * POST /api/users.php?action=toggle_favorite     → お気に入り切り替え
 * POST /api/users.php?action=award_badge         → バッジ付与
 */

require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

// ---- ランキング取得 ----
if ($method === 'GET' && $action === 'ranking') {
    $limit = min((int)($_GET['limit'] ?? 20), 100);
    $pdo   = getDB();
    $stmt  = $pdo->prepare("
        SELECT u.uid, u.display_name, u.total_contributions,
               GROUP_CONCAT(b.badge_id ORDER BY b.badge_id) AS badges
        FROM users u
        LEFT JOIN user_badges b ON u.uid = b.uid
        GROUP BY u.uid
        ORDER BY u.total_contributions DESC
        LIMIT :lim
    ");
    $stmt->bindValue(':lim', $limit, PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll();

    $rank = 1;
    $entries = array_map(function ($row) use (&$rank) {
        return [
            'rank'        => $rank++,
            'uid'         => $row['uid'],
            'displayName' => $row['display_name'] ?? 'Unknown',
            'points'      => (int)$row['total_contributions'],
            'badges'      => $row['badges'] ? explode(',', $row['badges']) : [],
        ];
    }, $rows);
    jsonResponse(['ranking' => $entries]);
}

// ---- ユーザープロフィール取得 ----
if ($method === 'GET' && isset($_GET['uid'])) {
    $uid = $_GET['uid'];
    $pdo = getDB();

    $stmt = $pdo->prepare("SELECT * FROM users WHERE uid = ?");
    $stmt->execute([$uid]);
    $user = $stmt->fetch();
    if (!$user) { errorResponse('User not found', 404); }

    $badgeStmt = $pdo->prepare("SELECT badge_id FROM user_badges WHERE uid = ?");
    $badgeStmt->execute([$uid]);
    $badges = array_column($badgeStmt->fetchAll(), 'badge_id');

    $favStmt = $pdo->prepare("SELECT store_id FROM user_favorites WHERE uid = ?");
    $favStmt->execute([$uid]);
    $favorites = array_column($favStmt->fetchAll(), 'store_id');

    jsonResponse([
        'uid'                => $user['uid'],
        'displayName'        => $user['display_name'],
        'email'              => $user['email'],
        'totalContributions' => (int)$user['total_contributions'],
        'isPremium'          => (bool)$user['is_premium'],
        'photoURL'           => $user['photo_url'],
        'badges'             => $badges,
        'favoriteStoreIds'   => $favorites,
    ]);
}

// ---- プロフィール更新（displayName / email）----
if ($method === 'POST' && $action === 'update_profile') {
    $body = getRequestBody();
    $uid  = $body['uid'] ?? null;
    if (!$uid) { errorResponse('uid required'); }

    $pdo = getDB();
    if (array_key_exists('displayName', $body) && $body['displayName'] !== null) {
        $pdo->prepare("UPDATE users SET display_name = ? WHERE uid = ?")
            ->execute([$body['displayName'], $uid]);
    }
    if (array_key_exists('email', $body) && $body['email'] !== null) {
        $pdo->prepare("UPDATE users SET email = ? WHERE uid = ?")
            ->execute([$body['email'], $uid]);
    }
    jsonResponse(['success' => true]);
}

// ---- お気に入り切り替え ----
if ($method === 'POST' && $action === 'toggle_favorite') {
    $body       = getRequestBody();
    $uid        = $body['uid']         ?? null;
    $storeId    = $body['store_id']    ?? null;
    $isFavorite = $body['is_favorite'] ?? null;
    if (!$uid || !$storeId || $isFavorite === null) { errorResponse('uid, store_id, is_favorite required'); }

    $pdo = getDB();
    if ($isFavorite) {
        // ユーザーが未登録の場合は自動作成（外部キー制約を満たすため）
        $pdo->prepare("INSERT IGNORE INTO users (uid) VALUES (?)")->execute([$uid]);
        $pdo->prepare("INSERT IGNORE INTO user_favorites (uid, store_id) VALUES (?, ?)")
            ->execute([$uid, $storeId]);
    } else {
        $pdo->prepare("DELETE FROM user_favorites WHERE uid = ? AND store_id = ?")
            ->execute([$uid, $storeId]);
    }
    jsonResponse(['success' => true]);
}

// ---- ポイント追加 ----
if ($method === 'POST' && $action === 'add_points') {
    $body   = getRequestBody();
    $uid    = $body['uid']    ?? null;
    $points = (int)($body['points'] ?? 0);
    if (!$uid || $points <= 0) { errorResponse('uid and points required'); }

    $pdo = getDB();
    $pdo->prepare("
        UPDATE users SET total_contributions = total_contributions + ? WHERE uid = ?
    ")->execute([$points, $uid]);

    $stmt = $pdo->prepare("SELECT total_contributions FROM users WHERE uid = ?");
    $stmt->execute([$uid]);
    $total = (int)$stmt->fetchColumn();

    $newBadges = checkAndAwardBadges($pdo, $uid, $total);
    jsonResponse(['success' => true, 'total' => $total, 'newBadges' => $newBadges]);
}

// ---- バッジ付与 ----
if ($method === 'POST' && $action === 'award_badge') {
    $body    = getRequestBody();
    $uid     = $body['uid']      ?? null;
    $badgeId = $body['badge_id'] ?? null;
    if (!$uid || !$badgeId) { errorResponse('uid and badge_id required'); }

    $pdo = getDB();
    // ユーザーが存在しない場合は何もしない（サイレント）
    $pdo->prepare("INSERT IGNORE INTO user_badges (uid, badge_id) VALUES (?, ?)")
        ->execute([$uid, $badgeId]);
    jsonResponse(['success' => true]);
}

// ---- ユーザー作成・更新 ----
if ($method === 'POST') {
    $body = getRequestBody();
    $uid  = $body['uid'] ?? null;
    if (!$uid) { errorResponse('uid required'); }

    $pdo = getDB();
    $pdo->prepare("
        INSERT INTO users (uid, display_name, email) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE
            display_name = COALESCE(VALUES(display_name), display_name),
            email        = COALESCE(VALUES(email), email)
    ")->execute([$uid, $body['displayName'] ?? null, $body['email'] ?? null]);
    jsonResponse(['success' => true]);
}

errorResponse('Invalid request', 400);

// ---- バッジ付与ヘルパー ----
function checkAndAwardBadges(PDO $pdo, string $uid, int $total): array {
    $thresholds = [
        'firstPost' => 1,
        'br10'      => 10,
        'br50'      => 50,
        'brMaster'  => 200,
    ];
    $stmt = $pdo->prepare("SELECT badge_id FROM user_badges WHERE uid = ?");
    $stmt->execute([$uid]);
    $earned = array_column($stmt->fetchAll(), 'badge_id');

    $newBadges = [];
    foreach ($thresholds as $id => $threshold) {
        if ($total >= $threshold && !in_array($id, $earned, true)) {
            $pdo->prepare("INSERT IGNORE INTO user_badges (uid, badge_id) VALUES (?, ?)")
                ->execute([$uid, $id]);
            $newBadges[] = $id;
        }
    }
    return $newBadges;
}
