# SecureInsights Hub

Privacy-Preserving AI Collaboration for Financial & Social Inclusion

## Overview

SecureInsights Hub is a Snowflake-powered Clean Room application that enables multiple organizations (banks, insurers, public agencies) to collaborate on AI-driven analytics while never sharing raw customer data.

Built for the Snowflake "AI for Good" Hackathon.

## Quick Start

### 1. Setup Databases
```sql
-- Run in order:
@sql/01_setup_databases.sql
@sql/02_create_private_tables.sql
@sql/03_sample_data.sql
```

### 2. Configure Clean Room
```sql
@sql/04_clean_room_setup.sql
@sql/05_ethical_playbooks.sql
@sql/06_audit_logging.sql
```

### 3. Enable Automation
```sql
@sql/07_streams_tasks.sql
@sql/08_cortex_ai_explanations.sql
@sql/09_horizon_governance.sql
```

### 4. Deploy Dashboard
Upload `streamlit/app.py` to Streamlit in Snowflake.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Streamlit Dashboard                       │
│         (Visualizations, Playbooks, AI Insights)            │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                  AI Explanation Layer                        │
│              (Cortex / AI SQL - Plain Language)             │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                 Clean Room Analytics                         │
│     (Pre-approved Playbooks, Aggregation-Only Queries)      │
└─────────────────────────────────────────────────────────────┘
                              │
┌───────────────┬─────────────────┬───────────────────────────┐
│  Bank Data    │  Insurance Data │    Agency Data            │
│  (Private)    │    (Private)    │     (Private)             │
└───────────────┴─────────────────┴───────────────────────────┘
```

## Key Features

- **Privacy-Preserving**: No raw data ever leaves organizations
- **Ethical Playbooks**: Pre-approved, audited analytics queries
- **AI Explanations**: Plain-language insights via Cortex
- **Full Audit Trail**: Complete compliance logging
- **Automated Alerts**: Anomaly detection for emerging risks

## Snowflake Features Used

- Data Clean Rooms
- Secure Data Sharing
- Horizon (Governance & Tags)
- Streams & Tasks
- Cortex / AI SQL
- Streamlit in Snowflake
