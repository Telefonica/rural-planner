CREATE OR REPLACE VIEW
    {schema}.v_segmentacion_clusters_3g
    (
        centroide,
        segmento_overlay,
        segmento_greenfield,
        segmento_fully_unconnected
    ) AS
SELECT 
    cl.centroide,
    CASE         
        WHEN cl.poblacion_no_conectada_movistar=0 then NULL::text
        WHEN (i.tower_id IS NOT NULL) AND cl.id_nodos_cluster IS NOT NULL
        THEN CONCAT('OVERLAY',' ',(CASE WHEN i.owner IS NULL THEN '' ELSE i.owner END))::text
        ELSE NULL::text
    END AS segmento_overlay,
    CASE WHEN cl.poblacion_no_conectada_movistar=0 then NULL::text
           WHEN i.tower_id IS NOT NULL THEN NULL::text
    ELSE CONCAT('GREENFIELD',' ',(CASE WHEN i.owner IS NULL THEN '' ELSE i.owner END))::text
    END AS segmento_greenfield,
    CASE WHEN cc.competitors_presence_4g<>0 AND cc.competitors_presence_3g<>0 
        THEN NULL::text       
        WHEN cl.poblacion_no_conectada_movistar=0 then NULL::text
        WHEN (i.tower_id IS NOT NULL) AND cl.id_nodos_cluster IS NOT NULL
        THEN CONCAT('OVERLAY',' ',(CASE WHEN i.owner IS NULL THEN '' ELSE i.owner END))::text
        WHEN i.tower_id IS NULL AND cl.id_nodos_cluster IS NOT NULL
        THEN CONCAT('GREENFIELD',' ',(CASE WHEN i.owner IS NULL THEN '' ELSE i.owner END))::text
        ELSE NULL::text
    END AS segmento_fully_unconnected    
FROM
    (({schema}.v_clusters_3g cl
LEFT JOIN
    {schema}.infrastructure_global i
ON
    ((
            cl.centroide = (i.tower_id)::text)))
LEFT JOIN
    {schema}.v_segmentacion s
ON
    ((
            cl.centroide = s.codigo_divipola))
LEFT JOIN
    {schema}.v_coberturas_clusters_3g cc
ON
    ((
            cl.centroide = cc.centroid))            
            );