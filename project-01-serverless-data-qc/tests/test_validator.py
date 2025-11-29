# tests/test_validator.py

# Import the necessary libraries. pandas is used to create mock DataFrames,
# and validate_dataframe is the function being tested (imported from your source code).
import pandas as pd
from src.validator import validate_dataframe

def test_validate_good_csv():
    """
    Tests a dataset that contains perfectly valid data according to the schema.
    The expectation is that the report finds zero issues.
    """
    # Create a small, mock DataFrame with correct types and non-empty required fields.
    df = pd.DataFrame([
        {"id": 1, "name": "Alice", "age": 30, "email": "a@x.com", "signup_date": "2020-01-01"},
        {"id": 2, "name": "Bob", "age": 22, "email": "b@x.com", "signup_date": "2021-02-02"},
    ])
    
    # Run the validation function.
    report = validate_dataframe(df)
    
    # Assertions: Verify the output matches expectations.
    # 1. The total number of issues found must be zero.
    assert report["total_issues"] == 0
    # 2. The report must correctly identify the number of rows processed.
    assert report["num_rows"] == 2

def test_missing_required_column():
    """
    Tests a scenario where a required column ("name" in the default schema)
    is completely missing from the input DataFrame.
    """
    # Create a DataFrame missing the "name" column.
    df = pd.DataFrame([{"id": 1, "age": 30}])
    
    # Run the validation function.
    report = validate_dataframe(df)
    
    # Assertion: Check that the name "name" appears in the list of missing required columns.
    assert "name" in report["missing_required_columns"]

def test_age_out_of_range():
    """
    Tests a row-level validation rule: the 'age' # tests/test_validator.py
import pandas as pd
from src.validator import validate_dataframe

def test_validate_good_csv():
    df = pd.DataFrame([
        {"id": 1, "name": "Alice", "age": 30, "email": "a@x.com", "signup_date": "2020-01-01"},
        {"id": 2, "name": "Bob", "age": 22, "email": "b@x.com", "signup_date": "2021-02-02"},
    ])
    report = validate_dataframe(df)
    assert report["total_issues"] == 0
    assert report["num_rows"] == 2

def test_missing_required_column():
    df = pd.DataFrame([{"id": 1, "age": 30}])
    report = validate_dataframe(df)
    assert "name" in report["missing_required_columns"]

def test_age_out_of_range():
    df = pd.DataFrame([{"id": 1, "name": "Sam", "age": 999}])
    report = validate_dataframe(df)
    assert report["total_issues"] > 0
value is present but violates
    the defined schema constraint (max: 120).
    """
    # Create a DataFrame with an 'age' value that is clearly out of the expected range.
    df = pd.DataFrame([{"id": 1, "name": "Sam", "age": 999}])
    
    # Run the validation function.
    report = validate_dataframe(df)
    
    # Assertion: Verify that at least one issue was found.
    # The expected issue here is "out_of_range" for the 'age' column.
    assert report["total_issues"] > 0