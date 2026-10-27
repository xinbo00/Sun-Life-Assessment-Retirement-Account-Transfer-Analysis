
DROP VIEW IF EXISTS view_summary_clean;
DROP VIEW IF EXISTS v_member_analytics;

CREATE VIEW view_summary_clean AS
WITH base AS (
    SELECT
        *,
        TRIM(termination_date) AS termination_date_raw,
        TRIM(rollover_dt) AS rollover_dt_raw,
        TRIM(withdrawal_date) AS withdrawal_date_raw,
        TRIM(FSC_Call_1st_Atmpt_dt) AS fsc_call_raw,
        TRIM(Client_1st_Inbound_dt) AS inbound_raw,
        TRIM(FSC_1st_Email_dt) AS fsc_email_raw,
        TRIM(DBA_RO_Email_dt) AS dba_email_raw,
        TRIM(Min_DBA_created_date) AS min_dba_raw
    FROM summary
),
cleaned AS (
    SELECT
        *,

        CASE
            WHEN termination_date_raw = '' THEN NULL
            WHEN SUBSTR(termination_date_raw, 5, 1) IN ('/', '-')
                 AND INSTR(SUBSTR(termination_date_raw, 6), SUBSTR(termination_date_raw, 5, 1)) > 0
            THEN
                CASE
                    WHEN CAST(SUBSTR(termination_date_raw, 1, 4) AS INTEGER) BETWEEN 1900 AND 2100
                         AND CAST(SUBSTR(SUBSTR(termination_date_raw, 6), 1, INSTR(SUBSTR(termination_date_raw, 6), SUBSTR(termination_date_raw, 5, 1)) - 1) AS INTEGER) BETWEEN 1 AND 12
                         AND DATE(PRINTF(
                             '%04d-%02d-%02d',
                             CAST(SUBSTR(termination_date_raw, 1, 4) AS INTEGER),
                             CAST(SUBSTR(SUBSTR(termination_date_raw, 6), 1, INSTR(SUBSTR(termination_date_raw, 6), SUBSTR(termination_date_raw, 5, 1)) - 1) AS INTEGER),
                             CAST(SUBSTR(SUBSTR(termination_date_raw, 6), INSTR(SUBSTR(termination_date_raw, 6), SUBSTR(termination_date_raw, 5, 1)) + 1) AS INTEGER)
                         )) = PRINTF(
                             '%04d-%02d-%02d',
                             CAST(SUBSTR(termination_date_raw, 1, 4) AS INTEGER),
                             CAST(SUBSTR(SUBSTR(termination_date_raw, 6), 1, INSTR(SUBSTR(termination_date_raw, 6), SUBSTR(termination_date_raw, 5, 1)) - 1) AS INTEGER),
                             CAST(SUBSTR(SUBSTR(termination_date_raw, 6), INSTR(SUBSTR(termination_date_raw, 6), SUBSTR(termination_date_raw, 5, 1)) + 1) AS INTEGER)
                         )
                    THEN DATE(PRINTF(
                        '%04d-%02d-%02d',
                        CAST(SUBSTR(termination_date_raw, 1, 4) AS INTEGER),
                        CAST(SUBSTR(SUBSTR(termination_date_raw, 6), 1, INSTR(SUBSTR(termination_date_raw, 6), SUBSTR(termination_date_raw, 5, 1)) - 1) AS INTEGER),
                        CAST(SUBSTR(SUBSTR(termination_date_raw, 6), INSTR(SUBSTR(termination_date_raw, 6), SUBSTR(termination_date_raw, 5, 1)) + 1) AS INTEGER)
                    ))
                    ELSE NULL
                END
            ELSE NULL
        END AS termination_date_clean,

        CASE
            WHEN rollover_dt_raw = '' THEN NULL
            WHEN SUBSTR(rollover_dt_raw, 5, 1) IN ('/', '-')
                 AND INSTR(SUBSTR(rollover_dt_raw, 6), SUBSTR(rollover_dt_raw, 5, 1)) > 0
            THEN
                CASE
                    WHEN CAST(SUBSTR(rollover_dt_raw, 1, 4) AS INTEGER) BETWEEN 1900 AND 2100
                         AND CAST(SUBSTR(SUBSTR(rollover_dt_raw, 6), 1, INSTR(SUBSTR(rollover_dt_raw, 6), SUBSTR(rollover_dt_raw, 5, 1)) - 1) AS INTEGER) BETWEEN 1 AND 12
                         AND DATE(PRINTF(
                             '%04d-%02d-%02d',
                             CAST(SUBSTR(rollover_dt_raw, 1, 4) AS INTEGER),
                             CAST(SUBSTR(SUBSTR(rollover_dt_raw, 6), 1, INSTR(SUBSTR(rollover_dt_raw, 6), SUBSTR(rollover_dt_raw, 5, 1)) - 1) AS INTEGER),
                             CAST(SUBSTR(SUBSTR(rollover_dt_raw, 6), INSTR(SUBSTR(rollover_dt_raw, 6), SUBSTR(rollover_dt_raw, 5, 1)) + 1) AS INTEGER)
                         )) = PRINTF(
                             '%04d-%02d-%02d',
                             CAST(SUBSTR(rollover_dt_raw, 1, 4) AS INTEGER),
                             CAST(SUBSTR(SUBSTR(rollover_dt_raw, 6), 1, INSTR(SUBSTR(rollover_dt_raw, 6), SUBSTR(rollover_dt_raw, 5, 1)) - 1) AS INTEGER),
                             CAST(SUBSTR(SUBSTR(rollover_dt_raw, 6), INSTR(SUBSTR(rollover_dt_raw, 6), SUBSTR(rollover_dt_raw, 5, 1)) + 1) AS INTEGER)
                         )
                    THEN DATE(PRINTF(
                        '%04d-%02d-%02d',
                        CAST(SUBSTR(rollover_dt_raw, 1, 4) AS INTEGER),
                        CAST(SUBSTR(SUBSTR(rollover_dt_raw, 6), 1, INSTR(SUBSTR(rollover_dt_raw, 6), SUBSTR(rollover_dt_raw, 5, 1)) - 1) AS INTEGER),
                        CAST(SUBSTR(SUBSTR(rollover_dt_raw, 6), INSTR(SUBSTR(rollover_dt_raw, 6), SUBSTR(rollover_dt_raw, 5, 1)) + 1) AS INTEGER)
                    ))
                    ELSE NULL
                END
            ELSE NULL
        END AS rollover_dt_clean,

        CASE
            WHEN withdrawal_date_raw = '' THEN NULL
            WHEN withdrawal_date_raw NOT GLOB '*[^0-9]*'
                 AND DATE('1899-12-30', '+' || CAST(withdrawal_date_raw AS INTEGER) || ' days')
                     BETWEEN '1900-01-01' AND '2100-12-31'
            THEN DATE('1899-12-30', '+' || CAST(withdrawal_date_raw AS INTEGER) || ' days')
            WHEN withdrawal_date_raw LIKE '%.0'
                 AND REPLACE(withdrawal_date_raw, '.0', '') NOT GLOB '*[^0-9]*'
                 AND DATE('1899-12-30', '+' || CAST(REPLACE(withdrawal_date_raw, '.0', '') AS INTEGER) || ' days')
                     BETWEEN '1900-01-01' AND '2100-12-31'
            THEN DATE('1899-12-30', '+' || CAST(REPLACE(withdrawal_date_raw, '.0', '') AS INTEGER) || ' days')
            ELSE NULL
        END AS withdrawal_date_clean,

        CASE
            WHEN fsc_call_raw = '' THEN NULL
            WHEN SUBSTR(fsc_call_raw, 5, 1) IN ('/', '-')
                 AND INSTR(SUBSTR(fsc_call_raw, 6), SUBSTR(fsc_call_raw, 5, 1)) > 0
            THEN DATE(PRINTF(
                '%04d-%02d-%02d',
                CAST(SUBSTR(fsc_call_raw, 1, 4) AS INTEGER),
                CAST(SUBSTR(SUBSTR(fsc_call_raw, 6), 1, INSTR(SUBSTR(fsc_call_raw, 6), SUBSTR(fsc_call_raw, 5, 1)) - 1) AS INTEGER),
                CAST(SUBSTR(SUBSTR(fsc_call_raw, 6), INSTR(SUBSTR(fsc_call_raw, 6), SUBSTR(fsc_call_raw, 5, 1)) + 1) AS INTEGER)
            ))
            ELSE NULL
        END AS fsc_first_call_date_clean,

        CASE
            WHEN inbound_raw = '' THEN NULL
            WHEN SUBSTR(inbound_raw, 5, 1) IN ('/', '-')
                 AND INSTR(SUBSTR(inbound_raw, 6), SUBSTR(inbound_raw, 5, 1)) > 0
            THEN DATE(PRINTF(
                '%04d-%02d-%02d',
                CAST(SUBSTR(inbound_raw, 1, 4) AS INTEGER),
                CAST(SUBSTR(SUBSTR(inbound_raw, 6), 1, INSTR(SUBSTR(inbound_raw, 6), SUBSTR(inbound_raw, 5, 1)) - 1) AS INTEGER),
                CAST(SUBSTR(SUBSTR(inbound_raw, 6), INSTR(SUBSTR(inbound_raw, 6), SUBSTR(inbound_raw, 5, 1)) + 1) AS INTEGER)
            ))
            ELSE NULL
        END AS client_first_inbound_date_clean,

        CASE
            WHEN fsc_email_raw = '' THEN NULL
            WHEN SUBSTR(fsc_email_raw, 5, 1) IN ('/', '-')
                 AND INSTR(SUBSTR(fsc_email_raw, 6), SUBSTR(fsc_email_raw, 5, 1)) > 0
            THEN DATE(PRINTF(
                '%04d-%02d-%02d',
                CAST(SUBSTR(fsc_email_raw, 1, 4) AS INTEGER),
                CAST(SUBSTR(SUBSTR(fsc_email_raw, 6), 1, INSTR(SUBSTR(fsc_email_raw, 6), SUBSTR(fsc_email_raw, 5, 1)) - 1) AS INTEGER),
                CAST(SUBSTR(SUBSTR(fsc_email_raw, 6), INSTR(SUBSTR(fsc_email_raw, 6), SUBSTR(fsc_email_raw, 5, 1)) + 1) AS INTEGER)
            ))
            ELSE NULL
        END AS fsc_first_email_date_clean,

        CASE
            WHEN dba_email_raw = '' THEN NULL
            WHEN SUBSTR(dba_email_raw, 5, 1) IN ('/', '-')
                 AND INSTR(SUBSTR(dba_email_raw, 6), SUBSTR(dba_email_raw, 5, 1)) > 0
            THEN DATE(PRINTF(
                '%04d-%02d-%02d',
                CAST(SUBSTR(dba_email_raw, 1, 4) AS INTEGER),
                CAST(SUBSTR(SUBSTR(dba_email_raw, 6), 1, INSTR(SUBSTR(dba_email_raw, 6), SUBSTR(dba_email_raw, 5, 1)) - 1) AS INTEGER),
                CAST(SUBSTR(SUBSTR(dba_email_raw, 6), INSTR(SUBSTR(dba_email_raw, 6), SUBSTR(dba_email_raw, 5, 1)) + 1) AS INTEGER)
            ))
            ELSE NULL
        END AS dba_email_date_clean,

        CASE
            WHEN min_dba_raw = '' THEN NULL
            WHEN SUBSTR(min_dba_raw, 5, 1) IN ('/', '-')
                 AND INSTR(SUBSTR(min_dba_raw, 6), SUBSTR(min_dba_raw, 5, 1)) > 0
            THEN DATE(PRINTF(
                '%04d-%02d-%02d',
                CAST(SUBSTR(min_dba_raw, 1, 4) AS INTEGER),
                CAST(SUBSTR(SUBSTR(min_dba_raw, 6), 1, INSTR(SUBSTR(min_dba_raw, 6), SUBSTR(min_dba_raw, 5, 1)) - 1) AS INTEGER),
                CAST(SUBSTR(SUBSTR(min_dba_raw, 6), INSTR(SUBSTR(min_dba_raw, 6), SUBSTR(min_dba_raw, 5, 1)) + 1) AS INTEGER)
            ))
            ELSE NULL
        END AS min_dba_created_date_clean
    FROM base
)
SELECT
    uniqueid AS unique_id,
    spouse_1,

    CAST(NULLIF(TRIM(Term_balance), '') AS REAL) AS term_balance,
    CAST(NULLIF(TRIM(roll_amt), '') AS REAL) AS roll_amt,
    CAST(NULLIF(TRIM(withdrawal_amount), '') AS REAL) AS withdrawal_amount,

    termination_date_clean AS termination_date,
    rollover_dt_clean AS rollover_dt,
    withdrawal_date_clean AS withdrawal_date,

    CAST(NULLIF(TRIM(age), '') AS INTEGER) AS age,
    spnsr_eng_nm AS client_workplace_name,
    province,

    channel_aligned,
    Campaign,

    CASE WHEN CAST(NULLIF(TRIM(FSC_assisted), '') AS REAL) > 0 THEN 1 ELSE 0 END AS fsc_assisted,
    CASE WHEN CAST(NULLIF(TRIM(Self_Serve), '') AS REAL) > 0 THEN 1 ELSE 0 END AS self_serve,
    CASE WHEN CAST(NULLIF(TRIM(AUTO), '') AS REAL) > 0 THEN 1 ELSE 0 END AS auto,

    CAST(NULLIF(TRIM(FSC_Call_Atmpts), '') AS INTEGER) AS fsc_call_attempts,
    CAST(NULLIF(TRIM(FSC_Contacted_SpoketoMember), '') AS INTEGER) AS fsc_contacted_member,
    CAST(NULLIF(TRIM(Inbound_Freq), '') AS INTEGER) AS inbound_freq,
    CAST(NULLIF(TRIM(FSC_Email_Freq), '') AS INTEGER) AS fsc_email_freq,

    CASE
        WHEN fsc_call_raw = '' THEN NULL
        WHEN fsc_first_call_date_clean = PRINTF(
            '%04d-%02d-%02d',
            CAST(SUBSTR(fsc_call_raw, 1, 4) AS INTEGER),
            CAST(SUBSTR(SUBSTR(fsc_call_raw, 6), 1, INSTR(SUBSTR(fsc_call_raw, 6), SUBSTR(fsc_call_raw, 5, 1)) - 1) AS INTEGER),
            CAST(SUBSTR(SUBSTR(fsc_call_raw, 6), INSTR(SUBSTR(fsc_call_raw, 6), SUBSTR(fsc_call_raw, 5, 1)) + 1) AS INTEGER)
        )
        THEN fsc_first_call_date_clean
        ELSE NULL
    END AS fsc_first_call_date,
    CASE
        WHEN inbound_raw = '' THEN NULL
        WHEN client_first_inbound_date_clean = PRINTF(
            '%04d-%02d-%02d',
            CAST(SUBSTR(inbound_raw, 1, 4) AS INTEGER),
            CAST(SUBSTR(SUBSTR(inbound_raw, 6), 1, INSTR(SUBSTR(inbound_raw, 6), SUBSTR(inbound_raw, 5, 1)) - 1) AS INTEGER),
            CAST(SUBSTR(SUBSTR(inbound_raw, 6), INSTR(SUBSTR(inbound_raw, 6), SUBSTR(inbound_raw, 5, 1)) + 1) AS INTEGER)
        )
        THEN client_first_inbound_date_clean
        ELSE NULL
    END AS client_first_inbound_date,
    CASE
        WHEN fsc_email_raw = '' THEN NULL
        WHEN fsc_first_email_date_clean = PRINTF(
            '%04d-%02d-%02d',
            CAST(SUBSTR(fsc_email_raw, 1, 4) AS INTEGER),
            CAST(SUBSTR(SUBSTR(fsc_email_raw, 6), 1, INSTR(SUBSTR(fsc_email_raw, 6), SUBSTR(fsc_email_raw, 5, 1)) - 1) AS INTEGER),
            CAST(SUBSTR(SUBSTR(fsc_email_raw, 6), INSTR(SUBSTR(fsc_email_raw, 6), SUBSTR(fsc_email_raw, 5, 1)) + 1) AS INTEGER)
        )
        THEN fsc_first_email_date_clean
        ELSE NULL
    END AS fsc_first_email_date,

    CASE
        WHEN dba_email_raw = '' THEN NULL
        WHEN dba_email_date_clean = PRINTF(
            '%04d-%02d-%02d',
            CAST(SUBSTR(dba_email_raw, 1, 4) AS INTEGER),
            CAST(SUBSTR(SUBSTR(dba_email_raw, 6), 1, INSTR(SUBSTR(dba_email_raw, 6), SUBSTR(dba_email_raw, 5, 1)) - 1) AS INTEGER),
            CAST(SUBSTR(SUBSTR(dba_email_raw, 6), INSTR(SUBSTR(dba_email_raw, 6), SUBSTR(dba_email_raw, 5, 1)) + 1) AS INTEGER)
        )
        THEN dba_email_date_clean
        ELSE NULL
    END AS dba_email_date,
    CAST(NULLIF(TRIM(DBA_RO_Email_Num), '') AS INTEGER) AS dba_email_sent,
    CAST(NULLIF(TRIM(DBA_Email_Open), '') AS INTEGER) AS dba_email_opened,
    CAST(NULLIF(TRIM(DBA_Email_Click), '') AS INTEGER) AS dba_email_clicked,
    CASE
        WHEN min_dba_raw = '' THEN NULL
        WHEN min_dba_created_date_clean = PRINTF(
            '%04d-%02d-%02d',
            CAST(SUBSTR(min_dba_raw, 1, 4) AS INTEGER),
            CAST(SUBSTR(SUBSTR(min_dba_raw, 6), 1, INSTR(SUBSTR(min_dba_raw, 6), SUBSTR(min_dba_raw, 5, 1)) - 1) AS INTEGER),
            CAST(SUBSTR(SUBSTR(min_dba_raw, 6), INSTR(SUBSTR(min_dba_raw, 6), SUBSTR(min_dba_raw, 5, 1)) + 1) AS INTEGER)
        )
        THEN min_dba_created_date_clean
        ELSE NULL
    END AS min_dba_created_date
