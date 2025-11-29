# src/validator.py
import pandas as pd
# Used to parse date strings into datetime objects, enabling date validation.
from dateutil.parser import parse as parse_date
# Used for type hinting to improve code readability and maintainability.
from typing import Dict, Any, List

# Define the default schema for data validation. This dictionary specifies
# the expected columns, their properties (required, type), and constraints.
DEFAULT_SCHEMA = {
    # Required integer column for unique identification.
    "id": {"required": True, "type": "int"},
    # Required string column for names.
    "name": {"required": True, "type": "str"},
    # Required integer column for age, with range constraints.
    "age": {"required": True, "type": "int", "min": 0, "max": 120},
    # Optional string column for email.
    "email": {"required": False, "type": "str"},
    # Optional date column for sign-up date.
    "signup_date": {"required": False, "type": "date"},
}

def validate_row(row: pd.Series, schema: Dict[str, Any] = None) -> List[Dict[str, Any]]:
    """
    Validates a single Pandas Series (row) against a defined schema.

    Args:
        row (pd.Series): The data row to validate.
        schema (Dict[str, Any], optional): The validation rules dictionary.
                                            Defaults to DEFAULT_SCHEMA.

    Returns:
        List[Dict[str, Any]]: A list of dictionaries detailing all validation
                              issues found in the row.
    """
    # Use the provided schema or fall back to the default schema.
    schema = schema or DEFAULT_SCHEMA
    issues = []

    # Iterate through each column defined in the schema and its rules.
    for col, rules in schema.items():
        # Safely retrieve the column value from the row.
        val = row.get(col, None)

        # 1. Check for Missing Required Values
        # Check if the value is None or if it's a float NaN (the standard way pandas handles missing numerical data).
        if (val is None or (isinstance(val, float) and pd.isna(val))) and rules.get("required", False):
            issues.append({"column": col, "issue": "missing", "value": val})
            # Continue to the next column, as type/range checks are meaningless for missing data.
            continue

        # If the value is optional and missing (None/NaN), skip all further checks for this column.
        if val is None or (isinstance(val, float) and pd.isna(val)):
            continue

        # Get the expected data type from the schema rules.
        expected = rules.get("type")

        # 2. Type and Constraint Checks (Integer)
        if expected == "int":
            try:
                # Attempt conversion to integer.
                int_val = int(val)
            except Exception:
                # If conversion fails (e.g., "twenty"), record type mismatch.
                issues.append({"column": col, "issue": "type_mismatch", "expected": "int", "value": val})
                continue # Skip range checks if type conversion failed.

            # Check min constraint.
            if "min" in rules and int_val < rules["min"]:
                issues.append({"column": col, "issue": "out_of_range", "value": int_val})
            # Check max constraint.
            if "max" in rules and int_val > rules["max"]:
                issues.append({"column": col, "issue": "out_of_range", "value": int_val})

        # 3. Type and Constraint Checks (Date)
        elif expected == "date":
            try:
                # Use dateutil.parser to check if the string can be parsed as a date.
                _ = parse_date(str(val))
            except Exception:
                # If parsing fails, the date format is invalid.
                issues.append({"column": col, "issue": "invalid_date", "value": val})

        # 4. Type and Constraint Checks (String)
        elif expected == "str":
            # This check is primarily defensive, ensuring non-string numeric values
            # aren't flagged as issues unless they cannot be converted to a string.
            if isinstance(val, (int, float)) and not isinstance(val, str):
                try:
                    # Attempt conversion to string.
                    _ = str(val)
                except Exception:
                    # This is unlikely but handles cases where str() conversion fails.
                    issues.append({"column": col, "issue": "type_mismatch", "expected": "str", "value": val})

    return issues

def validate_dataframe(df: pd.DataFrame, schema: Dict[str, Any] = None) -> Dict[str, Any]:
    """
    Validates every row in a DataFrame against the schema and generates a summary report.

    Args:
        df (pd.DataFrame): The DataFrame to validate.
        schema (Dict[str, Any], optional): The validation rules dictionary.
                                            Defaults to DEFAULT_SCHEMA.

    Returns:
        Dict[str, Any]: A comprehensive report containing overall stats,
                        row-level issues, and column summaries.
    """
    # Use the provided schema or fall back to the default schema.
    schema = schema or DEFAULT_SCHEMA

    # Initialize the report structure with basic DataFrame metadata.
    report = {
        "num_rows": len(df),
        "num_columns": df.shape[1],
        "columns_present": list(df.columns),
        "row_issues": {}, # Stores issues keyed by row index (int)
        "summary": {} # Will store overall column statistics
    }

    total_issues = 0
    # Iterate over each row of the DataFrame using iterrows().
    for idx, row in df.iterrows():
        # Validate the current row using the helper function.
        row_issues = validate_row(row, schema)

        if row_issues:
            # If issues are found, store them in the report using the integer index.
            report["row_issues"][int(idx)] = row_issues
            total_issues += len(row_issues)

    # 1. Check for missing required columns in the DataFrame itself (schema level check).
    missing_columns = [
        c for c, r in schema.items()
        if r.get("required", False) and c not in df.columns
    ]

    # Add final summary statistics to the report.
    report["missing_required_columns"] = missing_columns
    report["total_issues"] = total_issues

    # 2. Add Column Statistics (Profile)
    col_stats = {}
    for c in df.columns:
        col_stats[c] = {
            # Count of non-null values.
            "non_null_count": int(df[c].notna().sum()),
            # Count of unique, non-missing values.
            "unique": int(df[c].nunique(dropna=True)),
            # Pandas data type (e.g., 'object', 'int64').
            "dtype": str(df[c].dtype),
        }
    report["summary"]["columns"] = col_stats

    return report
