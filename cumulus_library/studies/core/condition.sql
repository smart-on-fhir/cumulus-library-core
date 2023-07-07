-- ############################################################
-- Condition
-- https://build.fhir.org/ig/HL7/US-Core/StructureDefinition-us-core-condition-encounter-diagnosis.html
-- 
--Each Condition must have:
--    a category code of “problem-list-item” or “health-concern”
--    a code that identifies the condition
--    a patient
--Each Condition must support:
--    a clinical status of the condition (e.g., active or resolved)
--    a verification status
--    a category code of ‘sdoh’
--    a date of diagnosis*
--    abatement date (in other words, date of resolution or remission)
--    a date when recorded


CREATE TABLE core__condition AS
WITH temp_condition AS (
    SELECT
        c.category,
        c.code,
        c.clinicalstatus,
        c.verificationstatus,
        c.subject.reference AS subject_ref,
        c.encounter.reference AS encounter_ref,
        c.id AS condition_id,
        date(from_iso8601_timestamp(c.recordeddate)) AS recordeddate,
        concat('Condition/', c.id) AS condition_ref
    FROM condition AS c
)

SELECT
    t_category_coding.category_row AS category,
    tc.code AS cond_code,
    tc.subject_ref,
    tc.encounter_ref,
    tc.condition_id,
    tc.condition_ref,
    tc.recordeddate,
    date_trunc('week', date(tc.recordeddate)) AS recorded_week,
    date_trunc('month', date(tc.recordeddate)) AS recorded_month,
    date_trunc('year', date(tc.recordeddate)) AS recorded_year
FROM temp_condition AS tc,
    unnest(category) AS t_category (category_coding), --noqa
    unnest(category_coding.coding) AS t_category_coding (category_row), --noqa
    unnest(code.coding) AS t_coding (code_row) --noqa
WHERE tc.recordeddate BETWEEN date('2016-01-01') AND current_date;

CREATE TABLE core__count_condition_month AS
WITH powerset AS (
    SELECT
        count(DISTINCT cc.subject_ref) AS cnt_subject,
        count(DISTINCT cc.encounter_ref) AS cnt_encounter,
        cccc.display AS display,
        cc.recorded_month,
        ce.enc_class
    FROM core__condition AS cc
    INNER JOIN core__encounter AS ce
        ON cc.encounter_ref = ce.encounter_ref
    LEFT JOIN core__condition_codable_concepts AS cccc
        ON cc.condition_id = cccc.id
    GROUP BY cube(display, cc.recorded_month, ce.enc_class)
)

SELECT
    powerset.cnt_subject AS cnt,
    powerset.recorded_month AS cond_month,
    powerset.display AS cond_code_display,
    enc_class.display AS enc_class_code
FROM powerset
WHERE powerset.cnt_subject >= 10
ORDER BY powerset.cnt_subject DESC, powerset.cnt_encounter DESC;