FROM cleaned;

CREATE VIEW v_member_analytics AS
SELECT
    *,
    CASE WHEN roll_amt > 0 THEN 1 ELSE 0 END AS successful_rollover_flag,
    CASE WHEN withdrawal_amount > 0 THEN 1 ELSE 0 END AS withdrawal_flag,
    CASE
        WHEN term_balance < 50000 THEN 'Low'
        WHEN term_balance < 150000 THEN 'Medium'
        ELSE 'High'
    END AS balance_tier,
    CASE
        WHEN age < 40 THEN '<40'
        WHEN age < 60 THEN '40-59'
        ELSE '60+'
    END AS age_bracket,
    CASE WHEN dba_email_opened = 1 OR dba_email_clicked = 1 THEN 1 ELSE 0 END AS digital_engagement_flag,
    CASE
        WHEN channel_aligned = 'FSC only' THEN 'FSC_Only'
        WHEN channel_aligned = 'Dual' THEN 'Dual'
        WHEN channel_aligned = 'Digital only' THEN 'Digital_Only'
        WHEN channel_aligned = 'No proactive Epic "Changing Employer" or FSC' THEN 'No_Proactive'
        ELSE 'Other'
    END AS channel_segment
FROM view_summary_clean;

DROP TABLE IF EXISTS summary_clean;

CREATE TABLE summary_clean AS
SELECT *
FROM view_summary_clean;