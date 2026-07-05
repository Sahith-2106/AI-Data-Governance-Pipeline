import json
import boto3

s3_client = boto3.client('s3')
bedrock_client = boto3.client('bedrock-runtime', region_name='eu-central-1')

def lambda_handler(event, context):
    bucket_name = 'ai-data-governance-landing-bucket'
    file_key = 'raw/Messy_Employee_dataset.csv'
    
    try:
        # 1. Fetch data sample
        response = s3_client.get_object(Bucket=bucket_name, Key=file_key, Range='bytes=0-2000')
        raw_sample = response['Body'].read().decode('utf-8')
        
        # 2. Invoke AWS Nova Micro
        system_prompt = (
            "You are an expert Data Engineer and Data Governance agent. Analyze the provided CSV data sample. "
            "Respond ONLY with a valid JSON object matching this structure, with no markdown formatting or extra text:\n"
            "{\n"
            "  \"columns\": [\n"
            "    {\"name\": \"column_name\", \"type\": \"suggested_sql_type\", \"contains_pii\": true/false, \"anomaly_detected\": \"description or none\"}\n"
            "  ]\n"
            "}"
        )
        
        messages = [{"role": "user", "content": [{"text": f"Here is the sample data:\n\n{raw_sample}"}]}]
        
        ai_response = bedrock_client.converse(
            modelId="eu.amazon.nova-micro-v1:0",
            messages=messages,
            system=[{"text": system_prompt}],
            inferenceConfig={"temperature": 0.0}
        )
        
        result_text = ai_response['output']['message']['content'][0]['text']
        metadata = json.loads(result_text)
        
        # 3. Dynamically build the dbt models.yml configuration string
        dbt_yaml = "version: 2\n\nmodels:\n  - name: stg_employees\n    description: \"Automated AI-profiled staging table for messy employee data.\"\n    columns:\n"
        
        for col in metadata['columns']:
            name = col['name']
            is_pii = col['contains_pii']
            
            dbt_yaml += f"      - name: {name}\n"
            dbt_yaml += f"        description: \"AI Detected Type: {col['type']}.\"\n"
            
            # Programmatically inject dbt tests based on metadata rules
            dbt_yaml += "        tests:\n"
            if name.lower() == 'employee_id':
                dbt_yaml += "          - unique\n          - not_null\n"
            else:
                # Add basic safety checks for other columns
                dbt_yaml += "          - not_null\n" if not is_pii else "          - not_null # Contains PII\n"
        
        # 4. Save the generated dbt config back to S3
        output_key = 'dbt_configs/models.yml'
        s3_client.put_object(
            Bucket=bucket_name,
            Key=output_key,
            Body=dbt_yaml,
            ContentType='text/yaml'
        )
        
        return {
            'statusCode': 200,
            'body': f"Success! dbt configuration built and uploaded to s3://{bucket_name}/{output_key}"
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f"Pipeline failed: {str(e)}"
        }