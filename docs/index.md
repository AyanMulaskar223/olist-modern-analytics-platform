# 🚀 Olist Modern Analytics Platform

![ADLC](https://img.shields.io/badge/Framework-ADLC%205%20Phases-2563EB?style=for-the-badge)
![Stack](https://img.shields.io/badge/Stack-Modern%20Data%20Stack-16A34A?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-559%20Automated-F59E0B?style=for-the-badge)
![Quality](https://img.shields.io/badge/Quality-100%25-10B981?style=for-the-badge)

<div class="hero-shell">
	<p class="hero-kicker">Portfolio Scenario • Modern Data Stack</p>
	<h1 class="hero-title">Production-Style Analytics Engineering</h1>
	<p class="hero-subtitle">Azure Blob → Snowflake → dbt → Power BI → GitHub Actions</p>
	<p class="hero-description">A portfolio platform focused on trust, governance, and measurable delivery quality across ingestion, transformation, semantic modeling, and DataOps.</p>
	<div class="hero-cta-row">
		<a class="hero-cta" href="01_architecture/">View Architecture</a>
		<a class="hero-cta hero-cta--secondary" href="03_data_quality/">View Quality Framework</a>
	</div>
</div>

## 🏗️ Architecture Preview

![Modern Data Stack Architecture](architecture/architecture_hero.png){.architecture-preview-image}

[Open full architecture view →](01_architecture.md)

---

## 📊 Platform Metrics

<div class="kpi-grid">
	<div class="kpi-card">
		<div class="kpi-label">Automated Tests</div>
		<div class="kpi-value">559</div>
		<div class="kpi-desc">dbt + Source Tests</div>
	</div>
	<div class="kpi-card">
		<div class="kpi-label">dbt Models</div>
		<div class="kpi-value">24</div>
		<div class="kpi-desc">Staging + Marts</div>
	</div>
	<div class="kpi-card">
		<div class="kpi-label">Data Volume</div>
		<div class="kpi-value">1.55M</div>
		<div class="kpi-desc">Rows Processed</div>
	</div>
	<div class="kpi-card">
		<div class="kpi-label">Dashboard Load</div>
		<div class="kpi-value">&lt; 2s</div>
		<div class="kpi-desc">Performance SLA</div>
	</div>
</div>

---

## 🎯 What This Project Demonstrates

!!! success "Enterprise-Grade Analytics Engineering"
**End-to-end modern data stack** implementation with production-quality standards:

    ✅ **Architecture:** Clear layer boundaries (RAW → STAGING → INTERMEDIATE → MARTS)
    ✅ **Quality:** 559 automated tests with 100% data quality score
    ✅ **DataOps:** CI/CD pipelines with automated testing and deployment
    ✅ **Performance:** Sub-2-second dashboard loads with cost optimization
    ✅ **Governance:** Row-level security (RLS), data contracts, semantic layer
    ✅ **Documentation:** Comprehensive docs with screenshots and evidence

---

## 🏗️ Technology Stack

<div class="tech-stack-grid">
    <div class="tech-card">
        <div class="tech-icon">☁️</div>
        <div class="tech-title">Azure Blob Storage</div>
        <div class="tech-desc">Centralized data lake for raw CSV/JSON/Parquet files</div>
    </div>
    <div class="tech-card">
        <div class="tech-icon">❄️</div>
        <div class="tech-title">Snowflake</div>
        <div class="tech-desc">Cloud data warehouse with auto-suspend & resource monitors</div>
    </div>
    <div class="tech-card">
        <div class="tech-icon">🔧</div>
        <div class="tech-title">dbt Core</div>
        <div class="tech-desc">Data transformation with star schema modeling & testing</div>
    </div>
    <div class="tech-card">
        <div class="tech-icon">📊</div>
        <div class="tech-title">Power BI</div>
        <div class="tech-desc">Semantic model with RLS, incremental refresh & BPA validation</div>
    </div>
    <div class="tech-card">
        <div class="tech-icon">🤖</div>
        <div class="tech-title">GitHub Actions</div>
        <div class="tech-desc">CI/CD pipelines for dbt tests & SQLFluff linting</div>
    </div>
    <div class="tech-card">
        <div class="tech-icon">🧠</div>
        <div class="tech-title">AI-Assisted Dev</div>
        <div class="tech-desc">GitHub Copilot + ChatGPT with human validation</div>
    </div>
</div>

---

## 📚 Documentation Navigator

### 📋 Core Design Documents

<div class="doc-grid">
    <div class="doc-card">
        <div class="doc-icon">🎯</div>
        <div class="doc-title"><a href="00_business_requirements/">Business Requirements</a></div>
        <div class="doc-desc">KPI definitions, business questions, success criteria</div>
    </div>
    <div class="doc-card">
        <div class="doc-icon">🏛️</div>
        <div class="doc-title"><a href="01_architecture/">Architecture</a></div>
        <div class="doc-desc">System design, data flow, layer responsibilities</div>
    </div>
    <div class="doc-card">
        <div class="doc-icon">📖</div>
        <div class="doc-title"><a href="02_data_dictionary/">Data Dictionary</a></div>
        <div class="doc-desc">Schema definitions, business rules, grain documentation</div>
    </div>
</div>

### ✅ Implementation Quality

<div class="doc-grid">
    <div class="doc-card">
        <div class="doc-icon">🧪</div>
        <div class="doc-title"><a href="03_data_quality/">Data Quality Framework</a></div>
        <div class="doc-desc">559 automated tests, validation strategy, quality gates</div>
    </div>
    <div class="doc-card">
        <div class="doc-icon">⚡</div>
        <div class="doc-title"><a href="05_performance_optimization/">Performance Optimization</a></div>
        <div class="doc-desc">Cost controls, incremental refresh, query optimization</div>
    </div>
    <div class="doc-card">
        <div class="doc-icon">🛠️</div>
        <div class="doc-title"><a href="06_engineering_standards/">Engineering Standards</a></div>
        <div class="doc-desc">ADLC framework, DataOps, AI-assisted development</div>
    </div>
</div>

### 📊 BI & Analytics

<div class="doc-grid">
    <div class="doc-card">
        <div class="doc-icon">🧠</div>
        <div class="doc-title"><a href="04_semantic_model/">Semantic Model</a></div>
        <div class="doc-desc">Power BI measures, RLS implementation, DAX patterns</div>
    </div>
    <div class="doc-card">
        <div class="doc-icon">📈</div>
        <div class="doc-title"><a href="07_analytics_insights/">Analytics Insights</a></div>
        <div class="doc-desc">Business findings, KPI analysis, recommendations</div>
    </div>
</div>

---

## 🗺️ ADLC 5-Phase Journey

!!! tip "Structured Development Lifecycle"
This project follows the **Analytics Development Life Cycle (ADLC)** framework for organized, phase-gated delivery:

| Phase       | Focus Area              | Key Deliverables                                         | Status      |
| :---------- | :---------------------- | :------------------------------------------------------- | :---------- |
| **Phase 1** | Requirements & Planning | Business questions, KPI definitions, architecture design | ✅ Complete |
| **Phase 2** | Data Ingestion          | Azure Blob setup, Snowflake RAW layer (1.55M rows)       | ✅ Complete |
| **Phase 3** | Transformation          | dbt models (staging → marts), star schema                | ✅ Complete |
| **Phase 4** | DataOps & CI/CD         | GitHub Actions, automated testing (559 tests)            | ✅ Complete |
| **Phase 5** | BI & Semantic Layer     | Power BI semantic model, dashboards, RLS                 | ✅ Complete |

---

## 🏆 Key Capabilities

!!! abstract "What Sets This Project Apart"

    **🔒 Governance-First Design**

    - Row-level security (RLS) with dynamic bridge pattern
    - Data contracts enforce schema validation
    - Certified semantic layer prevents metric chaos

    **🧪 Quality-Driven Development**

    - 559 automated tests (85 source + 474 model tests)
    - 100% data quality score validated
    - CI gates prevent bad data from reaching production

    **💰 Cost-Optimized Architecture**

    - Snowflake auto-suspend (60s/300s) saves compute costs
    - Power BI incremental refresh reduces load times
    - Query tagging enables cost attribution

    **🤖 AI-Accelerated Development**

    - GitHub Copilot integration with custom instructions
    - ChatGPT project with full context management
    - Human validation for all AI-generated code

---

## 🔗 External Links

- **GitHub Repository:** [AyanMulaskar223/olist-modern-analytics-platform](https://github.com/AyanMulaskar223/olist-modern-analytics-platform)
- **LinkedIn:** [Connect with Ayan Mulaskar](https://www.linkedin.com/in/ayan-mulaskar/)

---

<p style="text-align: center; color: #666; margin-top: 3rem;">
Built with ❤️ using the Modern Data Stack • February 2026
</p>
