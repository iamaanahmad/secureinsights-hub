-- ============================================
-- Ethical Analytics Playbooks
-- Pre-approved, governed queries for insights
-- ============================================

USE DATABASE SECUREINSIGHTS_CLEANROOM;
USE SCHEMA PLAYBOOKS;

-- ============================================
-- Playbook Registry Table
-- ============================================

CREATE OR REPLACE TABLE PLAYBOOK_REGISTRY (
    playbook_id VARCHAR(36) DEFAULT UUID_STRING(),
    playbook_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),           -- 'risk', 'inclusion', 'fraud', 'bias'
    query_template TEXT NOT NULL,
    min_aggregation_threshold INTEGER DEFAULT 10,
    requires_approval BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    created_by VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (playbook_id)
);

-- ============================================
-- Pre-Approved Playbooks
-- ============================================

-- Playbook 1: Combined Risk by Demographics
INSERT INTO PLAYBOOK_REGISTRY (playbook_name, description, category, query_template, created_by)
VALUES (
    'Combined Risk by Age Group',
    'Identifies which age groups show the highest combined default and insurance claim risk',
    'risk',
    '
    SELECT 
        age_group,
        SUM(bank_customers) as total_bank_customers,
        ROUND(AVG(bank_default_rate), 2) as avg_default_rate,
        SUM(insurance_policyholders) as total_policyholders,
        ROUND(AVG(insurance_claim_rate), 2) as avg_claim_rate,
        ROUND(AVG(combined_risk_score), 2) as avg_combined_risk
    FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.COMBINED_RISK_INSIGHTS
    GROUP BY age_group
    ORDER BY avg_combined_risk DESC
    ',
    'system'
);

-- Playbook 2: Regional Subsidy Gap Analysis
INSERT INTO PLAYBOOK_REGISTRY (playbook_name, description, category, query_template, created_by)
VALUES (
    'Regional Subsidy Gap Analysis',
    'Identifies regions receiving disproportionately low subsidies relative to risk exposure',
    'inclusion',
    '
    SELECT 
        region,
        ROUND(AVG(combined_risk_score), 2) as avg_risk_score,
        ROUND(AVG(avg_subsidy), 2) as avg_subsidy_amount,
        SUM(agency_beneficiaries) as total_beneficiaries,
        ROUND(AVG(combined_risk_score) / NULLIF(AVG(avg_subsidy), 0) * 1000, 2) as risk_to_subsidy_ratio,
        CASE 
            WHEN AVG(combined_risk_score) > 50 AND AVG(avg_subsidy) < 2000 THEN ''HIGH GAP''
            WHEN AVG(combined_risk_score) > 30 AND AVG(avg_subsidy) < 2500 THEN ''MODERATE GAP''
            ELSE ''ADEQUATE''
        END as coverage_assessment
    FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.COMBINED_RISK_INSIGHTS
    GROUP BY region
    ORDER BY risk_to_subsidy_ratio DESC
    ',
    'system'
);

-- Playbook 3: Underserved Population Detection
INSERT INTO PLAYBOOK_REGISTRY (playbook_name, description, category, query_template, created_by)
VALUES (
    'Underserved Population Detection',
    'Identifies demographic segments with high risk but low financial service coverage',
    'inclusion',
    '
    SELECT 
        age_group,
        region,
        bank_customers,
        insurance_policyholders,
        agency_beneficiaries,
        combined_risk_score,
        CASE 
            WHEN combined_risk_score > 60 AND COALESCE(agency_beneficiaries, 0) < 50 THEN ''CRITICALLY UNDERSERVED''
            WHEN combined_risk_score > 40 AND COALESCE(agency_beneficiaries, 0) < 100 THEN ''UNDERSERVED''
            ELSE ''ADEQUATELY SERVED''
        END as service_status
    FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.COMBINED_RISK_INSIGHTS
    WHERE combined_risk_score > 30
    ORDER BY combined_risk_score DESC
    ',
    'system'
);

-- Playbook 4: Fraud Risk Indicators
INSERT INTO PLAYBOOK_REGISTRY (playbook_name, description, category, query_template, created_by)
VALUES (
    'Cross-Sector Fraud Risk Indicators',
    'Identifies segments showing anomalous patterns across banking and insurance',
    'fraud',
    '
    SELECT 
        age_group,
        region,
        bank_default_rate,
        insurance_claim_rate,
        ROUND(ABS(bank_default_rate - insurance_claim_rate), 2) as rate_divergence,
        CASE 
            WHEN bank_default_rate > 30 AND insurance_claim_rate > 40 THEN ''HIGH FRAUD RISK''
            WHEN ABS(bank_default_rate - insurance_claim_rate) > 25 THEN ''ANOMALOUS PATTERN''
            ELSE ''NORMAL''
        END as fraud_indicator
    FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.COMBINED_RISK_INSIGHTS
    WHERE bank_default_rate IS NOT NULL AND insurance_claim_rate IS NOT NULL
    ORDER BY rate_divergence DESC
    ',
    'system'
);

-- Playbook 5: Bias Detection in Subsidies
INSERT INTO PLAYBOOK_REGISTRY (playbook_name, description, category, query_template, created_by)
VALUES (
    'Subsidy Distribution Bias Analysis',
    'Detects potential systemic bias in subsidy allocation across demographics',
    'bias',
    '
    WITH overall_avg AS (
        SELECT AVG(avg_subsidy) as global_avg_subsidy
        FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.COMBINED_RISK_INSIGHTS
    )
    SELECT 
        c.age_group,
        c.region,
        c.avg_subsidy,
        o.global_avg_subsidy,
        ROUND((c.avg_subsidy - o.global_avg_subsidy) / o.global_avg_subsidy * 100, 2) as subsidy_variance_pct,
        c.combined_risk_score,
        CASE 
            WHEN c.avg_subsidy < o.global_avg_subsidy * 0.7 AND c.combined_risk_score > 40 
                THEN ''POTENTIAL BIAS - UNDERFUNDED HIGH RISK''
            WHEN c.avg_subsidy > o.global_avg_subsidy * 1.3 AND c.combined_risk_score < 30 
                THEN ''POTENTIAL BIAS - OVERFUNDED LOW RISK''
            ELSE ''NO SIGNIFICANT BIAS''
        END as bias_assessment
    FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.COMBINED_RISK_INSIGHTS c
    CROSS JOIN overall_avg o
    ORDER BY ABS(subsidy_variance_pct) DESC
    ',
    'system'
);
