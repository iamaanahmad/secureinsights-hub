-- ============================================
-- Streams & Tasks for Automated Intelligence
-- Daily/weekly refresh and anomaly detection
-- ============================================

USE DATABASE SECUREINSIGHTS_CLEANROOM;
USE SCHEMA ANALYTICS;

-- ============================================
-- Anomaly Detection Table
-- ============================================

CREATE OR REPLACE TABLE ANOMALY_ALERTS (
    alert_id VARCHAR(36) DEFAULT UUID_STRING(),
    alert_type VARCHAR(50),
    severity VARCHAR(20),
    age_group VARCHAR(20),
    region VARCHAR(50),
    metric_name VARCHAR(50),
    previous_value DECIMAL(10,2),
    current_value DECIMAL(10,2),
    change_pct DECIMAL(10,2),
    description TEXT,
    detected_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    is_acknowledged BOOLEAN DEFAULT FALSE,
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMP_NTZ,
    PRIMARY KEY (alert_id)
);

-- ============================================
-- Risk Snapshot Table (for change tracking)
-- ============================================

CREATE OR REPLACE TABLE RISK_SNAPSHOTS (
    snapshot_id VARCHAR(36) DEFAULT UUID_STRING(),
    snapshot_date DATE DEFAULT CURRENT_DATE(),
    age_group VARCHAR(20),
    region VARCHAR(50),
    combined_risk_score DECIMAL(10,2),
    bank_default_rate DECIMAL(10,2),
    insurance_claim_rate DECIMAL(10,2),
    avg_subsidy DECIMAL(10,2),
    PRIMARY KEY (snapshot_id)
);

-- ============================================
-- Stored Procedure for Anomaly Detection
-- Lowered thresholds to catch more alerts
-- ============================================

CREATE OR REPLACE PROCEDURE DETECT_ANOMALIES()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    -- Clear old unacknowledged alerts to avoid duplicates
    DELETE FROM ANOMALY_ALERTS WHERE is_acknowledged = FALSE;
    
    -- Detect elevated risk scores (threshold: 25+)
    INSERT INTO ANOMALY_ALERTS (alert_type, severity, age_group, region, metric_name, current_value, description)
    SELECT 
        'RISK_SPIKE',
        CASE 
            WHEN combined_risk_score > 35 THEN 'CRITICAL'
            WHEN combined_risk_score > 30 THEN 'HIGH'
            ELSE 'MEDIUM'
        END,
        age_group,
        region,
        'combined_risk_score',
        combined_risk_score,
        'Elevated combined risk score (' || ROUND(combined_risk_score, 1) || ') detected for ' || age_group || ' in ' || region
    FROM COMBINED_RISK_INSIGHTS
    WHERE combined_risk_score > 25;
    
    -- Detect subsidy gaps (high risk + low subsidy)
    INSERT INTO ANOMALY_ALERTS (alert_type, severity, age_group, region, metric_name, current_value, description)
    SELECT 
        'SUBSIDY_GAP',
        CASE 
            WHEN combined_risk_score > 30 AND avg_subsidy < 2500 THEN 'CRITICAL'
            WHEN combined_risk_score > 25 AND avg_subsidy < 3000 THEN 'HIGH'
            ELSE 'MEDIUM'
        END,
        age_group,
        region,
        'subsidy_coverage',
        avg_subsidy,
        'Potential subsidy gap: Risk score ' || ROUND(combined_risk_score, 1) || ' with avg subsidy $' || ROUND(avg_subsidy, 0)
    FROM COMBINED_RISK_INSIGHTS
    WHERE combined_risk_score > 20 AND avg_subsidy < 3500;
    
    -- Detect high claim rates
    INSERT INTO ANOMALY_ALERTS (alert_type, severity, age_group, region, metric_name, current_value, description)
    SELECT 
        'HIGH_CLAIMS',
        CASE 
            WHEN insurance_claim_rate > 35 THEN 'CRITICAL'
            WHEN insurance_claim_rate > 30 THEN 'HIGH'
            ELSE 'MEDIUM'
        END,
        age_group,
        region,
        'insurance_claim_rate',
        insurance_claim_rate,
        'High insurance claim rate (' || ROUND(insurance_claim_rate, 1) || '%) for ' || age_group || ' in ' || region
    FROM COMBINED_RISK_INSIGHTS
    WHERE insurance_claim_rate > 25;
    
    RETURN 'Anomaly detection completed at ' || CURRENT_TIMESTAMP() || '. Found ' || 
           (SELECT COUNT(*) FROM ANOMALY_ALERTS WHERE is_acknowledged = FALSE) || ' alerts.';
END;
$$;

-- ============================================
-- Procedure to Capture Risk Snapshot
-- ============================================

CREATE OR REPLACE PROCEDURE CAPTURE_RISK_SNAPSHOT()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO RISK_SNAPSHOTS (age_group, region, combined_risk_score, bank_default_rate, insurance_claim_rate, avg_subsidy)
    SELECT 
        age_group,
        region,
        combined_risk_score,
        bank_default_rate,
        insurance_claim_rate,
        avg_subsidy
    FROM COMBINED_RISK_INSIGHTS;
    
    RETURN 'Snapshot captured at ' || CURRENT_TIMESTAMP();
END;
$$;

-- ============================================
-- Scheduled Tasks
-- ============================================

CREATE OR REPLACE TASK DAILY_RISK_REFRESH
    WAREHOUSE = SECUREINSIGHTS_WH
    SCHEDULE = 'USING CRON 0 6 * * * UTC'
AS
    CALL DETECT_ANOMALIES();

CREATE OR REPLACE TASK DAILY_SNAPSHOT
    WAREHOUSE = SECUREINSIGHTS_WH
    SCHEDULE = 'USING CRON 0 5 * * * UTC'
AS
    CALL CAPTURE_RISK_SNAPSHOT();

-- To enable tasks, run:
-- ALTER TASK SECUREINSIGHTS_CLEANROOM.ANALYTICS.DAILY_RISK_REFRESH RESUME;
-- ALTER TASK SECUREINSIGHTS_CLEANROOM.ANALYTICS.DAILY_SNAPSHOT RESUME;
