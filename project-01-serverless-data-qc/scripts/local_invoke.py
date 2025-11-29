#!/usr/bin/env python3
"""
scripts/local_invoke.py <path-to-csv> [--bucket <bucket-name>]
Simulates an S3 put event by monkeypatching utils.read_s3_object to return the file bytes,
then calling handler.handler(event, None).
"""
import sys, os, argparse # Standard libraries for system interaction and command line parsing

# --- Module Resolution Fix ---
# 1. Calculate the repository root (two directories up from 'scripts/local_invoke.py').
repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# 2. Add the project root to sys.path to resolve 'src' as a package.
sys.path.append(repo_root)

# Import the handler and utils modules as aliases for patching.
import src.handler as handler_mod # <-- Changed import to get module reference
import src.utils as utils_mod

def main():
    # 1. Setup Argument Parsing
    p = argparse.ArgumentParser()
    p.add_argument("csv", help="Path to CSV file to simulate uploading")
    p.add_argument("--bucket", default="local-bucket", help="Mock S3 bucket name")
    args = p.parse_args()
    
    csv_path = os.path.abspath(args.csv)
    
    # 2. Check File Existence
    if not os.path.exists(csv_path):
        print("CSV not found:", csv_path)
        sys.exit(2)
        
    # 3. Backup original functions for cleanup
    orig_read = utils_mod.read_s3_object
    orig_write = utils_mod.write_s3_json
    
    # Use a try...finally block to ensure the original functions are always restored
    try:
        # 4. Load the file data into memory
        with open(csv_path, "rb") as fh:
            data = fh.read()
            
        # 5. Monkeypatch read_s3_object (The Mock Read)
        # The S3 read function is replaced with a lambda that simply returns the local file data.
        mock_read = lambda b,k: data
        utils_mod.read_s3_object = mock_read
        
        # !!! CRITICAL FIX: Patch the handler module's internal reference as well !!!
        handler_mod.read_s3_object = mock_read 
        
        # 6. Monkeypatch write_s3_json (The Mock Write/Capture)
        captured = {}
        mock_write = lambda b,k,p,acl=None: captured.setdefault(k, p) # Added acl=None for robust matching
        utils_mod.write_s3_json = mock_write
        
        # !!! CRITICAL FIX: Patch the handler module's internal reference as well !!!
        handler_mod.write_s3_json = mock_write
        
        # 7. Create Mock S3 Event Payload
        event = {"Records":[
            {"s3":{
                "bucket":{"name":args.bucket},
                "object":{"key":os.path.basename(csv_path)}
            }}
        ]}
        
        # 8. Invoke the Handler
        out = handler_mod.handler(event, None) # <-- Call handler using the module alias
        
        # 9. Output Results
        print("Handler output:", out)
        print("Captured report keys:", list(captured.keys()))
        
        # Optionally pretty print report content
        import json
        for k,v in captured.items():
            print("\nReport:", k)
            # Print the beginning of the JSON report for quick verification
            print(json.dumps(v, indent=2)[:400] + "...") 
            
    finally:
        # 10. Cleanup: Restore original functions
        utils_mod.read_s3_object = orig_read
        utils_mod.write_s3_json = orig_write
        
        # Restore handler module's original references
        handler_mod.read_s3_object = orig_read
        handler_mod.write_s3_json = orig_write

if __name__ == "__main__":
    main()