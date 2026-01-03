-- ============================================
-- SecureInsights Hub - Master Setup Script
-- Run this to deploy the complete solution
-- ============================================

-- IMPORTANT: Run each script in order
-- Some scripts depend on objects created in previous scripts

-- Step 1: Create databases and warehouses
-- !source sql/01_setup_databases.sql

-- Step 2: Create private data tables
-- !source sql/02_create_private_tables.sql

-- Step 3: Load sample data
-- !source sql/03_sample_data.sql

-- Step 4: Setup clean room views
-- !source sql/04_clean_room_setup.sql

-- Step 5: Create ethical playbooks
-- !source sql/05_ethical_playbooks.sql

-- Step 6: Setup audit logging
-- !source sql/06_audit_logging.sql

-- Step 7: Configure streams and tasks
-- !source sql/07_streams_tasks.sql

-- Step 8: Setup Cortex AI explanations
-- !source sql/08_cortex_ai_explanations.sql

-- Step 9: Apply Horizon governance
-- !source sql/09_horizon_governance.sql

-- ============================================
-- Verification Queries
-- ============================================

-- Check databases created
SHOW DATABASES LIKE 'SECUREINSIGHTS%';

-- Check tables in each database
SELECT table_catalog, table_schema, table_name 
FROM information_schema.tables 
WHERE table_catalog LIKE 'SECUREINSIGHTS%'
ORDER BY table_catalog, table_schema, table_name;

-- Check playbooks registered
SELECT playbook_name, category, is_active 
FROM SECUREINSIGHTS_CLEANROOM.PLAYBOOKS.PLAYBOOK_REGISTRY;

-- Test combined view
SELECT COUNT(*) as segment_count, 
       AVG(combined_risk_score) as avg_risk
FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.COMBINED_RISK_INSIGHTS;

-- Check tasks status
SHOW TASKS IN SCHEMA SECUREINSIGHTS_CLEANROOM.ANALYTICS;

PRINT '✅ SecureInsights Hub setup complete!';
