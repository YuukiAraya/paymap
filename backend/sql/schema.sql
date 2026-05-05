-- PayMap データベーススキーマ
-- MySQL 5.7 / 8.0 対応
-- さくらインターネット共有サーバー / VPS で使用

CREATE DATABASE IF NOT EXISTS paymap CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE paymap;

-- ============================================================
-- 店舗テーブル
-- ============================================================
CREATE TABLE IF NOT EXISTS stores (
    id            VARCHAR(64)  NOT NULL PRIMARY KEY,
    name          VARCHAR(255) NOT NULL,
    name_en       VARCHAR(255),
    category      VARCHAR(64)  NOT NULL,
    latitude      DOUBLE       NOT NULL,
    longitude     DOUBLE       NOT NULL,
    address       TEXT,
    address_en    TEXT,
    photo_url     VARCHAR(512),
    registered_by VARCHAR(128),
    has_wifi      TINYINT(1),        -- NULL=不明, 0=なし, 1=あり
    has_power     TINYINT(1),        -- NULL=不明, 0=なし, 1=あり
    last_updated  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 緯度経度の範囲検索を高速化するインデックス
CREATE INDEX idx_stores_lat ON stores(latitude);
CREATE INDEX idx_stores_lng ON stores(longitude);
CREATE INDEX idx_stores_category ON stores(category);

-- ============================================================
-- 決済手段の確定情報（80%コンセンサス通過済み）
-- ============================================================
CREATE TABLE IF NOT EXISTS store_payment_methods (
    store_id  VARCHAR(64)  NOT NULL,
    method_id VARCHAR(64)  NOT NULL,
    PRIMARY KEY (store_id, method_id),
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 決済手段レポート（コンセンサス計算用）
-- ============================================================
CREATE TABLE IF NOT EXISTS payment_reports (
    id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    store_id         VARCHAR(64)  NOT NULL,
    method_id        VARCHAR(64)  NOT NULL,
    user_id          VARCHAR(128) NOT NULL,
    is_supported     TINYINT(1)   NOT NULL,
    reported_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_report (store_id, method_id, user_id),
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 決済手段ごとの集計（キャッシュ）
-- ============================================================
CREATE TABLE IF NOT EXISTS payment_report_summary (
    store_id          VARCHAR(64)  NOT NULL,
    method_id         VARCHAR(64)  NOT NULL,
    supported_count   INT          NOT NULL DEFAULT 0,
    unsupported_count INT          NOT NULL DEFAULT 0,
    total_reports     INT          NOT NULL DEFAULT 0,
    approval_rate     DOUBLE       NOT NULL DEFAULT 0.0,
    is_active         TINYINT(1)   NOT NULL DEFAULT 0,
    updated_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (store_id, method_id),
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- ユーザーテーブル
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    uid                  VARCHAR(128) NOT NULL PRIMARY KEY,
    display_name         VARCHAR(255),
    email                VARCHAR(255),
    total_contributions  INT          NOT NULL DEFAULT 0,
    is_premium           TINYINT(1)   NOT NULL DEFAULT 0,
    photo_url            VARCHAR(512),
    created_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- バッジテーブル
-- ============================================================
CREATE TABLE IF NOT EXISTS user_badges (
    uid      VARCHAR(128) NOT NULL,
    badge_id VARCHAR(64)  NOT NULL,
    earned_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (uid, badge_id),
    FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- お気に入りテーブル
-- ============================================================
CREATE TABLE IF NOT EXISTS user_favorites (
    uid       VARCHAR(128) NOT NULL,
    store_id  VARCHAR(64)  NOT NULL,
    added_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (uid, store_id),
    FOREIGN KEY (uid)      REFERENCES users(uid)   ON DELETE CASCADE,
    FOREIGN KEY (store_id) REFERENCES stores(id)   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 貢献履歴テーブル（ランキング詳細用）
-- ============================================================
CREATE TABLE IF NOT EXISTS contributions (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id      VARCHAR(128) NOT NULL,
    store_id     VARCHAR(64),
    method_id    VARCHAR(64),
    action       VARCHAR(64)  NOT NULL, -- 'new_store', 'first_report', 'report', 'confirm'
    points_earned INT         NOT NULL DEFAULT 0,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(uid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE INDEX idx_contrib_user ON contributions(user_id);
CREATE INDEX idx_contrib_created ON contributions(created_at);
