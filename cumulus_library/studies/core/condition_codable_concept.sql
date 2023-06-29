-- noqa: disable=all
/*
This is a reference output of the SQL generated by denormalizer.py that is
used by the core__condition table. It is not invoked directly. We may
in the future change the priority order of concept systems, or add
additional systems to support other implementations if we run into
unusual data in the wild.
*/
CREATE TABLE core__condition_codable_concepts AS (
    WITH

    system_0 AS (
        SELECT DISTINCT
            s.id AS id,
            '0' AS priority,
            u.codeable_concept.code AS code,
            u.codeable_concept.display AS display,
            u.codeable_concept.system AS code_system
        FROM
            condition AS s,
            UNNEST(s.code.coding) AS u (codeable_concept) --noqa: AL05
        WHERE
            u.codeable_concept.system = 'http://snomed.info/sct'
    ), --noqa: LT07

    system_1 AS (
        SELECT DISTINCT
            s.id AS id,
            '1' AS priority,
            u.codeable_concept.code AS code,
            u.codeable_concept.display AS display,
            u.codeable_concept.system AS code_system
        FROM
            condition AS s,
            UNNEST(s.code.coding) AS u (codeable_concept) --noqa: AL05
        WHERE
            u.codeable_concept.system = 'http://hl7.org/fhir/sid/icd-10-cm'
    ), --noqa: LT07

    system_2 AS (
        SELECT DISTINCT
            s.id AS id,
            '2' AS priority,
            u.codeable_concept.code AS code,
            u.codeable_concept.display AS display,
            u.codeable_concept.system AS code_system
        FROM
            condition AS s,
            UNNEST(s.code.coding) AS u (codeable_concept) --noqa: AL05
        WHERE
            u.codeable_concept.system = 'http://hl7.org/fhir/sid/icd-9-cm'
    ), --noqa: LT07

    union_table AS (
        SELECT
            id,
            priority,
            code_system,
            code,
            display
        FROM system_0
        UNION
        SELECT
            id,
            priority,
            code_system,
            code,
            display
        FROM system_1
        UNION
        SELECT
            id,
            priority,
            code_system,
            code,
            display
        FROM system_2
        ORDER BY id, priority
    )

    SELECT
        id,
        code,
        code_system,
        display
    FROM (
        SELECT
            id,
            code,
            code_system,
            display,
            ROW_NUMBER()
            OVER (
                PARTITION BY id
            ) AS available_priority
        FROM union_table
        GROUP BY id, code_system, code, display
    )
    WHERE available_priority = 1
);