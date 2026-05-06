<?php
/**
 * 店舗 API
 * GET    /api/stores.php?lat=35.6&lng=139.7&radius=20   → 近くの店舗一覧（半径 km）
 * GET    /api/stores.php?uid=xxx                         → ユーザーが登録した店舗一覧
 * GET    /api/stores.php?ids=id1,id2,id3                 → IDで一括取得（お気に入り用）
 * POST   /api/stores.php                                  → 店舗登録・更新 (upsert)
 * POST   /api/stores.php?action=update_facilities        → WiFi/電源のみ更新
 * POST   /api/stores.php?action=report_error             → 誤り報告
 * DELETE /api/stores.php?store_id=xxx&uid=yyy            → 店舗削除（本人24h以内 or 他更新0件 or 管理者）
 */

require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

// ============================================================
// スキーママイグレーション（is_deleted / in_review / store_error_reports）
// ============================================================
function ensureSchema(PDO $pdo): void {
    // is_deleted / in_review カラム追加（すでに存在する場合は無視）
    try { $pdo->exec("ALTER TABLE stores ADD COLUMN is_deleted TINYINT(1) NOT NULL DEFAULT 0"); }
    catch (PDOException $e) {}
    try { $pdo->exec("ALTER TABLE stores ADD COLUMN in_review TINYINT(1) NOT NULL DEFAULT 0"); }
    catch (PDOException $e) {}

    // 誤り報告テーブル
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS store_error_reports (
            id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            store_id         VARCHAR(64)  NOT NULL,
            reported_by_uid  VARCHAR(128) NOT NULL,
            reason           VARCHAR(255),
            created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uq_error_report (store_id, reported_by_uid),
            FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
}

// ============================================================
// GET: ユーザー登録店舗
// ============================================================
if ($method === 'GET' && isset($_GET['uid'])) {
    $uid  = $_GET['uid'];
    $pdo  = getDB();
    ensureSchema($pdo);
    $stmt = $pdo->prepare("
        SELECT s.*, GROUP_CONCAT(spm.method_id ORDER BY spm.method_id) AS confirmed_methods
        FROM stores s
        LEFT JOIN store_payment_methods spm ON s.id = spm.store_id
        WHERE s.registered_by = :uid AND s.is_deleted = 0
        GROUP BY s.id
        ORDER BY s.created_at DESC
        LIMIT 200
    ");
    $stmt->execute([':uid' => $uid]);
    jsonResponse(['stores' => array_map('storeRowToArray', $stmt->fetchAll())]);
}

// ============================================================
// GET: IDリストで一括取得（お気に入り）
// ============================================================
if ($method === 'GET' && isset($_GET['ids'])) {
    $ids = array_filter(array_map('trim', explode(',', $_GET['ids'])));
    if (empty($ids)) {
        jsonResponse(['stores' => []]);
    }
    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $pdo  = getDB();
    ensureSchema($pdo);
    $stmt = $pdo->prepare("
        SELECT s.*, GROUP_CONCAT(spm.method_id ORDER BY spm.method_id) AS confirmed_methods
        FROM stores s
        LEFT JOIN store_payment_methods spm ON s.id = spm.store_id
        WHERE s.id IN ($placeholders) AND s.is_deleted = 0
        GROUP BY s.id
    ");
    $stmt->execute(array_values($ids));
    jsonResponse(['stores' => array_map('storeRowToArray', $stmt->fetchAll())]);
}

// ============================================================
// GET: 近くの店舗（緯度経度 + 半径）
// ============================================================
if ($method === 'GET') {
    $lat    = isset($_GET['lat'])    ? (float)$_GET['lat']    : null;
    $lng    = isset($_GET['lng'])    ? (float)$_GET['lng']    : null;
    $radius = isset($_GET['radius']) ? (float)$_GET['radius'] : 20.0;

    if ($lat === null || $lng === null) {
        errorResponse('lat and lng are required');
    }

    $latDelta = $radius / 111.0;
    $lngDelta = $radius / (111.0 * cos($lat * M_PI / 180));

    $pdo  = getDB();
    ensureSchema($pdo);
    $stmt = $pdo->prepare("
        SELECT s.*, GROUP_CONCAT(spm.method_id ORDER BY spm.method_id) AS confirmed_methods
        FROM stores s
        LEFT JOIN store_payment_methods spm ON s.id = spm.store_id
        WHERE s.latitude  BETWEEN :latMin AND :latMax
          AND s.longitude BETWEEN :lngMin AND :lngMax
          AND s.is_deleted = 0
        GROUP BY s.id
        LIMIT 100
    ");
    $stmt->execute([
        ':latMin' => $lat - $latDelta, ':latMax' => $lat + $latDelta,
        ':lngMin' => $lng - $lngDelta, ':lngMax' => $lng + $lngDelta,
    ]);
    jsonResponse(['stores' => array_map('storeRowToArray', $stmt->fetchAll())]);
}

// ============================================================
// DELETE: 店舗削除
// 条件：（本人 AND (24h以内 OR 他ユーザー更新0件)）OR 管理者
// ============================================================
if ($method === 'DELETE') {
    global $ADMIN_UIDS;
    $storeId = $_GET['store_id'] ?? '';
    $uid     = $_GET['uid']      ?? '';

    if (empty($storeId) || empty($uid)) {
        errorResponse('store_id and uid are required');
    }

    $pdo = getDB();
    ensureSchema($pdo);

    // 店舗取得
    $stmt = $pdo->prepare("SELECT * FROM stores WHERE id = ? AND is_deleted = 0");
    $stmt->execute([$storeId]);
    $store = $stmt->fetch();

    if (!$store) {
        errorResponse('store_not_found', 404);
    }

    $isAdmin = in_array($uid, $ADMIN_UIDS, true);
    $isOwner = !empty($store['registered_by']) && $store['registered_by'] === $uid;

    if (!$isAdmin && !$isOwner) {
        errorResponse('not_authorized', 403);
    }

    if (!$isAdmin) {
        // 登録から24時間以内か確認
        $createdAt  = new DateTime($store['created_at']);
        $now        = new DateTime();
        $within24h  = ($now->getTimestamp() - $createdAt->getTimestamp()) < 86400;

        // 他ユーザーの決済手段レポート件数
        $stmt2 = $pdo->prepare("
            SELECT COUNT(*) FROM payment_reports
            WHERE store_id = ? AND user_id != ?
        ");
        $stmt2->execute([$storeId, $uid]);
        $otherReports = (int)$stmt2->fetchColumn();

        if (!$within24h && $otherReports > 0) {
            jsonResponse([
                'success' => false,
                'error'   => 'cannot_delete',
            ], 403);
        }
    }

    // 論理削除（is_deleted = 1）
    $pdo->prepare("UPDATE stores SET is_deleted = 1 WHERE id = ?")->execute([$storeId]);
    jsonResponse(['success' => true]);
}

// ============================================================
// POST: 誤り報告
// ============================================================
if ($method === 'POST' && $action === 'report_error') {
    $body    = getRequestBody();
    $storeId = $body['store_id'] ?? '';
    $uid     = $body['uid']      ?? '';
    $reason  = $body['reason']   ?? '';

    if (empty($storeId) || empty($uid)) {
        errorResponse('store_id and uid are required');
    }

    $pdo = getDB();
    ensureSchema($pdo);

    // 1ユーザー1店舗1票（重複無視）
    $stmt = $pdo->prepare("
        INSERT IGNORE INTO store_error_reports (store_id, reported_by_uid, reason)
        VALUES (?, ?, ?)
    ");
    $stmt->execute([$storeId, $uid, $reason]);

    // 報告件数集計
    $stmt2 = $pdo->prepare("SELECT COUNT(*) FROM store_error_reports WHERE store_id = ?");
    $stmt2->execute([$storeId]);
    $count = (int)$stmt2->fetchColumn();

    // 3件以上で管理者レビュー対象に
    if ($count >= 3) {
        $pdo->prepare("UPDATE stores SET in_review = 1 WHERE id = ?")->execute([$storeId]);
    }

    jsonResponse(['success' => true, 'report_count' => $count]);
}

// ============================================================
// POST: WiFi / 電源のみ更新
// ============================================================
if ($method === 'POST' && $action === 'update_facilities') {
    $body    = getRequestBody();
    $storeId = $body['store_id'] ?? null;
    if (!$storeId) {
        errorResponse('store_id is required');
    }
    $pdo = getDB();
    ensureSchema($pdo);
    if (array_key_exists('hasWifi', $body)) {
        $val = $body['hasWifi'] === null ? null : (int)(bool)$body['hasWifi'];
        $pdo->prepare("UPDATE stores SET has_wifi = ? WHERE id = ?")->execute([$val, $storeId]);
    }
    if (array_key_exists('hasPower', $body)) {
        $val = $body['hasPower'] === null ? null : (int)(bool)$body['hasPower'];
        $pdo->prepare("UPDATE stores SET has_power = ? WHERE id = ?")->execute([$val, $storeId]);
    }
    jsonResponse(['success' => true]);
}

// ============================================================
// POST: 店舗登録・更新 (upsert)
// ============================================================
if ($method === 'POST') {
    $body = getRequestBody();
    if (empty($body['id']) || empty($body['name']) || empty($body['category'])) {
        errorResponse('id, name, category are required');
    }

    $pdo  = getDB();
    ensureSchema($pdo);
    $stmt = $pdo->prepare("
        INSERT INTO stores (id, name, name_en, category, latitude, longitude, address, address_en,
                            photo_url, registered_by, has_wifi, has_power)
        VALUES (:id, :name, :name_en, :category, :lat, :lng, :address, :address_en,
                :photo_url, :registered_by, :has_wifi, :has_power)
        ON DUPLICATE KEY UPDATE
            name         = VALUES(name),
            name_en      = VALUES(name_en),
            category     = VALUES(category),
            address      = VALUES(address),
            address_en   = VALUES(address_en),
            has_wifi     = VALUES(has_wifi),
            has_power    = VALUES(has_power),
            last_updated = NOW()
    ");
    $loc = $body['location'] ?? [];
    $stmt->execute([
        ':id'            => $body['id'],
        ':name'          => $body['name'],
        ':name_en'       => $body['nameEn']          ?? null,
        ':category'      => $body['category'],
        ':lat'           => $loc['latitude']          ?? 0,
        ':lng'           => $loc['longitude']         ?? 0,
        ':address'       => $body['address']          ?? null,
        ':address_en'    => $body['addressEn']        ?? null,
        ':photo_url'     => $body['photoURL']         ?? null,
        ':registered_by' => $body['registeredByUid']  ?? null,
        ':has_wifi'      => isset($body['hasWifi'])   ? (int)(bool)$body['hasWifi']  : null,
        ':has_power'     => isset($body['hasPower'])  ? (int)(bool)$body['hasPower'] : null,
    ]);

    // 決済手段を更新
    if (!empty($body['supportedPaymentMethods'])) {
        $pdo->prepare("DELETE FROM store_payment_methods WHERE store_id = ?")->execute([$body['id']]);
        $ins = $pdo->prepare("INSERT IGNORE INTO store_payment_methods (store_id, method_id) VALUES (?,?)");
        foreach ($body['supportedPaymentMethods'] as $mid) {
            $ins->execute([$body['id'], $mid]);
        }
    }

    jsonResponse(['success' => true, 'id' => $body['id']]);
}

errorResponse('Method not allowed', 405);
