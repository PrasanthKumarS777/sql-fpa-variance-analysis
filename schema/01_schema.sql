-- ============================================
-- FP&A Variance Analysis System
-- Schema: Star Model
-- MySQL 8.0 | Author: Prasanth Kumar Sahu
-- ============================================

USE fpa_variance_db;

-- ─────────────────────────────────────────
-- DIMENSION 1: Date / Fiscal Calendar
-- ─────────────────────────────────────────
CREATE TABLE dim_date (
    date_id        INT PRIMARY KEY AUTO_INCREMENT,
    full_date      DATE NOT NULL UNIQUE,
    day_of_week    VARCHAR(10),
    day_num        INT,
    month_num      INT,
    month_name     VARCHAR(15),
    quarter_num    INT,
    fiscal_year    INT,
    period_label   VARCHAR(20),   -- e.g. FY2024-Q1-M01
    is_month_end   BOOLEAN DEFAULT FALSE
);

-- ─────────────────────────────────────────
-- DIMENSION 2: Department
-- ─────────────────────────────────────────
CREATE TABLE dim_department (
    dept_id    INT PRIMARY KEY AUTO_INCREMENT,
    dept_name  VARCHAR(100) NOT NULL UNIQUE,
    division   VARCHAR(50),       -- e.g. Sales, Tech, Ops
    cost_type  VARCHAR(20)        -- Cost Center / Revenue Center
);

-- ─────────────────────────────────────────
-- DIMENSION 3: Category (Chart of Accounts)
-- ─────────────────────────────────────────
CREATE TABLE dim_category (
    category_id    INT PRIMARY KEY AUTO_INCREMENT,
    category_name  VARCHAR(100) NOT NULL UNIQUE,
    account_type   VARCHAR(20)   -- Revenue / OpEx / COGS / CapEx
);

-- ─────────────────────────────────────────
-- DIMENSION 4: Region
-- ─────────────────────────────────────────
CREATE TABLE dim_region (
    region_id    INT PRIMARY KEY AUTO_INCREMENT,
    region_name  VARCHAR(100) NOT NULL UNIQUE,
    country      VARCHAR(50) DEFAULT 'USA',
    zone         VARCHAR(20)  -- North / South / East / West / Central
);

-- ─────────────────────────────────────────
-- DIMENSION 5: Payment Method
-- ─────────────────────────────────────────
CREATE TABLE dim_payment_method (
    method_id    INT PRIMARY KEY AUTO_INCREMENT,
    method_name  VARCHAR(50) NOT NULL UNIQUE   -- Bank Transfer / Credit Card etc.
);

-- ─────────────────────────────────────────
-- FACT TABLE: Transactions (Budget + Actuals)
-- ─────────────────────────────────────────
CREATE TABLE fact_transactions (
    transaction_id   VARCHAR(20) PRIMARY KEY,  -- real TXN IDs from dataset
    date_id          INT NOT NULL,
    dept_id          INT NOT NULL,
    category_id      INT NOT NULL,
    region_id        INT NOT NULL,
    method_id        INT NOT NULL,
    budget_amount    DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    actual_amount    DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    variance_amount  DECIMAL(15,2) GENERATED ALWAYS AS 
                     (actual_amount - budget_amount) STORED,
    variance_pct     DECIMAL(8,2)  GENERATED ALWAYS AS (
                     CASE WHEN budget_amount = 0 THEN NULL
                     ELSE ROUND((actual_amount - budget_amount) 
                          / budget_amount * 100, 2)
                     END) STORED,
    loaded_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (date_id)     REFERENCES dim_date(date_id),
    FOREIGN KEY (dept_id)     REFERENCES dim_department(dept_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    FOREIGN KEY (region_id)   REFERENCES dim_region(region_id),
    FOREIGN KEY (method_id)   REFERENCES dim_payment_method(method_id),

    INDEX idx_date     (date_id),
    INDEX idx_dept     (dept_id),
    INDEX idx_category (category_id),
    INDEX idx_region   (region_id)
);
