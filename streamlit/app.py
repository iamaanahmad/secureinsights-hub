"""
SecureInsights Hub - Streamlit Dashboard
Privacy-Preserving AI Collaboration Platform
"""

import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
from datetime import datetime

# Page config
st.set_page_config(
    page_title="SecureInsights Hub",
    page_icon="🔐",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Get Snowflake session
session = get_active_session()

# Header
st.title("🔐 SecureInsights Hub")
st.caption("Privacy-Preserving AI Collaboration for Financial & Social Inclusion")

# Sidebar
st.sidebar.title("Navigation")
page = st.sidebar.radio(
    "Select View",
    ["📊 Dashboard", "📋 Analytics Playbooks", "🤖 AI Insights", "📜 Audit Log", "⚠️ Alerts"]
)

st.sidebar.markdown("---")
st.sidebar.info(
    "SecureInsights Hub enables privacy-safe collaboration "
    "across organizations using Snowflake Data Clean Rooms."
)


# ============================================
# Dashboard Page
# ============================================
if page == "📊 Dashboard":
    st.header("Cross-Organization Risk Overview")
    
    # Fetch combined insights
    @st.cache_data(ttl=300)
    def get_combined_insights():
        return session.sql("""
            SELECT * FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.COMBINED_RISK_INSIGHTS
            ORDER BY combined_risk_score DESC
        """).to_pandas()
    
    try:
        df = get_combined_insights()
        
        # Key metrics row
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric(
                "Total Segments",
                len(df),
                help="Demographic segments analyzed"
            )
        
        with col2:
            high_risk = len(df[df['COMBINED_RISK_SCORE'] > 50]) if len(df) > 0 else 0
            st.metric(
                "High Risk Segments",
                high_risk,
                delta=f"{high_risk/len(df)*100:.1f}%" if len(df) > 0 else "0%",
                delta_color="inverse"
            )
        
        with col3:
            avg_risk = df['COMBINED_RISK_SCORE'].mean() if len(df) > 0 else 0
            st.metric(
                "Avg Risk Score",
                f"{avg_risk:.1f}"
            )
        
        with col4:
            total_ben = df['AGENCY_BENEFICIARIES'].sum() if 'AGENCY_BENEFICIARIES' in df.columns and len(df) > 0 else 0
            st.metric(
                "Total Beneficiaries",
                f"{total_ben:,.0f}"
            )
        
        st.markdown("---")
        
        # Charts
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Risk Score by Age Group")
            if len(df) > 0:
                age_risk = df.groupby('AGE_GROUP')['COMBINED_RISK_SCORE'].mean().reset_index()
                st.bar_chart(age_risk.set_index('AGE_GROUP'))
        
        with col2:
            st.subheader("Risk Score by Region")
            if len(df) > 0:
                region_risk = df.groupby('REGION')['COMBINED_RISK_SCORE'].mean().reset_index()
                st.bar_chart(region_risk.set_index('REGION'))
        
        # Data table
        st.subheader("Detailed Segment Data")
        st.dataframe(df, use_container_width=True, height=400)
        
    except Exception as e:
        st.error(f"Error loading data: {str(e)}")
        st.info("Make sure you've run all SQL setup scripts first.")


# ============================================
# Analytics Playbooks Page
# ============================================
elif page == "📋 Analytics Playbooks":
    st.header("Ethical Analytics Playbooks")
    st.markdown("Pre-approved, governed queries for privacy-safe insights")
    
    @st.cache_data(ttl=600)
    def get_playbooks():
        return session.sql("""
            SELECT playbook_id, playbook_name, description, category, query_template, is_active
            FROM SECUREINSIGHTS_CLEANROOM.PLAYBOOKS.PLAYBOOK_REGISTRY
            WHERE is_active = TRUE
            ORDER BY category, playbook_name
        """).to_pandas()
    
    try:
        playbooks = get_playbooks()
        
        # Category filter
        categories = ['All'] + list(playbooks['CATEGORY'].unique())
        selected_category = st.selectbox("Filter by Category", categories)
        
        if selected_category != 'All':
            playbooks = playbooks[playbooks['CATEGORY'] == selected_category]
        
        # Display playbooks
        for _, pb in playbooks.iterrows():
            with st.expander(f"📊 {pb['PLAYBOOK_NAME']} ({pb['CATEGORY']})"):
                st.markdown(f"**Description:** {pb['DESCRIPTION']}")
                
                purpose = st.text_input(
                    "Purpose (required for audit)",
                    key=f"purpose_{pb['PLAYBOOK_ID']}",
                    placeholder="Enter business reason"
                )
                
                if st.button("▶️ Run Query", key=f"run_{pb['PLAYBOOK_ID']}"):
                    if not purpose:
                        st.warning("Please provide a purpose for audit compliance")
                    else:
                        with st.spinner("Executing..."):
                            try:
                                # Log execution directly
                                session.sql(f"""
                                    INSERT INTO SECUREINSIGHTS_CLEANROOM.AUDIT.QUERY_AUDIT_LOG 
                                        (playbook_name, executed_by, organization, purpose, status)
                                    VALUES 
                                        ('{pb['PLAYBOOK_NAME']}', CURRENT_USER(), 'Dashboard', '{purpose}', 'SUCCESS')
                                """).collect()
                                
                                # Execute query
                                result = session.sql(pb['QUERY_TEMPLATE']).to_pandas()
                                st.success(f"✅ Returned {len(result)} rows")
                                st.dataframe(result, use_container_width=True)
                                
                                # Download
                                csv = result.to_csv(index=False)
                                st.download_button(
                                    "📥 Download CSV",
                                    csv,
                                    f"{pb['PLAYBOOK_NAME'].replace(' ', '_')}.csv",
                                    "text/csv"
                                )
                            except Exception as e:
                                st.error(f"Error: {str(e)}")
                                
    except Exception as e:
        st.error(f"Error loading playbooks: {str(e)}")


# ============================================
# AI Insights Page
# ============================================
elif page == "🤖 AI Insights":
    st.header("AI-Generated Insights")
    st.markdown("Plain-language explanations powered by Snowflake Cortex")
    
    @st.cache_data(ttl=300)
    def get_ai_insights():
        return session.sql("""
            SELECT * FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.CURRENT_AI_INSIGHTS
            ORDER BY risk_score DESC
        """).to_pandas()
    
    try:
        insights = get_ai_insights()
        
        if len(insights) > 0:
            # Filter
            categories = ['All'] + list(insights['INSIGHT_CATEGORY'].unique())
            selected = st.selectbox("Filter by Priority", categories)
            
            if selected != 'All':
                insights = insights[insights['INSIGHT_CATEGORY'] == selected]
            
            # Display
            for _, ins in insights.iterrows():
                severity = ins['INSIGHT_CATEGORY']
                icon = '🔴' if severity == 'CRITICAL' else '🟠' if severity == 'HIGH_PRIORITY' else '🟡'
                
                with st.container():
                    st.markdown(f"### {icon} {ins['AGE_GROUP']} - {ins['REGION']}")
                    st.markdown(f"**Risk Score:** {ins['RISK_SCORE']}")
                    st.info(ins['INSIGHT_TEXT'])
                    st.caption(f"Generated: {ins['GENERATED_AT']}")
                    st.markdown("---")
        else:
            st.info("No AI insights available yet.")
            
    except Exception as e:
        st.warning("AI insights table not found. Generate insights first.")
        
        if st.button("🔄 Generate AI Insights"):
            with st.spinner("Generating with Cortex AI..."):
                try:
                    session.sql("CALL SECUREINSIGHTS_CLEANROOM.ANALYTICS.GENERATE_ALL_INSIGHTS()").collect()
                    st.success("Done! Refresh the page.")
                    st.rerun()
                except Exception as e:
                    st.error(f"Error: {str(e)}")
    
    # Manual generation
    st.markdown("---")
    st.subheader("Generate Custom Insight")
    
    col1, col2 = st.columns(2)
    with col1:
        age = st.selectbox("Age Group", ['18-25', '26-35', '36-45', '46-55', '56-65', '65+'])
    with col2:
        region = st.selectbox("Region", ['Urban-North', 'Urban-South', 'Rural-North', 'Rural-South', 'Suburban-East', 'Suburban-West'])
    
    if st.button("🤖 Generate"):
        with st.spinner("Generating..."):
            try:
                result = session.sql(f"""
                    SELECT SECUREINSIGHTS_CLEANROOM.ANALYTICS.GENERATE_INSIGHT_EXPLANATION(
                        '{age}', '{region}', 45.0, 15.0, 20.0, 2500.0
                    ) as insight
                """).to_pandas()
                st.success("Generated!")
                st.info(result['INSIGHT'].iloc[0])
            except Exception as e:
                st.error(f"Cortex error: {str(e)}")


# ============================================
# Audit Log Page
# ============================================
elif page == "📜 Audit Log":
    st.header("Query Audit Log")
    st.markdown("Complete compliance tracking")
    
    try:
        # Summary
        summary = session.sql("""
            SELECT 
                COUNT(*) as total,
                COUNT(DISTINCT executed_by) as users,
                COUNT(DISTINCT playbook_name) as playbooks,
                SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) as success,
                SUM(CASE WHEN status = 'FAILED' THEN 1 ELSE 0 END) as failed
            FROM SECUREINSIGHTS_CLEANROOM.AUDIT.QUERY_AUDIT_LOG
        """).to_pandas()
        
        col1, col2, col3, col4, col5 = st.columns(5)
        col1.metric("Total Queries", summary['TOTAL'].iloc[0])
        col2.metric("Unique Users", summary['USERS'].iloc[0])
        col3.metric("Playbooks Used", summary['PLAYBOOKS'].iloc[0])
        col4.metric("Successful", summary['SUCCESS'].iloc[0])
        col5.metric("Failed", summary['FAILED'].iloc[0])
        
        st.markdown("---")
        
        # Filters
        col1, col2 = st.columns(2)
        with col1:
            status_filter = st.selectbox("Status", ['All', 'SUCCESS', 'FAILED'])
        with col2:
            search = st.text_input("Search", "")
        
        # Query
        query = """
            SELECT audit_id, playbook_name, executed_by, organization, 
                   execution_timestamp, purpose, status
            FROM SECUREINSIGHTS_CLEANROOM.AUDIT.QUERY_AUDIT_LOG
            WHERE 1=1
        """
        if status_filter != 'All':
            query += f" AND status = '{status_filter}'"
        if search:
            query += f" AND (executed_by ILIKE '%{search}%' OR playbook_name ILIKE '%{search}%')"
        query += " ORDER BY execution_timestamp DESC LIMIT 200"
        
        audit_log = session.sql(query).to_pandas()
        
        st.subheader("Recent Activity")
        st.dataframe(audit_log, use_container_width=True, height=400)
        
        if len(audit_log) > 0:
            csv = audit_log.to_csv(index=False)
            st.download_button(
                "📥 Export Log",
                csv,
                f"audit_{datetime.now().strftime('%Y%m%d')}.csv",
                "text/csv"
            )
            
    except Exception as e:
        st.info("No audit data yet. Run some playbooks first.")

# ============================================
# Alerts Page
# ============================================
elif page == "⚠️ Alerts":
    st.header("Anomaly Alerts")
    st.markdown("Automated detection of emerging risks")
    
    try:
        alerts = session.sql("""
            SELECT * FROM SECUREINSIGHTS_CLEANROOM.ANALYTICS.ANOMALY_ALERTS
            WHERE is_acknowledged = FALSE
            ORDER BY 
                CASE severity WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 WHEN 'MEDIUM' THEN 3 ELSE 4 END,
                detected_at DESC
        """).to_pandas()
        
        # Summary
        col1, col2, col3 = st.columns(3)
        critical = len(alerts[alerts['SEVERITY'] == 'CRITICAL']) if len(alerts) > 0 else 0
        high = len(alerts[alerts['SEVERITY'] == 'HIGH']) if len(alerts) > 0 else 0
        medium = len(alerts[alerts['SEVERITY'] == 'MEDIUM']) if len(alerts) > 0 else 0
        
        col1.metric("🔴 Critical", critical)
        col2.metric("🟠 High", high)
        col3.metric("🟡 Medium", medium)
        
        st.markdown("---")
        
        if len(alerts) > 0:
            for _, alert in alerts.iterrows():
                icon = {'CRITICAL': '🔴', 'HIGH': '🟠', 'MEDIUM': '🟡'}.get(alert['SEVERITY'], '⚪')
                
                with st.expander(f"{icon} {alert['ALERT_TYPE']} - {alert['AGE_GROUP']} / {alert['REGION']}"):
                    st.markdown(f"**{alert['DESCRIPTION']}**")
                    st.markdown(f"Metric: {alert['METRIC_NAME']} = {alert['CURRENT_VALUE']}")
                    st.caption(f"Detected: {alert['DETECTED_AT']}")
                    
                    if st.button("✅ Acknowledge", key=f"ack_{alert['ALERT_ID']}"):
                        session.sql(f"""
                            UPDATE SECUREINSIGHTS_CLEANROOM.ANALYTICS.ANOMALY_ALERTS
                            SET is_acknowledged = TRUE, acknowledged_at = CURRENT_TIMESTAMP()
                            WHERE alert_id = '{alert['ALERT_ID']}'
                        """).collect()
                        st.success("Acknowledged!")
                        st.rerun()
        else:
            st.success("🎉 No unacknowledged alerts!")
        
        st.markdown("---")
        if st.button("🔄 Run Detection Now"):
            with st.spinner("Detecting..."):
                session.sql("CALL SECUREINSIGHTS_CLEANROOM.ANALYTICS.DETECT_ANOMALIES()").collect()
                st.success("Done!")
                st.rerun()
                
    except Exception as e:
        st.info("Alerts system not initialized. Run setup scripts first.")

# Footer
st.markdown("---")
st.caption("SecureInsights Hub | Built with Snowflake Data Clean Rooms")
