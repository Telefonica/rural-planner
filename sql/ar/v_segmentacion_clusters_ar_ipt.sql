CREATE OR REPLACE VIEW
    {schema}.v_segmentacion_clusters_ipt
    (
        centroide,
        segmento_overlay,
        segmento_greenfield,
        segmento_fully_unconnected
    ) AS
SELECT
    cl.centroid as centroide,
    CASE
        WHEN (cl.centroid_type LIKE '%%TOWER 2G%%'::text OR cl.centroid_type LIKE '%%TOWER 3G%%'::text)
        THEN 'OVERLAY 2/3G'::text
        ELSE NULL::text
    END AS segmento_overlay,
    CASE
        WHEN (cl.centroid_type LIKE '%%SETTLEMENT%%'::text)
        THEN 'GREENFIELD'::text
        WHEN (cl.centroid_type LIKE '%%TOWER TX%%'::text)
        THEN 'GREENFIELD WITH TX'::text
        WHEN (cl.centroid_type LIKE '%%TOWER NO TX%%'::text)
        THEN 'GREENFIELD WITH INFRA'::text
        ELSE NULL::text
    END AS segmento_greenfield,
    CASE
        WHEN (cl.centroid_type LIKE '%%TOWER 2G%%'::text OR cl.centroid_type LIKE '%%TOWER 3G%%'::text) AND (v.competitors_presence_4g=0)
        THEN 'OVERLAY 2/3G'::text
        WHEN (cl.centroid_type LIKE '%%SETTLEMENT%%'::text) AND (v.competitors_presence_4g=0)
        THEN 'GREENFIELD'::text
        WHEN (cl.centroid_type LIKE '%%TOWER TX%%'::text) AND (v.competitors_presence_4g=0)
        THEN 'GREENFIELD WITH TX'::text
        WHEN (cl.centroid_type LIKE '%%TOWER NO TX%%'::text) AND (v.competitors_presence_4g=0)
        THEN 'GREENFIELD WITH INFRA'::text
        ELSE NULL::text
    END AS segmento_fully_unconnected
FROM {schema}.clusters_ipt cl
LEFT JOIN
    {schema}.v_coberturas_clusters_ipt V
ON cl.centroid = v.centroid;
