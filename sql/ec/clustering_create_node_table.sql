DROP TABLE IF EXISTS {schema_2}.{table_nodes_original} CASCADE;
CREATE TABLE {schema_2}.{table_nodes_original} AS


--Tower nodes: they have the weight of the population of the uncovered settlements they give access to
SELECT
I.tower_id::TEXT AS node_id,
0 AS node_weight,

CASE WHEN (tech_3g IS TRUE OR tech_4g IS TRUE) AND fiber IS TRUE THEN 'TOWER 3G+ FIBER'
     WHEN (tech_3g IS TRUE OR tech_4g IS TRUE) AND radio IS TRUE THEN 'TOWER 3G+ RADIO'
     WHEN tech_2g IS TRUE AND fiber IS TRUE THEN 'TOWER 2G FIBER'
     WHEN tech_2g IS TRUE AND radio IS TRUE THEN 'TOWER 2G RADIO'
     WHEN tech_2g IS TRUE AND satellite IS TRUE THEN 'TOWER 2G SATELLITE' 
     ELSE 'TOWER' END AS node_type,
I.latitude,
I.longitude,
I.geom
LEFT JOIN {schema}.{table_infrastructure} I
LEFT JOIN {schema}.{table_franchises} F
ON I.tower_id::TEXT = F.centroid
WHERE  I.tech_4g IS FALSE AND I.tech_3g IS FALSE
GROUP BY I.tower_id, I.geom, I.latitude, I.longitude, node_type

UNION

--Settlement nodes

SELECT 
S.settlement_id AS node_id,
CASE WHEN C.movistar_3g_corrected IS TRUE OR C.movistar_4g_corrected IS TRUE THEN 0
     ELSE S.population_corrected::FLOAT END AS node_weight,
CASE WHEN movistar_3g_corrected IS TRUE OR movistar_4g_corrected IS TRUE THEN CONCAT('SETTLEMENT 3G+',' ',franchise)
     WHEN movistar_2g_corrected IS TRUE THEN CONCAT('SETTLEMENT 2G',' ',franchise) 
     WHEN movistar_2g_corrected IS FALSE THEN CONCAT('SETTLEMENT GREENFIELD',' ',franchise) END AS node_type,     
S.latitude,
S.longitude,
S.geom
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_coverage}  C
ON S.settlement_id = C.settlement_id
LEFT JOIN {schema}.{table_franchises} F
ON S.settlement_id = F.centroid
WHERE movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE
;

--CREATE INDEX node_location_gix ON {schema_2}.{table_nodes_original} USING GIST (geom);
--CREATE INDEX node_id_ix ON {schema_2}.{table_nodes_original} (node_id);

