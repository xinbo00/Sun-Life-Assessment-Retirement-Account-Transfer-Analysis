DROP TABLE IF EXISTS summary_clean;
DROP VIEW IF EXISTS v_summary_amount_row_share;

CREATE VIEW v_summary_amount_row_share AS
WITH row_flags AS (
    SELECT
        rowid AS summary_row_id,
        CASE
            WHEN CAST(NULLIF(TRIM(withdrawal_amount), '') AS REAL) > 0 THEN 1
            ELSE 0
        END AS withdrawal_amount_flag,
        CASE
            WHEN CAST(NULLIF(TRIM(roll_amt), '') AS REAL) > 0 THEN 1
            ELSE 0
        END AS roll_amount_flag
    FROM summary
)
SELECT
    COUNT(summary_row_id) AS total_rows,
    SUM(withdrawal_amount_flag) AS rows_with_withdrawal_amount,
    1.0 * SUM(withdrawal_amount_flag) / COUNT(summary_row_id) AS withdrawal_amount_row_ratio,
    ROUND(100.0 * SUM(withdrawal_amount_flag) / COUNT(summary_row_id), 2) AS withdrawal_amount_row_pct,
    SUM(roll_amount_flag) AS rows_with_roll_amount,
    1.0 * SUM(roll_amount_flag) / COUNT(summary_row_id) AS roll_amount_row_ratio,
    ROUND(100.0 * SUM(roll_amount_flag) / COUNT(summary_row_id), 2) AS roll_amount_row_pct
FROM row_flags;

CREATE TABLE summary_clean AS
SELECT *
FROM view_summary_clean;

DROP TABLE IF EXISTS record_analytics;

CREATE TABLE record_analytics AS
WITH record_base AS (
    SELECT
        summary_clean.*,
        CASE
            WHEN roll_amt > 0 THEN 1
            ELSE 0
        END AS successful_rollover_flag,
        CASE
            WHEN withdrawal_amount > 0 THEN 1
            ELSE 0
        END AS withdrawal_flag,
        CASE
            WHEN term_balance IS NULL THEN 'Unknown'
            WHEN term_balance < 50000 THEN 'Low'
            WHEN term_balance < 150000 THEN 'Medium'
            ELSE 'High'
        END AS balance_tier,
        CASE
            WHEN age IS NULL THEN 'Unknown'
            WHEN age < 40 THEN '<40'
            WHEN age < 60 THEN '40-59'
            ELSE '60+'
        END AS age_bracket,
        CASE
            WHEN dba_email_opened = 1 OR dba_email_clicked = 1 THEN 1
            ELSE 0
        END AS digital_engagement_flag,
        CASE
            WHEN TRIM(channel_aligned) = 'FSC only' THEN 'FSC_Only'
            WHEN TRIM(channel_aligned) = 'Dual' THEN 'Dual'
            WHEN TRIM(channel_aligned) = 'Digital only' THEN 'Digital_Only'
            WHEN TRIM(channel_aligned) = 'No proactive Epic "Changing Employer" or FSC' THEN 'No_Proactive'
            WHEN channel_aligned IS NULL OR TRIM(channel_aligned) = '' THEN 'Unknown'
            ELSE 'Other'
        END AS channel_segment,
        (
            SELECT MIN(contact_date)
            FROM (
                SELECT summary_clean.fsc_first_call_date AS contact_date
                UNION ALL
                SELECT summary_clean.client_first_inbound_date
                UNION ALL
                SELECT summary_clean.fsc_first_email_date
                UNION ALL
                SELECT summary_clean.dba_email_date
                UNION ALL
                SELECT summary_clean.min_dba_created_date
            )
            WHERE contact_date IS NOT NULL
        ) AS first_contact_date
    FROM summary_clean
),
record_metrics AS (
    SELECT
        record_base.*,
        CASE
            WHEN term_balance IS NULL OR term_balance = 0 THEN NULL
            ELSE roll_amt / term_balance
        END AS retention_ratio,
        CASE
            WHEN term_balance IS NULL OR term_balance = 0 THEN NULL
            ELSE withdrawal_amount / term_balance
        END AS withdrawal_ratio,
        CASE
            WHEN rollover_dt IS NULL OR termination_date IS NULL THEN NULL
            ELSE julianday(rollover_dt) - julianday(termination_date)
        END AS days_to_rollover,
        CASE
            WHEN withdrawal_date IS NULL OR termination_date IS NULL THEN NULL
            ELSE julianday(withdrawal_date) - julianday(termination_date)
        END AS days_to_withdrawal,
        CASE
            WHEN first_contact_date IS NULL OR termination_date IS NULL THEN NULL
            ELSE julianday(first_contact_date) - julianday(termination_date)
        END AS days_to_first_contact
    FROM record_base
),
record_final AS (
    SELECT
        record_metrics.*,
        CASE
            WHEN days_to_rollover < 0 THEN 1
            ELSE 0
        END AS negative_days_to_rollover_flag,
        CASE
            WHEN days_to_withdrawal < 0 THEN 1
            ELSE 0
        END AS negative_days_to_withdrawal_flag,
        CASE
            WHEN days_to_first_contact < 0 THEN 1
            ELSE 0
        END AS negative_days_to_first_contact_flag
    FROM record_metrics
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            unique_id,
            termination_date,
            client_workplace_name,
            age,
            Province,
            spouse_1,
            term_balance,
            rollover_dt,
            withdrawal_date
    ) AS row_id,
    record_final.*
FROM record_final;

DROP TABLE IF EXISTS member_metrics;
DROP TABLE IF EXISTS grouped_id_metrics;

DROP TABLE IF EXISTS final_outcome_lookup;

CREATE TABLE final_outcome_lookup AS
SELECT
    row_id,
    CASE
        WHEN COALESCE(roll_amt, 0) > 0
             AND COALESCE(withdrawal_amount, 0) = 0
        THEN 'Full Rollover'
        WHEN COALESCE(withdrawal_amount, 0) > 0
             AND COALESCE(roll_amt, 0) = 0
        THEN 'Full Withdrawal'
        WHEN COALESCE(roll_amt, 0) > 0
             AND COALESCE(withdrawal_amount, 0) > 0
        THEN 'Partial Movement'
        ELSE 'No Movement'
    END AS final_outcome
FROM record_analytics;

SELECT *
FROM record_analytics
LIMIT 20;

SELECT *
FROM grouped_id_metrics
LIMIT 20;

SELECT *
FROM final_outcome_lookup
LIMIT 20;
