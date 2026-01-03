-- ============================================
-- Audit Logging System
-- Full compliance tracking for all queries
-- ============================================

USE DATABASE SECUREINSIGHTS_CLEANROOM;
USE SCHEMA AUDIT;

-- ============================================
-- Audit Log Table
-- ============================================

CREATE OR REPLACE TABLE QUERY_AUDIT_LOG (
    audit_id VARCHAR(36) DEFAULT UUID_STRING(),
    playbook_id VARCHAR(36),
    playbook_name VARCHAR(100),
    executed_by VARCHAR(100) NOT NULL,
    organization VARCHAR(100),
    execution_timestamp TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    query_executed TEXT,
    row_count_returned INTEGER,
    execution_duration_ms INTEGER,
    purpose VARCHAR(255),
    ip_address VARCHAR(45),
    session_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'SUCCESS',
    error_message TEXT,
    PRIMARY KEY (audit_id)
);

-- ============================================
-- Simple Insert Procedure for Logging
-- ============================================

CREATE OR REPLACE PROCEDURE LOG_PLAYBOOK_EXECUTION(
    PLAYBOOK_NAME_IN VARCHAR,
    USER_IN VARCHAR,
    ORG_IN VARCHAR,
    PURPOSE_IN VARCHAR,
    STATUS_IN VARCHAR,
    ERROR_IN VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO SECUREINSIGHTS_CLEANROOM.AUDIT.QUERY_AUDIT_LOG 
        (playbook_name, executed_by, organization, purpose, status, error_message)
    VALUES 
        (:PLAYBOOK_NAME_IN, :USER_IN, :ORG_IN, :PURPOSE_IN, :STATUS_IN, :ERROR_IN);
    
    RETURN 'Logged successfully';
END;
$$;

-- ============================================
-- Audit Summary Views
-- ============================================

CREATE OR REPLACE VIEW AUDIT_SUMMARY_BY_USER AS
SELECT 
    executed_by,
    organization,
    COUNT(*) as total_queries,
    SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) as successful_queries,
    SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) as failed_queries,
    MIN(execution_timestamp) as first_query,
    MAX(execution_timestamp) as last_query
FROM QUERY_AUDIT_LOG
GROUP BY executed_by, organization;

CREATE OR REPLACE VIEW AUDIT_SUMMARY_BY_PLAYBOOK AS
SELECT 
    playbook_name,
    COUNT(*) as execution_count,
    COUNT(DISTINCT executed_by) as unique_users,
    COUNT(DISTINCT organization) as unique_orgs,
    MAX(execution_timestamp) as last_executed
FROM QUERY_AUDIT_LOG
WHERE status = 'SUCCESS'
GROUP BY playbook_name;

CREATE OR REPLACE VIEW RECENT_AUDIT_ACTIVITY AS
SELECT 
    audit_id,
    playbook_name,
    executed_by,
    organization,
    execution_timestamp,
    purpose,
    status
FROM QUERY_AUDIT_LOG
ORDER BY execution_timestamp DESC
LIMIT 100;
