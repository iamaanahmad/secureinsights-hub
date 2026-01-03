-- ============================================
-- Private Data Tables (Never Exposed Directly)
-- Each organization's sensitive data
-- ============================================

USE DATABASE SECUREINSIGHTS_BANK;
USE SCHEMA PRIVATE_DATA;

-- Bank: Customer financial data
CREATE OR REPLACE TABLE CUSTOMERS (
    customer_id VARCHAR(36) PRIMARY KEY,
    age_group VARCHAR(20),           -- '18-25', '26-35', '36-45', '46-55', '56-65', '65+'
    region VARCHAR(50),
    income_bracket VARCHAR(20),      -- 'low', 'medium', 'high'
    account_type VARCHAR(30),
    credit_score_band VARCHAR(20),   -- 'poor', 'fair', 'good', 'excellent'
    has_default BOOLEAN,
    default_amount DECIMAL(12,2),
    account_balance DECIMAL(12,2),
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Bank: Transaction patterns (aggregated)
CREATE OR REPLACE TABLE TRANSACTION_PATTERNS (
    customer_id VARCHAR(36),
    month_year VARCHAR(7),
    transaction_count INTEGER,
    avg_transaction_amount DECIMAL(10,2),
    category VARCHAR(30),
    anomaly_flag BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id)
);

USE DATABASE SECUREINSIGHTS_INSURANCE;
USE SCHEMA PRIVATE_DATA;

-- Insurance: Policy and claims data
CREATE OR REPLACE TABLE POLICYHOLDERS (
    policyholder_id VARCHAR(36) PRIMARY KEY,
    age_group VARCHAR(20),
    region VARCHAR(50),
    policy_type VARCHAR(30),         -- 'health', 'life', 'property', 'auto'
    premium_bracket VARCHAR(20),
    risk_category VARCHAR(20),       -- 'low', 'medium', 'high'
    has_claim BOOLEAN,
    claim_count INTEGER DEFAULT 0,
    total_claim_amount DECIMAL(12,2) DEFAULT 0,
    policy_start_date DATE,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Insurance: Claim patterns
CREATE OR REPLACE TABLE CLAIM_PATTERNS (
    policyholder_id VARCHAR(36),
    claim_year INTEGER,
    claim_type VARCHAR(30),
    claim_amount DECIMAL(12,2),
    claim_status VARCHAR(20),        -- 'approved', 'denied', 'pending'
    fraud_flag BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (policyholder_id) REFERENCES POLICYHOLDERS(policyholder_id)
);

USE DATABASE SECUREINSIGHTS_AGENCY;
USE SCHEMA PRIVATE_DATA;

-- Public Agency: Subsidy and welfare data
CREATE OR REPLACE TABLE BENEFICIARIES (
    beneficiary_id VARCHAR(36) PRIMARY KEY,
    age_group VARCHAR(20),
    region VARCHAR(50),
    household_size INTEGER,
    income_level VARCHAR(20),        -- 'below_poverty', 'low', 'medium'
    subsidy_type VARCHAR(30),        -- 'housing', 'food', 'healthcare', 'education'
    subsidy_amount DECIMAL(10,2),
    eligibility_score DECIMAL(5,2),
    enrollment_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Agency: Program effectiveness tracking
CREATE OR REPLACE TABLE PROGRAM_OUTCOMES (
    beneficiary_id VARCHAR(36),
    program_year INTEGER,
    outcome_metric VARCHAR(30),
    outcome_value DECIMAL(10,2),
    improvement_flag BOOLEAN,
    FOREIGN KEY (beneficiary_id) REFERENCES BENEFICIARIES(beneficiary_id)
);
