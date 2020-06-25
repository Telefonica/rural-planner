
CREATE INDEX ON {schema}.{table_infrastructure} USING GIST(coverage_area_2g);
CREATE INDEX ON {schema}.{table_infrastructure} USING GIST(coverage_area_3g);
CREATE INDEX ON {schema}.{table_infrastructure} USING GIST(coverage_area_4g);

DROP TABLE IF EXISTS {schema}.{table_nodes_original};
CREATE TABLE {schema}.{table_nodes_original} AS


--Tower nodes VIVO:
SELECT
I.tower_id::TEXT AS node_id,
0 AS node_weight,
CASE WHEN I.tech_2g IS TRUE AND I.fiber IS TRUE THEN CONCAT(I.source,' TOWER 2G FIBER')
     WHEN I.tech_2g IS TRUE AND I.radio IS TRUE THEN CONCAT(I.source,' TOWER 2G RADIO')
     WHEN I.tech_2g IS TRUE AND I.satellite IS TRUE THEN CONCAT(I.source,' TOWER 2G SATELLITE') 
     WHEN I.tech_2g IS TRUE AND (I1.fiber IS TRUE OR I2.fiber IS TRUE OR I3.fiber IS TRUE) THEN CONCAT(I.source,' TOWER 2G NEAR FIBER')
     WHEN I.tech_2g IS TRUE AND (I1.radio IS TRUE OR I2.radio IS TRUE OR I3.radio IS TRUE) THEN CONCAT(I.source,' TOWER 2G NEAR RADIO')
     WHEN I.tech_2g IS TRUE THEN CONCAT(I.source,' TOWER 2G OTHER TX')
     ELSE CONCAT(I.source,' TOWER', (CASE WHEN I.tech_2g IS TRUE THEN ' 2G' ELSE '' END))  END AS node_type,
I.latitude,
I.longitude,
ST_Transform(I.geom::geometry, 3857) as geom
FROM  {schema}.{table_infrastructure} I
LEFT JOIN {schema}.{table_transport} T
ON I.tower_id=T.tower_id
LEFT JOIN {schema}.{table_infrastructure} I1
ON I1.tower_id=T.movistar_transport_id
LEFT JOIN {schema}.{table_infrastructure} I2
ON I2.tower_id=T.regional_transport_id
LEFT JOIN {schema}.{table_infrastructure} I3
ON I3.tower_id=T.third_party_transport_id
WHERE I.tech_4g IS FALSE AND I.tech_3g is FALSE 
AND I.source='VIVO'
                                     
UNION

--Tower nodes TIM and 3rd PARTIES:
SELECT
I.tower_id::TEXT AS node_id,
0 AS node_weight,
CASE WHEN I.tech_2g IS TRUE AND I.fiber IS TRUE THEN CONCAT(I.source,' TOWER 2G FIBER')
     WHEN I.tech_2g IS TRUE AND I.radio IS TRUE THEN CONCAT(I.source,' TOWER 2G RADIO')
     WHEN I.tech_2g IS TRUE AND I.satellite IS TRUE THEN CONCAT(I.source,' TOWER 2G SATELLITE') 
     WHEN I.tech_2g IS TRUE AND (I1.fiber IS TRUE OR I2.fiber IS TRUE OR I3.fiber IS TRUE) THEN CONCAT(I.source,' TOWER 2G NEAR FIBER')
     WHEN I.tech_2g IS TRUE AND (I1.radio IS TRUE OR I2.radio IS TRUE OR I3.radio IS TRUE) THEN CONCAT(I.source,' TOWER 2G NEAR RADIO')
     WHEN I.tech_2g IS TRUE THEN CONCAT(I.source,' TOWER 2G OTHER TX')
     ELSE CONCAT(I.source,' TOWER')  END AS node_type,
I.latitude,
I.longitude,
ST_Transform(I.geom::geometry, 3857) as geom
FROM  {schema}.{table_infrastructure} I
LEFT JOIN {schema}.{table_transport} T
ON I.tower_id=T.tower_id
LEFT JOIN {schema}.{table_infrastructure} I1
ON I1.tower_id=T.movistar_transport_id
LEFT JOIN {schema}.{table_infrastructure} I2
ON I2.tower_id=T.regional_transport_id
LEFT JOIN {schema}.{table_infrastructure} I3
ON I3.tower_id=T.third_party_transport_id
WHERE I.tech_4g IS FALSE AND I.tech_3g is FALSE
AND I.source NOT LIKE '%%_LINES' AND I.source NOT LIKE '%%_POINTS'

UNION

--Settlement nodes:
SELECT 
S.settlement_id AS node_id,
CASE WHEN (C.vivo_3g_corrected IS FALSE AND C.vivo_4g_corrected IS FALSE) THEN S.population_corrected::FLOAT 
     ELSE 0 END AS node_weight,
CASE WHEN (C.vivo_4g_corrected IS TRUE) THEN 'SETTLEMENT 4G'
     WHEN (C.vivo_3g_corrected IS TRUE) THEN 'SETTLEMENT 3G'
     WHEN (C.vivo_2g_corrected IS TRUE) THEN 'SETTLEMENT 2G' 
     ELSE 'SETTLEMENT GREENFIELD' END AS node_type,
S.latitude,
S.longitude,
ST_Transform(S.geom::geometry, 3857) as geom
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_coverage} C
ON S.settlement_id = C.settlement_id
WHERE C.vivo_4g_corrected IS FALSE AND C.vivo_3g_corrected IS FALSE 
AND S.settlement_id NOT IN (SELECT settlement_id FROM {schema}.localidades_tim); -------------------

CREATE INDEX ON {schema}.{table_nodes_original} USING GIST( (geom) );
