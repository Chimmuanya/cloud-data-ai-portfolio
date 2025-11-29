# tests/test_handler_event.py

import pytest # The powerful testing framework for Python.
# Import the function we are testing from the application handler file.
from src.handler import s3_event_to_bucket_key

def test_s3_event_to_bucket_key_valid():
    """
    Tests the standard 'happy path': checking that a correctly formatted S3 event
    is parsed successfully, extracting the correct bucket name and file key.
    """
    # Create a mock (fake) S3 event payload, mimicking the structure AWS sends.
    event = {"Records": [{"s3": {"bucket": {"name": "my-b"}, "object": {"key": "file.csv"}}}]}
    
    # Execute the function we are testing.
    bucket, key = s3_event_to_bucket_key(event)
    
    # Assertion 1: Check that the extracted bucket name is correct.
    assert bucket == "my-b"
    
    # Assertion 2: Check that the extracted file key (filename) is correct.
    assert key == "file.csv"

def test_s3_event_to_bucket_key_invalid():
    """
    Tests the 'failure path': checking that a missing or incorrectly formatted 
    event (missing the 'Records' structure) correctly raises a ValueError.
    """
    # Use pytest's context manager to assert that a specific exception is raised.
    # The code inside the 'with' block must cause a ValueError, or the test fails.
    with pytest.raises(ValueError):
        # Pass an empty dictionary, which violates the expected S3 event structure.
        s3_event_to_bucket_key({})