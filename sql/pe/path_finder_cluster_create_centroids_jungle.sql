DROP TABLE IF EXISTS {schema}.{table_jungle};
CREATE TABLE {schema}.{table_jungle} AS 

SELECT 
centroid,
CASE WHEN centroid IN (

WITH x AS (
SELECT 
ST_Union(ST_Buffer(S.geom, 20000)::geometry) AS geom
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_settlements_kpis} K
ON S.settlement_id = K.settlement_id
WHERE K.orography = 'SELVA'
)
SELECT centroid
FROM {schema}.{table_clusters}
WHERE ST_Contains((SELECT geom::geometry FROM x), geom::geometry)

UNION 

SELECT 
tower_id::text
FROM {schema}.{table_towers}
WHERE tower_id::text NOT IN (SELECT centroid FROM {schema}.{table_clusters})
AND ST_Contains((SELECT geom::geometry FROM x), geom::geometry)

) THEN 'JUNGLE'
ELSE 'NOT JUNGLE' END AS orography
FROM (SELECT centroid FROM {schema}.{table_clusters} UNION SELECT tower_id::text FROM {schema}.{table_towers} WHERE tower_id::text NOT IN (SELECT centroid FROM {schema}.{table_clusters}) ) B
