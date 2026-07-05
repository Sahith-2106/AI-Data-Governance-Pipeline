# Autonomous AI Data Governance & Secure Analytics Pipeline

An event-driven data pipeline that leverages Generative AI to automatically profile incoming datasets, generate dbt quality tests, isolate sensitive data (PII), and enforce masking rules inside Snowflake.

---

## 🎯 Why This Project Exists

In traditional data engineering, when a new or modified dataset lands, pipelines break unless an engineer manually updates schema definitions and data-quality tests. Furthermore, identifying sensitive personal data (PII) to meet GDPR compliance is often manual and error-prone. 

This project solves this problem by giving the data pipeline **contextual vision**. By using a lightweight AI model at the landing zone, the pipeline dynamically adapts to incoming data, writes its own test definitions, and flags sensitive records before the data is processed.

---

## 🏗️ Architecture & Data Flow



The entire architecture is serverless, secure, and fully automated across five clear steps:

1. **Land:** Raw, unmanaged CSV data drops into an **Amazon S3** bucket.
2. **Profile:** An S3 Event Notification triggers an **AWS Lambda** function. The function sends a sample of the data to **Amazon Nova Micro** (via Amazon Bedrock) to automatically detect SQL column types, anomalies, and sensitive PII.
3. **Generate:** Lambda dynamically formats the AI’s metadata insights into a native dbt `models.yml` file and saves it back to S3.
4. **Ingest:** **Snowflake** securely reads the raw file from S3 using a credential-less, identity-based Storage Integration.
5. **Mask & Clean:** **dbt Cloud** connects to Snowflake, reads the AI-generated testing suite to check for quality anomalies, and runs a SQL staging model that permanently hashes and obfuscates sensitive personal data (e.g., names and emails).

---

## 🛠️ Tech Stack & Key Skills

* **Cloud Infrastructure:** AWS (S3, Lambda, Bedrock, IAM)
* **Data Warehouse:** Snowflake (Storage Integrations, External Stages)
* **Transformation & Testing:** dbt Cloud (SQL Modeling, Macro Testing)
* **Security & Compliance:** SHA-256 Data Hashing, PII Obfuscation, Event-Driven Automation
* **Languages:** Python (Boto3 SDK), SQL (Snowflake dialect), YAML

---

## 🚀 Key Features

### 1. Zero-Trust PII Masking
The dbt transformation layer isolates columns flagged by the AI and automatically applies protection rules:
* **Names & Emails:** Converted into irreversible SHA-256 hashes so analysts can perform unique joins without seeing real identity data.
* **Phone Numbers:** Partially masked (`XXXX-XXXX-1234`) to protect privacy while preserving basic formatting.

### 2. Automated Schema Adaptation
If column structures or formatting rules change, the serverless function rewrites the dbt validation suite instantly. This eliminates the need for engineers to manually write and maintain test configurations.

---

## 📂 Repository Structure

```text
├── aws_lambda/
│   └── lambda_function.py      # Python backend connecting S3, Bedrock, and Nova Micro
├── dbt_project/
│   ├── models/
│   │   ├── stg_employees.sql   # SQL transformation, data cleansing, and masking layer
│   │   └── models.yml          # AI-Generated data quality schema & validation rules
│   └── dbt_project.yml
├── raw_data/
│   └── Messy_Employee_dataset.csv  # Input messy dataset
├── snowflake_setup/
│   └── snowflake_setup.sql    # Contains series of sql statements from snowflake 
└── README.md
