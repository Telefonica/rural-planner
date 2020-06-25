
DROP TABLE IF EXISTS {schema}.{table_nodes_original};
CREATE TABLE {schema}.{table_nodes_original} AS


--3G Tower nodes: 
SELECT
I.tower_id::TEXT AS node_id,
0 AS node_weight,
CASE WHEN I.tech_3g IS TRUE AND (A.fiber IS TRUE OR B.fiber IS TRUE OR C.fiber IS TRUE) THEN 'TOWER 3G FIBER'
     WHEN I.tech_3g IS TRUE AND (A.fiber IS TRUE OR B.fiber IS TRUE OR C.fiber IS TRUE) IS FALSE THEN 'TOWER 3G NOT FIBER'
     WHEN I.tech_2g IS TRUE AND (A.fiber IS TRUE OR B.fiber IS TRUE OR C.fiber IS TRUE) IS TRUE THEN 'TOWER 2G FIBER'
     WHEN I.tech_2g IS TRUE AND (A.radio IS TRUE OR B.radio IS TRUE OR C.radio IS TRUE) IS TRUE THEN 'TOWER 2G RADIO'
     ELSE 'TOWER' END AS node_type,
I.latitude,
I.longitude,
I.geom::GEOGRAPHY
FROM {schema}.{table_transport} T
LEFT JOIN {schema}.{table_infrastructure} I
ON I.tower_id = T.tower_id
LEFT JOIN {schema}.{table_infrastructure} A
ON A.tower_id = T.tasa_transport_id
LEFT JOIN {schema}.{table_infrastructure} B
ON B.tower_id = T.regional_transport_id
LEFT JOIN {schema}.{table_infrastructure} C
ON C.tower_id = T.third_party_transport_id
WHERE (T.tasa_transport_id IS NOT NULL OR T.regional_transport_id IS NOT NULL OR T.third_party_transport_id IS NOT NULL) and I.source NOT IN ('SILICA','ARSAT','GIGARED','EPEC_POINTS','FIBRA_PROV_SAN_LUIS_POINTS','HG_PISADA_SION_POINTS','SION_USHUAIA_POINTS','TELMEX_POINTS')
AND I.tech_4g IS FALSE AND I.tech_3g IS TRUE AND (I.tower_height>0 OR I.tower_height IS NOT NULL)
AND in_service IN ('IN SERVICE','AVAILABLE')

UNION

--Settlement nodes: they have the weight of their population if: they are uncovered (by 4G)

SELECT 
S.settlement_id AS node_id,
CASE WHEN (C.movistar_4g_corrected IS FALSE AND C.movistar_3g_corrected IS TRUE) THEN S.population_corrected::FLOAT
     ELSE 0 END AS node_weight,
CASE WHEN movistar_4g_corrected IS TRUE THEN 'SETTLEMENT 4G'
     WHEN movistar_3g_corrected IS TRUE THEN 'SETTLEMENT 3G' 
     WHEN movistar_2g_corrected IS TRUE THEN 'SETTLEMENT 2G' 
     ELSE 'SETTLEMENT GREENFIELD' END AS node_type,
S.latitude,
S.longitude,
S.geom::GEOGRAPHY
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_coverage} C
ON S.settlement_id = C.settlement_id
WHERE C.movistar_4g_corrected IS FALSE AND C.movistar_3g_corrected IS TRUE ;

CREATE INDEX node_location_gix ON {schema}.{table_nodes_original} USING GIST (geom);
CREATE INDEX node_id_ix ON {schema}.{table_nodes_original} (node_id);
