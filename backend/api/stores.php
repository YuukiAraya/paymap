<?php
/**
 * 店舗 API
 * GET  /api/stores.php?lat=35.6&lng=139.7&radius=20   → 近くの店舗一覧
 * POST /api/stores.php                                  → 店舗登録・更新 (upsert)
 */

require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];

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
    $rows = $stmt->fetchAll();

    $stores = array_map(function($row) {
        return [
            'id'                       => $row['id'],
            'name'                     => $row['name'],
            'nameEn'                   => $row['name_en'],
            'category'                 => $row['category'],
            'location'                 => ['latitude' => (float)$row['latitude'], 'longitude' => (float)$row['longitude']],
            'address'                  => $row['address'],
            'addressEn'                => $row['address_en'],
            'photoURL'                 => $row['photo_url'],
            'registeredByUid'          => $row['registered_by'],
            'hasWifi'                  => $row['has_wifi'] === null ? null : (bool)$row['has_wifi'],
            'hasPower'                 => $row['has_power'] === null ? null : (bool)$row['has_power'],
            'supportedPaymentMethods'  => $row['confirmed_methods'] ? explode(',', $row['confirmed_methods']) : [],
        ];
    }, $rows);

    jsonResponse(['stores' => $stores]);

} elseif ($method === 'POST') {
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
        ':name_en'       => $body['nameEn']      ?? null,
        ':category'      => $body['category'],
        ':lat'           => $loc['latitude']     ?? 0,
        ':lng'           => $loc['longitude']    ?? 0,
        ':address'       => $body['address']     ?? null,
        ':address_en'    => $body['addressEn']   ?? null,
        ':photo_url'     => $body['photoURL']    ?? null,
        ':registered_by' => $body['registeredByUid'] ?? null,
        ':has_wifi'      => isset($body['hasWifi'])  ? (int)$body['hasWifi']  : null,
        ':has_power'     => isset($body['hasPower']) ? (int)$body['hasPower'] : null,
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

} else {
    errorResponse('Method not allowed', 405);
}
