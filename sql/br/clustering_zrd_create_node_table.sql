DROP TABLE IF EXISTS {schema}.{table_nodes_original};
CREATE TABLE {schema}.{table_nodes_original} AS


--ZRD nodes:
SELECT 
S.settlement_id AS node_id,
CASE WHEN (C.vivo_4g_corrected IS FALSE) THEN S.population_corrected::FLOAT 
     ELSE 0 END AS node_weight,
CASE WHEN (C.vivo_4g_corrected IS TRUE) THEN 'SETTLEMENT ZRD 4G'
     WHEN (C.vivo_3g_corrected IS TRUE) THEN 'SETTLEMENT ZRD 3G'
     WHEN (C.vivo_2g_corrected IS TRUE) THEN 'SETTLEMENT ZRD 2G' 
     ELSE 'SETTLEMENT ZRD GREENFIELD' END AS node_type,
S.latitude,
S.longitude,
ST_Transform(S.geom,3857) as geom
FROM {schema}.{table_settlements_zrd} S
LEFT JOIN {schema}.{table_coverage_zrd} C
ON S.settlement_id = C.settlement_id
WHERE C.vivo_4g_corrected IS FALSE 

UNION

--Longtail nodes 2G OR LESS
SELECT 
S.settlement_id AS node_id,
CASE WHEN C.vivo_3g_corrected IS TRUE OR C.vivo_4g_corrected IS TRUE THEN 0
     ELSE S.population_corrected::FLOAT END AS node_weight,
CASE WHEN vivo_3g_corrected IS TRUE OR vivo_4g_corrected IS TRUE THEN 'SETTLEMENT 3G+'
     WHEN vivo_2g_corrected IS TRUE THEN 'SETTLEMENT 2G' 
     WHEN vivo_2g_corrected IS FALSE THEN 'SETTLEMENT GREENFIELD' END AS node_type,
S.latitude,
S.longitude,
ST_Transform(S.geom,3857) as geom
FROM (SELECT L.node_2_id AS settlement_id
        FROM {schema}.{table_links_main} L
        LEFT JOIN {schema}.{table_nodes_main} N
        ON L.centroid=N.node_id
        WHERE LENGTH(L.node_2_id)>=15 AND (L.cluster_weight<500 AND N.node_type NOT LIKE '%%2G%%')
        UNION
    SELECT centroid AS settlement_id
        FROM {schema}.{table_links_main} L
        LEFT JOIN {schema}.{table_nodes_main} N
        ON L.centroid=N.node_id
        WHERE LENGTH(centroid)>=15 AND (L.cluster_weight<500 AND N.node_type NOT LIKE '%%2G%%')) A
LEFT JOIN {schema}.{table_settlements} S
ON S.settlement_id=A.settlement_id
LEFT JOIN {schema}.{table_coverage} C
ON S.settlement_id = C.settlement_id
WHERE vivo_3g_corrected IS FALSE AND vivo_4g_corrected IS FALSE;