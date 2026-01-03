-- ============================================
-- Sample Data Generation
-- De-identified synthetic data for demo
-- ============================================

USE WAREHOUSE SECUREINSIGHTS_WH;

-- ============================================
-- Bank Sample Data
-- ============================================
USE DATABASE SECUREINSIGHTS_BANK;
USE SCHEMA PRIVATE_DATA;

INSERT INTO CUSTOMERS (customer_id, age_group, region, income_bracket, account_type, credit_score_band, has_default, default_amount, account_balance)
WITH age_groups AS (
    SELECT column1 AS val FROM VALUES ('18-25'), ('26-35'), ('36-45'), ('46-55'), ('56-65'), ('65+')
),
regions AS (
    SELECT column1 AS val FROM VALUES ('Urban-North'), ('Urban-South'), ('Rural-North'), ('Rural-South'), ('Suburban-East'), ('Suburban-West')
),
income AS (
    SELECT column1 AS val FROM VALUES ('low'), ('medium'), ('high')
),
accounts AS (
    SELECT column1 AS val FROM VALUES ('savings'), ('checking'), ('business')
),
credit AS (
    SELECT column1 AS val FROM VALUES ('poor'), ('fair'), ('good'), ('excellent')
)
SELECT 
    UUID_STRING(),
    a.val,
    r.val,
    i.val,
    ac.val,
    c.val,
    CASE WHEN UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) > 0.85 THEN TRUE ELSE FALSE END,
    CASE WHEN UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) > 0.85 THEN ROUND(UNIFORM(0::FLOAT, 10000::FLOAT, RANDOM()), 2) ELSE 0 END,
    ROUND(UNIFORM(1000::FLOAT, 50000::FLOAT, RANDOM()), 2)
FROM age_groups a
CROSS JOIN regions r
CROSS JOIN income i
CROSS JOIN accounts ac
CROSS JOIN credit c;

-- ============================================
-- Insurance Sample Data
-- ============================================
USE DATABASE SECUREINSIGHTS_INSURANCE;
USE SCHEMA PRIVATE_DATA;

INSERT INTO POLICYHOLDERS (policyholder_id, age_group, region, policy_type, premium_bracket, risk_category, has_claim, claim_count, total_claim_amount, policy_start_date)
WITH age_groups AS (
    SELECT column1 AS val FROM VALUES ('18-25'), ('26-35'), ('36-45'), ('46-55'), ('56-65'), ('65+')
),
regions AS (
    SELECT column1 AS val FROM VALUES ('Urban-North'), ('Urban-South'), ('Rural-North'), ('Rural-South'), ('Suburban-East'), ('Suburban-West')
),
policy AS (
    SELECT column1 AS val FROM VALUES ('health'), ('life'), ('property'), ('auto')
),
premium AS (
    SELECT column1 AS val FROM VALUES ('low'), ('medium'), ('high')
),
risk AS (
    SELECT column1 AS val FROM VALUES ('low'), ('medium'), ('high')
)
SELECT 
    UUID_STRING(),
    a.val,
    r.val,
    p.val,
    pr.val,
    ri.val,
    CASE WHEN UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) > 0.7 THEN TRUE ELSE FALSE END,
    FLOOR(UNIFORM(0::FLOAT, 5::FLOAT, RANDOM())),
    ROUND(UNIFORM(0::FLOAT, 25000::FLOAT, RANDOM()), 2),
    DATEADD(day, -FLOOR(UNIFORM(0::FLOAT, 1000::FLOAT, RANDOM())), CURRENT_DATE())
FROM age_groups a
CROSS JOIN regions r
CROSS JOIN policy p
CROSS JOIN premium pr
CROSS JOIN risk ri;

-- ============================================
-- Agency Sample Data
-- ============================================
USE DATABASE SECUREINSIGHTS_AGENCY;
USE SCHEMA PRIVATE_DATA;

INSERT INTO BENEFICIARIES (beneficiary_id, age_group, region, household_size, income_level, subsidy_type, subsidy_amount, eligibility_score, enrollment_date, is_active)
WITH age_groups AS (
    SELECT column1 AS val FROM VALUES ('18-25'), ('26-35'), ('36-45'), ('46-55'), ('56-65'), ('65+')
),
regions AS (
    SELECT column1 AS val FROM VALUES ('Urban-North'), ('Urban-South'), ('Rural-North'), ('Rural-South'), ('Suburban-East'), ('Suburban-West')
),
income AS (
    SELECT column1 AS val FROM VALUES ('below_poverty'), ('low'), ('medium')
),
subsidy AS (
    SELECT column1 AS val FROM VALUES ('housing'), ('food'), ('healthcare'), ('education')
)
SELECT 
    UUID_STRING(),
    a.val,
    r.val,
    FLOOR(UNIFORM(1::FLOAT, 7::FLOAT, RANDOM())),
    i.val,
    s.val,
    ROUND(UNIFORM(500::FLOAT, 5500::FLOAT, RANDOM()), 2),
    ROUND(UNIFORM(0::FLOAT, 100::FLOAT, RANDOM()), 2),
    DATEADD(day, -FLOOR(UNIFORM(0::FLOAT, 500::FLOAT, RANDOM())), CURRENT_DATE()),
    CASE WHEN UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) > 0.1 THEN TRUE ELSE FALSE END
FROM age_groups a
CROSS JOIN regions r
CROSS JOIN income i
CROSS JOIN subsidy s;

-- Verify data loaded
SELECT 'BANK' as source, COUNT(*) as row_count FROM SECUREINSIGHTS_BANK.PRIVATE_DATA.CUSTOMERS
UNION ALL
SELECT 'INSURANCE', COUNT(*) FROM SECUREINSIGHTS_INSURANCE.PRIVATE_DATA.POLICYHOLDERS
UNION ALL
SELECT 'AGENCY', COUNT(*) FROM SECUREINSIGHTS_AGENCY.PRIVATE_DATA.BENEFICIARIES;
