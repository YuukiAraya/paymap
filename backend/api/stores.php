<?php
/**
 * 店舗 API
 * GET  /api/stores.php?lat=35.6&lng=139.7&radius=20   → 近くの店舗一覧（半径 km）
 * GET  /api/stores.php?uid=xxx                         → ユーザーが登録した店舗一覧
 * GET  /api/stores.php?ids=id1,id2,id3                 → IDで一括取得（お気に入り用）
 * POST /api/stores.php                                  → 店舗登録・更新 (upsert)
 * POST /api/stores.php?action=update_facilities        → WiFi/電源のみ更新
 */

require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

// ============================================================
// GET: ユーザー登録店舗
// ============================================================
if ($method === 'GET' && isset($_GET['uid'])) {
    $uid  = $_GET['uid'];
    $pdo  = getDB();
    $stmt = $pdo->prepare("
        SELECT s.*, GROUP_CONCAT(spm.method_id ORDER BY spm.method_id) AS confirmed_methods
        FROM stores s
        LEFT JOIN store_payment_methods spm ON s.id = spm.store_id
        WHERE s.registered_by = :uid
        GROUP BY s.id
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
    $stmt = $pdo->prepare("
        SELECT s.*, GROUP_CONCAT(spm.method_id ORDER BY spm.method_id) AS confirmed_methods
        FROM stores s
        LEFT JOIN store_payment_methods spm ON s.id = spm.store_id
        WHERE s.id IN ($placeholders)
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
    $stmt = $pdo->prepare("
        SELECT s.*, GROUP_CONCAT(spm.method_id ORDER BY spm.method_id) AS confirmed_methods
        FROM stores s
        LEFT JOIN store_payment_methods spm ON s.id = spm.store_id
        WHERE s.latitude  BETWEEN :latMin AND :latMax
          AND s.longitude BETWEEN :lngMin AND :lngMax
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
// POST: WiFi / 電源のみ更新
// ============================================================
if ($method === 'POST' && $action === 'update_facilities') {
    $body    = getRequestBody();
    $storeId = $body['store_id'] ?? null;
    if (!$storeId) {
        errorResponse('store_id is required');
    }
    $pdo = getDB();
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
