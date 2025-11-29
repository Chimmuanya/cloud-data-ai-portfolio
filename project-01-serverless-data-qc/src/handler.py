# src/handler.py

import os
import tempfile
import csv
import io
import json
import pandas as pd
from typing import Dict, Any
# Import core application logic
from .validator import validate_dataframe
# Import S3 utility functions for reading and writing files
from .utils import read_s3_object, write_s3_json

def s3_event_to_bucket_key(event: Dict[str, Any]):
    """
    Parses the complex AWS S3 event structure to extract the specific 
    bucket name and file key (path/filename) that triggered the Lambda.
    
    Args:
        event (Dict[str, Any]): The raw JSON object passed by AWS S3.
        
    Returns:
        tuple[str, str]: A tuple containing (bucket_name, file_key).
    """
    # S3 put event structure assumed: AWS wraps the useful data in a 'Records' list.
    records = event.get("Records", [])
    if not records:
        # If the expected structure is missing, something is wrong with the trigger setup.
        raise ValueError("No Records found in event")
        
    # We only care about the first record, which contains the S3 information.
    rec = records[0].get("s3", {})
    
    # Safely extract the bucket name from the nested dictionary structure.
    bucket = rec.get("bucket", {}).get("name")
    
    # Safely extract the file key (path/filename) from the nested structure.
    key = rec.get("object", {}).get("key")
    
    return bucket, key

def handler(event, context):
    """
    The main entry point for the AWS Lambda function. 
    It orchestrates the reading, validation, and reporting process.

    Args:
        event (Dict[str, Any]): The input payload from the S3 trigger.
        context (Any): Standard AWS Lambda context object (not used here).

    Returns:
        Dict[str, Any]: A response object suitable for AWS Lambda success.
    """
    
    # 1. Parse Event: Get the location of the file that triggered the function.
    bucket, key = s3_event_to_bucket_key(event)
    
    # 2. Read Input Data: Download the file content as raw bytes using the utility function.
    # The 'raw' variable now holds the CSV file data.
    raw = read_s3_object(bucket, key)
    
    # 3. Data Processing: Convert the raw bytes into a Pandas DataFrame.
    # Assumes the input is text/csv. io.BytesIO wraps the bytes so pandas can read it 
    # directly from memory without needing to save it to a temporary disk file.
    df = pd.read_csv(io.BytesIO(raw))
    
    # 4. Core Logic: Run the data validation logic.
    # This is where the schema checks (from src/validator.py) are performed.
    report = validate_dataframe(df)
    
    # 5. Define Output Path: Create the filename for the QC report.
    # Example: If input key was 'data/raw.csv', the report key becomes 'reports/data/raw.csv.qc.json'.
    report_key = f"reports/{key}.qc.json"
    
    # 6. Write Output Report: Upload the resulting validation report back to S3.
    # The utility function (from src/utils.py) handles converting the report dict to JSON.
    write_s3_json(bucket, report_key, report)
    
    # 7. Return Response: Standard Lambda success response.
    return {
        "statusCode": 200,
        "body": json.dumps({"report_key": report_key}) # Include the report path in the body
    }