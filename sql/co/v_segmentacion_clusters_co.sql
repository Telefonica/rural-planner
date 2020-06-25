CREATE OR REPLACE VIEW
    {schema}.v_segmentacion_clusters
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
        WHEN (i.tower_id IS NOT NULL) AND i.source NOT IN ('ATC','ATP','ANDITEL','PTI','QMC','UNITI') AND cl.centros_poblados IS NOT NULL
        THEN CONCAT('OVERLAY',' ',(CASE WHEN i.source='SITES_TEF' THEN 'TELEFONICA' ELSE i.source END),' ',(CASE WHEN i.owner IS NULL THEN '' ELSE i.owner END))::text
        ELSE NULL::text
    END AS segmento_overlay,
    CASE WHEN (i.tower_id IS NOT NULL) AND i.source NOT IN ('ATC','ATP','ANDITEL','PTI','QMC','UNITI') OR cl.centros_poblados IS NULL
        THEN NULL::text
        WHEN cl.poblacion_no_conectada_movistar=0 then NULL::text
    ELSE CONCAT('GREENFIELD',' ',(CASE WHEN i.source IS NULL then '' WHEN i.source='SITES_TEF' THEN 'TELEFONICA' ELSE i.source END),' ',(CASE WHEN i.owner IS NULL THEN '' ELSE i.owner END))::text
    END AS segmento_greenfield,
    CASE
        WHEN (i.tower_id IS NOT NULL) AND cc.competitors_presence_3g=0 and cc.competitors_presence_4g=0  AND i.source NOT IN ('ATC','ATP','ANDITEL','PTI','QMC','UNITI') AND cl.centros_poblados IS NOT NULL
        THEN CONCAT('OVERLAY',' ',(CASE WHEN i.source='SITES_TEF' THEN 'TELEFONICA' ELSE i.source END))::text
        WHEN ((i.tower_id IS NOT NULL) AND i.source NOT IN ('ATC','ATP','ANDITEL','PTI','QMC','UNITI')) and cc.competitors_presence_4g<>0 AND cc.competitors_presence_3g<>0 
        THEN NULL::text        
        WHEN cl.poblacion_no_conectada_movistar=0 then NULL::text
        WHEN cc.competitors_presence_3g=0 and cc.competitors_presence_4g=0 AND cl.centros_poblados IS NOT NULL
        THEN CONCAT('GREENFIELD',' ',(CASE WHEN i.source IS NULL then '' WHEN i.source='SITES_TEF' THEN 'TELEFONICA' ELSE i.source END))::text
        ELSE NULL
    END AS segmento_fully_unconnected    
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
            cl.centroide = s.codigo_divipola))
LEFT JOIN
    {schema}.v_coberturas_clusters cc
ON
    ((
            cl.centroide = cc.centroid))            
            );
