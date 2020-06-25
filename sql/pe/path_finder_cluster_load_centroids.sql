SELECT 
M.*,
T.tower_height,
ST_X(geom_node::geometry) AS longitude_road,
ST_Y(geom_node::geometry) AS latitude_road,
ST_X(geom_centroid::geometry) AS longitude_centroid,
ST_Y(geom_centroid::geometry) AS latitude_centroid,
J.orography
FROM {schema}.{table_cluster_node_map} M
LEFT JOIN (
    SELECT 
    tower_id::text AS centroid,
    CASE WHEN (tower_height IS NULL OR tower_height = 0) THEN 15
         ELSE tower_height END AS tower_height
    FROM {schema}.{table_towers} I

    UNION

    SELECT
    settlement_id AS centroid,
    30 AS tower_height
    FROM {schema}.{table_settlements} I
) T
ON M.centroid = T.centroid
LEFT JOIN {schema}.{table_jungle} J
ON M.centroid = J.centroid