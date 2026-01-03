# Project Structure

```
/
├── .kiro/
│   └── steering/       # AI assistant guidance documents
├── hackathon/          # Hackathon planning and documentation
│   ├── hackathon-hackathon.txt  # Hackathon rules and problem statements
│   ├── our-plan.txt    # SecureInsights Hub project plan
│   └── plans.txt       # Additional planning notes
```

## Architecture Layers

1. **Data Layer** - Private Snowflake tables per organization (never exposed)
2. **Clean Room Layer** - Pre-approved ethical analytics queries, aggregation-only
3. **AI Explanation Layer** - Cortex/AI SQL for plain-language insights
4. **Presentation Layer** - Streamlit dashboard with visualizations and audit logs

## Expected Future Structure

As implementation progresses, expect:
- `/sql/` - SQL scripts for tables, views, and queries
- `/streamlit/` - Dashboard application code
- `/docs/` - Additional documentation
