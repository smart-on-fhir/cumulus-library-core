-- ############################################################
-- FHIR Patient
-- http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient

CREATE TABLE core__patient AS
WITH temp_patient AS (
    SELECT DISTINCT
        p.gender,
        er.race_display,
        ee.ethnicity_display,
        p.address,
        p.id AS subject_id,
        date(concat(p.birthdate, '-01-01')) AS birthdate,
        concat('Patient/', p.id) AS subject_ref
    FROM
        patient AS p
    LEFT JOIN core__patient_ext_race AS er ON p.id = er.id
    LEFT JOIN core__patient_ext_ethnicity AS ee ON p.id = ee.id
)

SELECT DISTINCT
    tp.gender,
    tp.birthdate,
    date_diff('year', tp.birthdate, current_date) AS age,
    CASE
        WHEN
            t_address.addr_row.postalcode IS NOT NULL
            THEN substr(t_address.addr_row.postalcode, 1, 3)
        ELSE '?'
    END AS postalcode3,
    tp.subject_id,
    tp.subject_ref,
    coalesce(tp.race_display, ARRAY['unknown']) AS race_display,
    coalesce(tp.ethnicity_display, ARRAY['unknown']) AS ethnicity_display
FROM
    temp_patient AS tp,
    unnest(tp.address) AS t_address (addr_row) --noqa: AL05

WHERE
    tp.birthdate IS NOT NULL
    AND tp.gender IS NOT NULL;


CREATE TABLE core__count_patient AS
WITH powerset AS (
    SELECT
        count(DISTINCT cp.subject_ref) AS cnt_subject,
        cp.gender,
        cp.age,
        cp.race_display,
        cp.ethnicity_display
    FROM core__patient AS cp
    GROUP BY cube(cp.gender, cp.age, cp.race_display, cp.ethnicity_display)
)

SELECT
    cnt_subject AS cnt,
    gender,
    age,
    race_display,
    ethnicity_display
FROM powerset
WHERE cnt_subject >= 10
ORDER BY cnt DESC;
