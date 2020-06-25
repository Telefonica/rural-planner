CREATE OR REPLACE VIEW
    {schema}.v_segmentacion_clusters
    (
        centroide,
        segmento_overlay,
        segmento_greenfield
    ) AS
SELECT
    cl.centroide,
    CASE
        WHEN (i.type = 'MACRO'::text)
        THEN 'OVERLAY MACRO'::text
        WHEN (i.type = 'FEMTO'::text)
        THEN 'OVERLAY FEMTO'::text
        ELSE NULL::text
    END AS segmento_overlay,
    s.segmento_greenfield
FROM
    (({schema}.v_clusters cl
LEFT JOIN
    {schema}.infrastructure_global i
ON
    ((
            cl.centroide = (i.tower_id)::text)))
LEFT JOIN
    {schema}.v_segmentacion s
ON
    ((
            cl.centroide = s.ubigeo)));
