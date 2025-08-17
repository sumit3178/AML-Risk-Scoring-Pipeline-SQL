-- Backup Original Table with New Name
SELECT * 
INTO dbo.SAML_Cleaned
FROM dbo.[SAML-D];

--  Drop Unused Columns
ALTER TABLE dbo.SAML_Cleaned
DROP COLUMN Is_laundering, Laundering_type;

-- Create Risk Scoring View (No Currency Tier Logic)
CREATE OR ALTER VIEW vw_RiskScore_Evaluated AS
SELECT 
    t.Time,
    t.Date,
    t.Sender_account,
    t.Receiver_account,
    t.Amount,
    t.Payment_currency,
    t.Received_currency,
    t.Sender_bank_location,
    t.Receiver_bank_location,
    t.Payment_type,

    -- Risk scoring logic 
    (
        CASE WHEN t.Amount > 10000 THEN 2 ELSE 0 END +                          -- High-value transaction
        CASE WHEN t.Payment_type = 'Cross-border' THEN 2 ELSE 0 END +          -- Cross-border payment
        CASE WHEN t.Payment_currency != t.Received_currency THEN 1 ELSE 0 END +-- Currency mismatch
        CASE WHEN t.Sender_bank_location != t.Receiver_bank_location THEN 1 ELSE 0 END -- Location mismatch
    ) AS risk_score

FROM dbo.SAML_Cleaned t;
GO

-- Flag Suspicious Transactions
CREATE OR ALTER VIEW vw_SuspiciousFlags AS
SELECT *,
    CASE 
        WHEN risk_score >= 5 THEN 1
        ELSE 0
    END AS is_suspicious
FROM vw_RiskScore_Evaluated;
GO

--  Sender Account Summary
CREATE OR ALTER VIEW vw_SenderStats AS
SELECT 
    Sender_account,
    COUNT(*) AS total_transactions,
    SUM(Amount) AS total_sent_amount,
    AVG(Amount) AS avg_transaction_amount,
    MAX(Amount) AS max_transaction_amount,
    MIN(Amount) AS min_transaction_amount
FROM dbo.SAML_Cleaned
GROUP BY Sender_account;
GO

--  Export Flagged Transactions
SELECT * 
INTO dbo.AML_Export_Flag
FROM vw_SuspiciousFlags
WHERE is_suspicious = 1;


SELECT * 
FROM dbo.AML_Export_Flag
order by Sender_account, Receiver_account 
