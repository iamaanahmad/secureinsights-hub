-- ============================================
-- Cortex AI / AI SQL Integration
-- Plain-language explanations for insights
-- ============================================

USE DATABASE SECUREINSIGHTS_CLEANROOM;
USE SCHEMA ANALYTICS;

-- ============================================
-- Enable cross-region inference first (run as ACCOUNTADMIN):
-- ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
-- ============================================

-- ============================================
-- AI Explanation Generation Function
-- ============================================

CREATE OR REPLACE FUNCTION GENERATE_INSIGHT_EXPLANATION(
    p_age_group VARCHAR,
    p_region VARCHAR,
    p_risk_score FLOAT,
    p_default_rate FLOAT,
    p_claim_rate FLOAT,
    p_subsidy_amount FLOAT
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'mistral-large2',
        CONCAT(
            'You are an AI analyst for a privacy-preserving financial inclusion platform. ',
            'Generate a brief, actionable insight (2-3 sentences) based on this aggregated data: ',
            'Demographics: ', p_age_group, ' age group in ', p_region, '. ',
            'Combined Risk Score: ', p_risk_score::VARCHAR, ' (scale 0-100, higher = more vulnerable). ',
            'Bank Default Rate: ', COALESCE(p_default_rate, 0)::VARCHAR, '%. ',
            'Insurance Claim Rate: ', COALESCE(p_claim_rate, 0)::VARCHAR, '%. ',
            'Average Subsidy Amount: $', COALESCE(p_subsidy_amount, 0)::VARCHAR, '. ',
            'Focus on identifying vulnerabilities, potential inclusion gaps, and actionable recommendations. ',
            'Be specific but avoid revealing individual-level information.'
        )
    )
$$;

-- ============================================
-- Alternative using llama model
-- ============================================

CREATE OR REPLACE FUNCTION GENERATE_INSIGHT_LLAMA(
    p_age_group VARCHAR,
    p_region VARCHAR,
    p_risk_score FLOAT,
    p_default_rate FLOAT,
    p_claim_rate FLOAT,
    p_subsidy_amount FLOAT
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'llama3.1-8b',
        CONCAT(
            'Generate a 2-sentence insight about this demographic: ',
            'Age: ', p_age_group, ', Region: ', p_region, ', ',
            'Risk Score: ', p_risk_score::VARCHAR, '/100, ',
            'Default Rate: ', COALESCE(p_default_rate, 0)::VARCHAR, '%, ',
            'Claim Rate: ', COALESCE(p_claim_rate, 0)::VARCHAR, '%, ',
            'Avg Subsidy: $', COALESCE(p_subsidy_amount, 0)::VARCHAR, '. ',
            'Focus on financial inclusion gaps.'
        )
    )
$$;

-- ============================================
-- Pre-computed Insights Table
-- ============================================

CREATE OR REPLACE TABLE AI_GENERATED_INSIGHTS (
    insight_id VARCHAR(36) DEFAULT UUID_STRING(),
    age_group VARCHAR(20),
    region VARCHAR(50),
    risk_score DECIMAL(10,2),
    insight_text TEXT,
    insight_category VARCHAR(50),
    generated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    is_current BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (insight_id)
);

-- ============================================
-- Procedure to Generate All Insights
-- ============================================

CREATE OR REPLACE PROCEDURE GENERATE_ALL_INSIGHTS()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    UPDATE AI_GENERATED_INSIGHTS SET is_current = FALSE WHERE is_current = TRUE;
    
    INSERT INTO AI_GENERATED_INSIGHTS (age_group, region, risk_score, insight_text, insight_category)
    SELECT 
        age_group,
        region,
        combined_risk_score,
        GENERATE_INSIGHT_EXPLANATION(
            age_group, 
            region, 
            combined_risk_score,
            bank_default_rate,
            insurance_claim_rate,
            avg_subsidy
        ),
        CASE 
            WHEN combined_risk_score > 60 THEN 'CRITICAL'
            WHEN combined_risk_score > 40 THEN 'HIGH_PRIORITY'
            ELSE 'MONITORING'
        END
    FROM COMBINED_RISK_INSIGHTS
    WHERE combined_risk_score > 30;
    
    RETURN 'Generated ' || (SELECT COUNT(*) FROM AI_GENERATED_INSIGHTS WHERE is_current = TRUE) || ' insights';
END;
$$;

-- ============================================
-- View for Dashboard
-- ============================================

CREATE OR REPLACE VIEW CURRENT_AI_INSIGHTS AS
SELECT 
    insight_id,
    age_group,
    region,
    risk_score,
    insight_text,
    insight_category,
    generated_at
FROM AI_GENERATED_INSIGHTS
WHERE is_current = TRUE
ORDER BY risk_score DESC;
