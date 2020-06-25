CREATE OR REPLACE VIEW
    {schema}.v_escuelas
    (
        ubigeo,
        num_escuelas,
        num_alumnos,
        num_escuelas_edu_inicial,
        num_alumnos_edu_inicial,
        num_escuelas_edu_primaria,
        num_alumnos_edu_primaria,
        num_escuelas_edu_secundaria,
        num_alumnos_edu_secundaria,
        num_escuelas_edu_superior,
        num_alumnos_edu_superior,
        num_escuelas_otros,
        num_alumnos_otros,
        num_escuelas_10km,
        num_alumnos_10km
    ) AS
SELECT
    ss.settlement_id              AS ubigeo,
    ss.direct_total_schools       AS num_escuelas,
    ss.direct_total_students      AS num_alumnos,
    ss.direct_initial_education   AS num_escuelas_edu_inicial,
    ss.direct_initial_students    AS num_alumnos_edu_inicial,
    ss.direct_primary_education   AS num_escuelas_edu_primaria,
    ss.direct_primary_students    AS num_alumnos_edu_primaria,
    ss.direct_secondary_education AS num_escuelas_edu_secundaria,
    ss.direct_secondary_students  AS num_alumnos_edu_secundaria,
    ss.direct_superior_education  AS num_escuelas_edu_superior,
    ss.direct_superior_students   AS num_alumnos_edu_superior,
    ss.direct_other_education     AS num_escuelas_otros,
    ss.direct_other_students      AS num_alumnos_otros,
    ss.indirect_total_schools     AS num_escuelas_10km,
    ss.indirect_total_students    AS num_alumnos_10km
FROM
    {schema}.schools_summary ss;
