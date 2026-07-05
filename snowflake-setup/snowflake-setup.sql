-- ==========================================
-- 1. Compute & Infrastructure Setup
-- ==========================================
-- Create a lightweight warehouse for data loading (starts and stops automatically to save credits)
CREATE OR REPLACE WAREHOUSE DATA_GOVERNANCE_WH 
  WAREHOUSE_SIZE = 'XSMALL' 
  AUTO_SUSPEND = 60 
  AUTO_RESUME = TRUE;

-- Create our dedicated project database and schema
CREATE OR REPLACE DATABASE GOVERNANCE_DB;
CREATE OR REPLACE SCHEMA GOVERNANCE_DB.RAW_STAGE;

-- ==========================================
-- 2. Secure Storage Integration (AWS S3 Handshake)
-- ==========================================
CREATE OR REPLACE STORAGE INTEGRATION s3_governance_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:role/snowflake-s3-integration-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://ai-data-governance-landing-bucket/raw/');

DESCRIBE INTEGRATION s3_governance_integration;

USE DATABASE GOVERNANCE_DB;
USE SCHEMA RAW_STAGE;

-- Create an external stage pointing exactly to your raw data directory in S3
CREATE OR REPLACE STAGE employee_raw_stage
  URL = 's3://ai-data-governance-landing-bucket/raw/'
  STORAGE_INTEGRATION = s3_governance_integration;

-- Verify file arrival in landing zone
LIST @employee_raw_stage;

-- ==========================================
-- 3. Raw Data Ingestion Layer
-- ==========================================
-- Create a raw table with flexible VARCHAR types to hold the messy data safely
CREATE OR REPLACE TABLE GOVERNANCE_DB.RAW_STAGE.STG_EMPLOYEES (
    Employee_ID VARCHAR,
    First_Name VARCHAR,
    Last_Name VARCHAR,
    Age VARCHAR,
    Department_Region VARCHAR,
    Status VARCHAR,
    Join_Date VARCHAR,
    Salary VARCHAR,
    Email VARCHAR,
    Phone VARCHAR,
    Performance_Score VARCHAR,
    Remote_Work VARCHAR
);

-- Ingest the file from your S3 stage into the raw table
COPY INTO GOVERNANCE_DB.RAW_STAGE.STG_EMPLOYEES
FROM @employee_raw_stage
FILES = ('Messy_Employee_dataset.csv')
FILE_FORMAT = (
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('', 'NULL', 'NaN')
);

-- ==========================================
-- 4. Governance & Verification Queries
-- ==========================================
-- Check for anomalous data identified by AI (e.g., missing metrics)
SELECT * FROM GOVERNANCE_DB.RAW_STAGE.STG_EMPLOYEES 
WHERE Age IS NULL;

-- Verify dbt's down-funnel transformation and SHA-256 data masking rules
SELECT 
    Employee_ID, 
    hashed_first_name, 
    hashed_email, 
    masked_phone, 
    employee_age 
FROM GOVERNANCE_DB.DBT_ANALYTICS_SCHEMA.STG_EMPLOYEES 
LIMIT 5;