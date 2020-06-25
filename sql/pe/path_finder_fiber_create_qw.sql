DROP TABLE {schema}.{table_initial_quick_wins};
CREATE TABLE {schema}.{table_initial_quick_wins} AS
SELECT 
centroid,
fiber_node,
distance AS distance_to_fiber,
fiber_owner,
'NEAR POP' AS type,
geom_centroid,
geom_fiber,
geom_line
FROM (
SELECT DISTINCT ON (I1.tower_id)
I1.tower_id AS centroid,
I2.tower_id AS fiber_node,
CASE WHEN I2.source NOT IN ('AZTECA', 'REGIONAL', 'GILAT', 'TORRES ANDINAS', 'EHAS') AND I2.fiber IS TRUE THEN 0
		  WHEN I2.source = 'AZTECA' THEN 1
		  WHEN I2.source IN ('REGIONAL') AND I2.in_service = 'IN SERVICE' THEN 2
		  WHEN I2.source NOT IN ('AZTECA', 'REGIONAL', 'GILAT', 'TORRES ANDINAS', 'EHAS') THEN 3
		  WHEN I2.source IN ('GILAT', 'TORRES ANDINAS', 'EHAS') AND I2.in_service = 'IN SERVICE' THEN 4
		  WHEN I2.source IN ('REGIONAL') AND I2.in_service <> 'IN SERVICE' THEN 5
		  WHEN I2.source IN ('GILAT', 'TORRES ANDINAS', 'EHAS') AND I2.in_service <> 'IN SERVICE' THEN 6 
		  ELSE 99 END AS priority,		  
ST_Distance(I1.geom::geography, I2.geom::geography) AS distance,
CASE WHEN I2.source NOT IN ('AZTECA', 'REGIONAL', 'GILAT', 'TORRES ANDINAS', 'EHAS') THEN 'MOVISTAR'
		  WHEN I2.source = 'AZTECA' THEN 'AZTECA'
		  WHEN I2.source IN ('REGIONAL') THEN 'REGIONAL' 
		  WHEN I2.source IN ('GILAT', 'TORRES ANDINAS', 'EHAS') THEN 'THIRD PARTY'
		  ELSE 'UNKNOWN' END AS fiber_owner,
I1.geom AS geom_centroid,
I2.geom AS geom_fiber,
ST_MakeLine(I1.geom::geometry, I2.geom::geometry) AS geom_line
FROM {schema}.{table_towers} I1
LEFT JOIN {schema}.{table_towers} I2
ON ST_DWithin(I1.geom::geography, I2.geom::geography, {radius}) AND I1.tower_id <> I2.tower_id
WHERE I1.ipt_perimeter = 'IPT'
AND I1.tech_3g IS FALSE
AND I1.tech_4g IS FALSE
AND I1.radio IS FALSE
AND I1.fiber IS FALSE
AND (I2.fiber IS TRUE
OR I2.radio IS TRUE
)
AND (I2.in_service = 'IN SERVICE' OR I2.source = 'FIBER PLANNED')
ORDER BY I1.tower_id, priority, distance
) A

UNION

SELECT 
tower_id AS centroid,
tower_id AS fiber_node,
0 AS distance,
'MOVISTAR' AS fiber_owner,
CASE WHEN tech_3g IS TRUE OR tech_4g IS TRUE THEN 'CONNECTED'
     ELSE 'PLUG AND PLAY' END AS type,
geom AS geom_centroid,
geom AS geom_fiber,
ST_MakeLine(geom::geometry, geom::geometry) AS geom_line
FROM {schema}.{table_towers}
WHERE ipt_perimeter = 'IPT'
AND (tech_3g IS TRUE
OR tech_4g IS TRUE
OR radio IS TRUE
OR fiber IS TRUE)