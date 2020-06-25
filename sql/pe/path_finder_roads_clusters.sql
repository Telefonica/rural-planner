DROP TABLE IF EXISTS {schema}.{auxiliary_table};
CREATE TABLE {schema}.{auxiliary_table} AS
SELECT
centroid,
cluster_weight,
geom AS geom_centroid
FROM {schema}.{table_clusters}
            
UNION

SELECT 
tower_id::text,
0 AS cluster_weight,
geom AS geom_centroid
FROM {schema}.{table_towers}
WHERE tower_id::text NOT IN (
    SELECT centroid
    FROM {schema}.{table_clusters}
);
CREATE INDEX {auxiliary_table}_gix ON {schema}.{auxiliary_table} USING GIST(geom_centroid);