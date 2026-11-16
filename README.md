# KSolutions — The True Margin Challenge

**Data Analyst Assessment | Q3 Client Profitability, Downgrade Risk & Executive Decision Support**

This repository contains the analytical work for the KSolutions Data Analyst Assessment. The objective is to move beyond the reported company-wide profit margin and examine client-level profitability after accounting for the cost and contract factors identified in the assessment.

> **Assessment status:** Repository initialized. Analysis outputs and final submission files should be added as each phase is completed and validated. No client-level results are reported in this README until they are calculated from the supplied data.

## 1. Business context

KSolutions provides enterprise cloud hosting, custom software development and tier-1 IT support across Nigeria, the United States and Europe. Leadership believes the overall profit margin is 22%, while the CFO is concerned that some major enterprise accounts may be loss-making because of:

- Service Level Agreement (SLA) penalties;
- NGN-to-USD currency fluctuations; and
- Unbilled overtime and support effort.

The assessment asks for a client-level view of **True Q3 Profitability in USD**, a baseline model to identify clients at risk of downgrading in Q4, an interactive SLA penalty simulator, and a strategic memo addressing the response to a loss-making public-sector account.

## 2. Assessment workstreams

### Phase 1 — SQL & data engineering: the messy reality

**Objective:** Calculate Q3 profitability for each client in USD using PostgreSQL.

Expected synthetic source files:

| Source | Purpose / relevant characteristics |
|---|---|
| `cloud_compute_logs` | Hourly server costs by client; resource tags are held in an unvalidated JSON string column named `config_tags`. |
| `support_tickets` | Support-ticket records with timestamps in UTC. |
| `sla_contracts` | Client-specific contractual SLA penalty rules. |
| `daily_fx_rates` | Daily NGN-to-USD exchange rates. |

The SQL workflow will document data validation, parsing of resource tags, time handling, contractual penalty logic, currency conversion and client-level aggregation. The final script and its execution notes will be stored under `sql/`.

### Phase 2 — Python: downgrade-risk classification

**Objective:** Explore `client_churn_history.csv` and train a baseline classification model to predict `downgraded_status`, supporting identification of current accounts that may downgrade in Q4.

The notebook will document data checks, exploratory analysis, target and feature treatment, train/test methodology, baseline model selection and evaluation. Any class imbalance, leakage risk or limitations will be stated explicitly. Model artefacts and reusable code belong under `python/`.

### Phase 3 — Power BI: executive what-if dashboard

**Objective:** Build an executive-level view of Q3 revenue versus True Profit Margin, using the validated Phase 1 outputs.

The dashboard must include:

1. Q3 revenue and True Profit Margin by client;
2. a dynamic Base SLA Penalty Rate parameter from **1% to 10%**;
3. recalculated client profitability as the parameter changes; and
4. identification of clients that move from profitable to unprofitable under the selected scenario.

The Power BI file, supporting data model notes and screenshots will be stored under `power-bi/`.

### Phase 4 — Strategic advisory memo

**Objective:** Prepare a 1–2 page memo for the CTO (Ibrahim) and executive board responding to the scenario of a major public-sector client operating at a stated -4% margin due to SLA penalties and frequent support calls.

The memo will:

- explain the data drivers of the negative margin using validated Phase 1 findings;
- identify at least three strategic or data-adjacent reasons not to terminate the account immediately; and
- recommend a data-driven alternative to improve account profitability without dropping the client.

The final PDF will be stored under `memo/`.

## 3. Repository structure

```text
KSolutions-True-Margin-Analysis/
├── README.md
├── data/
│   ├── raw/                 # Supplied source files; do not overwrite originals
│   └── processed/           # Documented, reproducible derived datasets
├── sql/                     # PostgreSQL scripts and query documentation
├── python/
│   ├── notebooks/           # EDA, modelling and evaluation
│   ├── src/                 # Reusable Python scripts
│   └── models/              # Saved model artefacts, if appropriate
├── power-bi/                # .pbix file, model notes and screenshots
├── memo/                    # Final 1–2 page strategic memo (.pdf)
└── docs/                    # Data dictionary, methodology, QA and decisions
```

## 4. Analytical standards

- **Traceability:** retain the supplied raw files unchanged and document transformations.
- **Reproducibility:** provide executable SQL/Python work and explain dependencies and run order.
- **Data integrity:** validate joins, date/time handling, currency conversion, missing values and aggregation grain.
- **No invented results:** all figures, model metrics and recommendations must be supported by the supplied data or clearly labelled as assumptions.
- **Business interpretation:** distinguish calculated findings from interpretation, assumptions and recommendations.
- **Confidentiality:** do not commit passwords, access tokens, credentials or unrelated personal information. Share only assessment data that is permitted to be included in the submission.

## 5. Submission checklist

- [ ] PostgreSQL script calculating client-level Q3 True Profitability in USD.
- [ ] Python EDA and baseline downgrade classification model.
- [ ] Evaluation results and limitations for the classification model.
- [ ] Power BI dashboard (.pbix) with the 1%–10% dynamic SLA penalty simulator.
- [ ] Evidence of clients changing profitability status under scenarios.
- [ ] 1–2 page strategic memo (.pdf).
- [ ] Final QA of file names, links, calculations and repository access.

## 6. Tools

- PostgreSQL
- Python (pandas and scikit-learn, where appropriate)
- Power BI
- Git and GitHub

## 7. Running the work

Project-specific setup instructions, package versions, SQL execution order and data requirements will be added in the relevant phase folders once the supplied assessment data and final scripts are in place.

---

**Prepared by:** Samson Bukola Oguntade  
**Project:** KSolutions Data Analyst Assessment — The True Margin Challenge  
**Submission format:** Private GitHub repository containing code/scripts, a dashboard file and a 1–2 page strategic memo.
