### Architecture v001

**Primary Flow:** The S3 input bucket triggers an AWS Lambda function (Data QC). The Lambda processes the file and writes the resulting QC JSON to the `reports/` prefix within the **same bucket**.

**Future Enhancements (Optional):**

* **Analytics:** Catalog reports into AWS Athena.

* **Monitoring:** Use Amazon SNS for alerts on critical validation failures.

**Status:**

* **Created:** 2025-11-29
