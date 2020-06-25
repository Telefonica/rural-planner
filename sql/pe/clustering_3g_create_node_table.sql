DROP TABLE IF EXISTS {schema}.{table_nodes_original};
CREATE TABLE {schema}.{table_nodes_original} AS


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
WHERE I.tech_3g IS TRUE AND I.tech_4g IS FALSE AND I.owner NOT IN ('CLARO','ENTEL','CLARO FIBER') AND in_service='IN SERVICE'

UNION

--Settlement nodes: they have the weight of their population if: they are uncovered and they do not have 2G access tower. Otherwise they have a weight of zero
SELECT 
S.settlement_id AS node_id,
CASE WHEN C.movistar_3g_corrected IS TRUE AND C.movistar_4g_corrected IS FALSE THEN S.population_corrected::FLOAT
     ELSE 0 END AS node_weight,
CASE WHEN movistar_3g_corrected IS TRUE OR movistar_4g_corrected IS TRUE THEN 'SETTLEMENT 3G+'
     WHEN I.tower_id IS NOT NULL THEN 'SETTLEMENT PERIURBAN 3G+'
     WHEN movistar_2g_corrected IS TRUE THEN 'SETTLEMENT 2G' 
     WHEN movistar_2g_corrected IS FALSE THEN 'SETTLEMENT GREENFIELD' END AS node_type,
S.latitude,
S.longitude,
S.geom
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_coverage} C
ON S.settlement_id = C.settlement_id
WHERE movistar_3g_corrected IS TRUE AND movistar_4g_corrected IS FALSE);
