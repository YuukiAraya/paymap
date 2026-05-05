<?php
/**
 * 写真アップロード API
 * POST /api/upload.php  (multipart/form-data)
 *   store_id: string
 *   photo:    file (JPEG/PNG, max 5MB)
 */

require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    errorResponse('POST only', 405);
}

$storeId = $_POST['store_id'] ?? null;
if (!$storeId) { errorResponse('store_id is required'); }

if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
    errorResponse('photo file is required');
}

$file     = $_FILES['photo'];
$maxSize  = 5 * 1024 * 1024; // 5MB
if ($file['size'] > $maxSize) { errorResponse('File too large (max 5MB)'); }

$allowed = ['image/jpeg', 'image/png', 'image/jpg'];
$finfo   = new finfo(FILEINFO_MIME_TYPE);
$mime    = $finfo->file($file['tmp_name']);
if (!in_array($mime, $allowed, true)) { errorResponse('Only JPEG/PNG allowed'); }

// アップロードディレクトリ確認・作成
if (!is_dir(UPLOAD_DIR)) {
    mkdir(UPLOAD_DIR, 0755, true);
}

$ext      = $mime === 'image/png' ? 'png' : 'jpg';
$filename = 'store_' . preg_replace('/[^a-zA-Z0-9_-]/', '_', $storeId) . '_' . time() . '.' . $ext;
$destPath = UPLOAD_DIR . $filename;

if (!move_uploaded_file($file['tmp_name'], $destPath)) {
    errorResponse('Failed to save file', 500);
}

$photoUrl = UPLOAD_BASE_URL . $filename;

// データベースの store の photo_url を更新
$pdo = getDB();
$pdo->prepare("UPDATE stores SET photo_url = ? WHERE id = ?")
    ->execute([$photoUrl, $storeId]);

jsonResponse(['success' => true, 'url' => $photoUrl]);
