-- ############################################################
-- FHIR Patient
-- http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient

DROP TABLE IF EXISTS core_patient;

CREATE TABLE core_patient AS
WITH temp_patient AS (
    SELECT DISTINCT
        gender,
        extension,
        address,
        id AS subject_id,
        date(concat(birthdate, '-01-01')) AS birthdate,
        concat('Patient/', id) AS subject_ref
    FROM
        patient
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
    t_extension.ext_row.valuecoding AS race,
    tp.subject_id,
    tp.subject_ref
FROM
    temp_patient AS tp,
    unnest(address) AS t_address(addr_row), --noqa
    unnest(extension) AS t_extension_root(ext_root), --noqa
    unnest(ext_root.extension) AS t_extension(ext_row) --noqa
WHERE
    tp.birthdate IS NOT NULL
    AND tp.gender IS NOT NULL;

-- count demographics
CREATE OR REPLACE VIEW count_core_patient AS
WITH powerset AS (
    SELECT
        count(DISTINCT core_patient.subject_ref) AS cnt_subject,
        core_patient.gender,
        core_patient.age,
        race.display AS race_display
    FROM core_patient
    GROUP BY cube(core_patient.gender, core_patient.age, core_patient.race)
)

SELECT
    cnt_subject AS cnt,
    gender,
    age,
    race_display
FROM powerset
WHERE cnt_subject >= 10
ORDER BY cnt DESC;