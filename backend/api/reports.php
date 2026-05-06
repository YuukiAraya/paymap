<?php
/**
 * 決済手段レポート API（80%コンセンサス）
 * GET  /api/reports.php?store_id=xxx                   → 店舗の集計サマリ一覧
 * POST /api/reports.php  body: { store_id, method_id, user_id, is_supported }
 */

require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];

// ============================================================
// GET: 店舗の決済手段集計を取得
// ============================================================
if ($method === 'GET') {
    $storeId = $_GET['store_id'] ?? null;
    if (!$storeId) {
        errorResponse('store_id is required');
    }
    $pdo  = getDB();
    $stmt = $pdo->prepare("
        SELECT method_id, supported_count, unsupported_count, total_reports, approval_rate, is_active
        FROM payment_report_summary
        WHERE store_id = ?
    ");
    $stmt->execute([$storeId]);
    $rows = $stmt->fetchAll();

    $reports = array_map(function ($row) {
        return [
            'methodId'         => $row['method_id'],
            'supportedCount'   => (int)$row['supported_count'],
            'unsupportedCount' => (int)$row['unsupported_count'],
            'totalReports'     => (int)$row['total_reports'],
            'approvalRate'     => (float)$row['approval_rate'],
            'isActive'         => (bool)$row['is_active'],
        ];
    }, $rows);

    jsonResponse(['reports' => $reports]);
}

// ============================================================
// POST: レポート投稿 + 80%コンセンサス計算
// ============================================================
if ($method === 'POST') {
    $body        = getRequestBody();
    $storeId     = $body['store_id']    ?? null;
    $methodId    = $body['method_id']   ?? null;
    $userId      = $body['user_id']     ?? null;
    $isSupported = isset($body['is_supported']) ? (bool)$body['is_supported'] : null;

    if (!$storeId || !$methodId || !$userId || $isSupported === null) {
        errorResponse('store_id, method_id, user_id, is_supported are required');
    }

    $pdo = getDB();
    $pdo->beginTransaction();

    try {
        // UPSERT レポート（1ユーザー1メソッドで上書き）
        $pdo->prepare("
            INSERT INTO payment_reports (store_id, method_id, user_id, is_supported)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE is_supported = VALUES(is_supported), reported_at = NOW()
        ")->execute([$storeId, $methodId, $userId, (int)$isSupported]);

        // 集計を再計算
        $agg = $pdo->prepare("
            SELECT
                SUM(is_supported = 1) AS supported_count,
                SUM(is_supported = 0) AS unsupported_count,
                COUNT(*)              AS total
            FROM payment_reports
            WHERE store_id = ? AND method_id = ?
        ");
        $agg->execute([$storeId, $methodId]);
        $row = $agg->fetch();

        $supported   = (int)$row['supported_count'];
        $unsupported = (int)$row['unsupported_count'];
        $total       = (int)$row['total'];
        $rate        = $total > 0 ? $supported / $total : 0.0;
        $isActive    = $rate >= 0.8 ? 1 : 0;

        // サマリを UPSERT
        $pdo->prepare("
            INSERT INTO payment_report_summary
                (store_id, method_id, supported_count, unsupported_count, total_reports, approval_rate, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                supported_count   = VALUES(supported_count),
                unsupported_count = VALUES(unsupported_count),
                total_reports     = VALUES(total_reports),
                approval_rate     = VALUES(approval_rate),
                is_active         = VALUES(is_active)
        ")->execute([$storeId, $methodId, $supported, $unsupported, $total, $rate, $isActive]);

        // 80%到達したら確定メソッドに追加、外れたら削除
        if ($isActive) {
            $pdo->prepare("INSERT IGNORE INTO store_payment_methods (store_id, method_id) VALUES (?,?)")
                ->execute([$storeId, $methodId]);
        } else {
            $pdo->prepare("DELETE FROM store_payment_methods WHERE store_id=? AND method_id=?")
                ->execute([$storeId, $methodId]);
        }

        $pdo->commit();
        jsonResponse([
            'success'       => true,
            'approval_rate' => round($rate * 100),
            'is_active'     => (bool)$isActive,
        ]);
    } catch (\Exception $e) {
        $pdo->rollBack();
        errorResponse('Transaction failed: ' . $e->getMessage(), 500);
    }
}

errorResponse('Method not allowed', 405);
