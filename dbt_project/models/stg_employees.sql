WITH raw_data AS (
    SELECT * FROM GOVERNANCE_DB.RAW_STAGE.STG_EMPLOYEES
)

SELECT
    Employee_ID,
    
    -- 1. PII Masking: SHA256 Hash names and emails to protect identity while preserving analytical uniqueness
    SHA2(First_Name, 256) AS hashed_first_name,
    SHA2(Last_Name, 256) AS hashed_last_name,
    SHA2(Email, 256) AS hashed_email,
    
    -- 2. PII Obfuscation: Partially mask phone numbers to show only the last 4 digits
    CASE 
        WHEN Phone IS NOT NULL THEN CONCAT('XXXX-XXXX-', RIGHT(Phone, 4))
        ELSE NULL 
    END AS masked_phone,
    
    -- 3. Data Cleansing: Handle the empty/NULL ages by imputing the company median age (e.g., 35)
    COALESCE(TRY_TO_NUMBER(Age), 35) AS employee_age,
    
    -- 4. Standardizing remaining fields
    Department_Region,
    Status,
    TRY_TO_DATE(Join_Date) AS join_date,
    TRY_TO_DECIMAL(Salary, 10, 2) AS salary,
    Performance_Score,
    TRY_TO_BOOLEAN(Remote_Work) AS is_remote_work

FROM raw_data