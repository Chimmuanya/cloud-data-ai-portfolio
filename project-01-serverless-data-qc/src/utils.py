# src/utils.py

import json # Required for converting Python dictionaries to JSON strings (and vice-versa).
import boto3 # The AWS SDK for Python, used to interact with AWS services like S3.
from botocore.exceptions import ClientError # Used for catching specific AWS-related errors.
from typing import Dict, Any # Used for type hinting, making the code easier to read and debug.

# Initialize the S3 client globally. This client handles communication with the S3 service.
# Creating it outside the functions saves time on every function call in a Lambda environment.
s3 = boto3.client("s3")

def read_s3_object(bucket: str, key: str) -> bytes:
    """
    Reads the full content of an object (file) from S3.

    Args:
        bucket (str): The name of the S3 bucket where the file is located.
        key (str): The key (path/filename) of the object in the bucket.

    Returns:
        bytes: The raw content of the file as bytes.
    """
    try:
        # Calls the S3 GetObject API. This is the primary action for downloading data.
        resp = s3.get_object(Bucket=bucket, Key=key)
        
        # Reads the entire content from the response body and returns it as raw bytes.
        return resp["Body"].read()
    except ClientError as e:
        # It's good practice to log or handle exceptions, especially permissions errors (403).
        print(f"Error reading S3 object {key} from {bucket}: {e}")
        raise # Re-raise the exception to be handled by the calling function.

def write_s3_json(bucket: str, key: str, payload: Dict[str, Any], acl=None) -> None:
    """
    Writes a Python dictionary (payload) to S3, automatically converting it to a 
    UTF-8 encoded JSON string suitable for storage and retrieval.

    Args:
        bucket (str): The destination S3 bucket name.
        key (str): The key (path/filename) for the new object (e.g., 'reports/qc_report.json').
        payload (Dict[str, Any]): The Python dictionary to be saved (e.g., the validation report).
        acl (str, optional): Access control list setting, typically left as None.
    """
    # Calls the S3 PutObject API, the primary action for uploading data.
    s3.put_object(
        Bucket=bucket,
        Key=key,
        # Convert the Python dictionary (payload) into a JSON string, ensuring non-standard
        # types (like datetime objects) are converted to strings first (default=str).
        # Then, encode the JSON string into bytes using UTF-8 encoding for S3 storage.
        Body=json.dumps(payload, default=str).encode("utf-8"),
        ContentType="application/json" # Sets the metadata so S3 knows the file is JSON.
        # Note: ACL argument is accepted but is unused in the function body above,
        # which adheres to best practices of using bucket policies instead of ACLs.
    )