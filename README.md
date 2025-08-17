#AML Risk Scoring Pipeline (SQL)

Data set - https://www.kaggle.com/datasets/berkanoztas/synthetic-transaction-monitoring-dataset-aml
Anti Money Laundering Transaction Data (SAML-D)
#  AML Risk Scoring Pipeline (SQL)
Please reference the paper below if you use our dataset.
B. Oztas, D. Cetinkaya, F. Adedoyin, M. Budka, H. Dogan and G. Aksu, "Enhancing Anti-Money Laundering: Development of a Synthetic Transaction Monitoring Dataset," 2023 IEEE International Conference on e-Business Engineering (ICEBE), Sydney, Australia, 2023, pp. 47-54, doi: 10.1109/ICEBE59045.2023.00028.
https://ieeexplore.ieee.org/document/10356193

Money laundering remains a significant global issue, driving the need for improved transaction monitoring methods. Current anti-money laundering (AML) procedures are inefficient, and access to data is difficult/restricted by legal and privacy issues. Moreover, existing data often lacks diversity and true labels. This study introduces a novel AML transaction generator, creating the SAML-D dataset with enhanced features and typologies, aiming to aid researchers in evaluating their models and developing more advanced monitoring methods.

The dataset incorporates 12 features and 28 typologies (split between 11 normal and 17 suspicious). These were selected based on existing datasets, the academic literature, and interviews with AML specialists. The dataset comprises 9,504,852 transactions, of which 0.1039% are suspicious. It also includes 15 graphical network structures to represent the transaction flow within these typologies. The structures, while sometimes shared among typologies, vary significantly in parameters to increase complexities and challenge detection efforts. More details about these typologies are available in the paper above. The dataset is an updated version compared to the paper.

Features of the SAML-D dataset:

• Time and Date: Essential for tracking transaction chronology.

• Sender and Receiver Account Details: Helps uncover behavioural patterns and complex banking connections.

• Amount: Indicates transaction values to identify suspicious activities.

• Payment Type: Includes various methods like credit card, debit card, cash, ACH transfers, cross-border, and cheque.

• Sender and Receiver Bank Location: Pinpoints high-risk regions including Mexico, Turkey, Morocco, and the UAE.

• Payment and Receiver Currency: Align with location features, adding complexity when mismatched.

• 'Is Suspicious' Feature: Binary indicator differentiating normal from suspicious transactions.

• Type: Classifies typologies, offering deeper insights.

## Overview

This project implements a rule-based Anti-Money Laundering (AML) pipeline using SQL.
It processes raw transaction data to detect suspicious behavior by scoring transaction risk and flagging high-risk cases.



## Features

*  **Data Isolation** – Creates a working copy of the original dataset
* **Data Cleaning** – Removes manually labeled or unused columns
* **Risk Scoring** – Assigns numeric risk scores using predefined rules
* **Suspicious Flagging** – Flags transactions that exceed risk thresholds
* **Behavioral Summary** – Aggregates transaction metrics per sender
* **Export** – Saves high-risk transactions for review or reporting

---

##  Pipeline Steps

1. **Backup Original Table**

   ```sql
   SELECT * INTO dbo.SAML_Cleaned FROM dbo.[SAML-D];
   ```

2. **Drop Unused Columns**

   ```sql
   ALTER TABLE dbo.SAML_Cleaned DROP COLUMN Is_laundering, Laundering_type;
   ```

3. **Create Risk Scoring View**

   ```sql
   CREATE OR ALTER VIEW vw_RiskScore_Evaluated AS
   SELECT ..., 
       (
           CASE WHEN Amount > 10000 THEN 2 ELSE 0 END +
           CASE WHEN Payment_type = 'Cross-border' THEN 2 ELSE 0 END +
           CASE WHEN Payment_currency != Received_currency THEN 1 ELSE 0 END +
           CASE WHEN Sender_bank_location != Receiver_bank_location THEN 1 ELSE 0 END
       ) AS risk_score
   FROM dbo.SAML_Cleaned;
   ```

4. **Flag Suspicious Transactions**

   ```sql
   CREATE OR ALTER VIEW vw_SuspiciousFlags AS
   SELECT *, 
       CASE WHEN risk_score >= 5 THEN 1 ELSE 0 END AS is_suspicious
   FROM vw_RiskScore_Evaluated;
   ```

5. **Sender Account Summary**

   ```sql
   CREATE OR ALTER VIEW vw_SenderStats AS
   SELECT Sender_account, COUNT(*) AS total_transactions, ...
   FROM dbo.SAML_Cleaned
   GROUP BY Sender_account;
   ```

6. **Export Flagged Transactions**

   ```sql
   SELECT * INTO dbo.AML_Export_Flag
   FROM vw_SuspiciousFlags
   WHERE is_suspicious = 1;
   ```

7. **Final Review**

   ```sql
   SELECT * FROM dbo.AML_Export_Flag
   ORDER BY Sender_account, Receiver_account;
   ```

---

## Requirements

* SQL Server or compatible RDBMS
* Access to transaction dataset (`SAML-D`)

---

##Future Improvements

* Add `risk_category` column (e.g., Low/Medium/High)
* Include time-based or regional pattern detection
* Integrate with BI dashboards (e.g., Power BI, Tableau)

