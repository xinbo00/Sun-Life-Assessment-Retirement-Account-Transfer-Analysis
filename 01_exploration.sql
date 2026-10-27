
select * from summary
limit 10;

PRAGMA table_info(summary);


select DISTINCT spouse_1 from summary;

select DISTINCT self_serve from summary;

PRAGMA table_info(view_summary_clean);

SELECT typeof(term_balance) AS term_balance_type,
       typeof(age) AS age_type,
       typeof(roll_amt) AS roll_amt_type
FROM view_summary_clean
LIMIT 1;


SELECT
    uniqueid,
    COUNT(*) AS duplicate_count
FROM summary
GROUP BY uniqueid
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

SELECT
    COUNT(*) AS exact_duplicate_patterns,
    COALESCE(SUM(duplicate_count), 0) AS rows_in_exact_duplicate_patterns,
    COALESCE(MAX(duplicate_count), 0) AS max_identical_rows
FROM (
    SELECT
        uniqueid,
        spouse_1,
        Term_balance,
        termination_date,
        age,
        spnsr_eng_nm,
        rollover_dt,
        roll_amt,
        withdrawal_date,
        withdrawal_amount,
        FSC_assisted,
        Self_Serve,
        AUTO,
        Campaign,
        FSC_Call_Atmpts,
        FSC_Contacted_SpoketoMember,
        Inbound_Freq,
        FSC_Email_Freq,
        FSC_Call_1st_Atmpt_dt,
        Client_1st_Inbound_dt,
        FSC_1st_Email_dt,
        DBA_RO_Email_dt,
        DBA_RO_Email_Num,
        DBA_Email_Open,
        DBA_Email_Click,
        Min_DBA_created_date,
        channel_aligned,
        Province,
        COUNT(*) AS duplicate_count
    FROM summary
    GROUP BY
        uniqueid,
        spouse_1,
        Term_balance,
        termination_date,
        age,
        spnsr_eng_nm,
        rollover_dt,
        roll_amt,
        withdrawal_date,
        withdrawal_amount,
        FSC_assisted,
        Self_Serve,
        AUTO,
        Campaign,
        FSC_Call_Atmpts,
        FSC_Contacted_SpoketoMember,
        Inbound_Freq,
        FSC_Email_Freq,
        FSC_Call_1st_Atmpt_dt,
        Client_1st_Inbound_dt,
        FSC_1st_Email_dt,
        DBA_RO_Email_dt,
        DBA_RO_Email_Num,
        DBA_Email_Open,
        DBA_Email_Click,
        Min_DBA_created_date,
        channel_aligned,
        Province
    HAVING COUNT(*) > 1
);

select * from view_summary_clean
limit 20;

select * from summary_clean
where unique_id = 'ABC61764306';

select * from record_analytics
limit 20;

SELECT
    unique_id,
    COUNT(*) AS duplicate_count
FROM member_metrics
GROUP BY unique_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

select * from summary_clean
where unique_id = 'ABC61872810';

select * from grouped_id_metrics
where unique_id = 'ABC61872810';

select * from record_analytics
where unique_id = 'ABC61872810';

SELECT *
FROM summary
WHERE uniqueid IN (
    SELECT uniqueid
    FROM summary
    GROUP BY uniqueid
    HAVING COUNT(*) > 1
)
ORDER BY uniqueid, age;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT row_id) AS distinct_row_id
FROM record_analytics;

SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT row_id) AS distinct_row_id
FROM record_analytics;

select * from summary_clean
where roll_amt > 0 and withdrawal_amount > 0;

SELECT *
FROM record_analytics
LIMIT 20;

SELECT *
FROM grouped_id_metrics
LIMIT 20;

SELECT *
FROM final_outcome_lookup
LIMIT 20;
