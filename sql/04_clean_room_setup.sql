-- ============================================
-- Clean Room Setup
-- Privacy-safe aggregation views and policies
-- ============================================

USE DATABASE SECUREINSIGHTS_CLEANROOM;
USE SCHEMA ANALYTICS;

-- ============================================
-- Aggregated Views (Only expose aggregates, never raw data)
-- Grouped by age_group and region only for sufficient sample sizes
-- ============================================

-- Bank aggregated view
CREATE OR REPLACE SECURE VIEW BANK_AGGREGATES AS
SELECT 
    age_group,
    region,
    COUNT(*) as customer_count,
    SUM(CASE WHEN has_default THEN 1 ELSE 0 END) as default_count,
    ROUND(AVG(default_amount), 2) as avg_default_amount,
    ROUND(SUM(CASE WHEN has_default THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100, 2) as default_rate_pct
FROM SECUREINSIGHTS_BANK.PRIVATE_DATA.CUSTOMERS
GROUP BY age_group, region
HAVING COUNT(*) >= 10;

-- Insurance aggregated view
CREATE OR REPLACE SECURE VIEW INSURANCE_AGGREGATES AS
SELECT 
    age_group,
    region,
    COUNT(*) as policyholder_count,
    SUM(CASE WHEN has_claim THEN 1 ELSE 0 END) as claim_count,
    ROUND(AVG(total_claim_amount), 2) as avg_claim_amount,
    ROUND(SUM(CASE WHEN has_claim THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100, 2) as claim_rate_pct
FROM SECUREINSIGHTS_INSURANCE.PRIVATE_DATA.POLICYHOLDERS
GROUP BY age_group, region
HAVING COUNT(*) >= 10;

-- Agency aggregated view
CREATE OR REPLACE SECURE VIEW AGENCY_AGGREGATES AS
SELECT 
    age_group,
    region,
    COUNT(*) as beneficiary_count,
    ROUND(AVG(subsidy_amount), 2) as avg_subsidy_amount,
    ROUND(AVG(eligibility_score), 2) as avg_eligibility_score,
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) as active_count
FROM SECUREINSIGHTS_AGENCY.PRIVATE_DATA.BENEFICIARIES
GROUP BY age_group, region
HAVING COUNT(*) >= 10;

-- ============================================
-- Combined Cross-Organization View
-- ============================================

CREATE OR REPLACE SECURE VIEW COMBINED_RISK_INSIGHTS AS
SELECT 
    COALESCE(b.age_group, i.age_group, a.age_group) as age_group,
    COALESCE(b.region, i.region, a.region) as region,
    b.customer_count as bank_customers,
    b.default_rate_pct as bank_default_rate,
    i.policyholder_count as insurance_policyholders,
    i.claim_rate_pct as insurance_claim_rate,
    a.beneficiary_count as agency_beneficiaries,
    a.avg_subsidy_amount as avg_subsidy,
    -- Combined risk score (higher = more vulnerable)
    ROUND(
        (COALESCE(b.default_rate_pct, 0) * 0.4) + 
        (COALESCE(i.claim_rate_pct, 0) * 0.3) + 
        (100 - COALESCE(a.avg_eligibility_score, 50)) * 0.3
    , 2) as combined_risk_score
FROM BANK_AGGREGATES b
FULL OUTER JOIN INSURANCE_AGGREGATES i 
    ON b.age_group = i.age_group AND b.region = i.region
FULL OUTER JOIN AGENCY_AGGREGATES a 
    ON COALESCE(b.age_group, i.age_group) = a.age_group 
    AND COALESCE(b.region, i.region) = a.region;

-- Verify data
SELECT COUNT(*) as total_segments, 
       ROUND(AVG(combined_risk_score), 2) as avg_risk,
       ROUND(MIN(combined_risk_score), 2) as min_risk,
       ROUND(MAX(combined_risk_score), 2) as max_risk
FROM COMBINED_RISK_INSIGHTS;
