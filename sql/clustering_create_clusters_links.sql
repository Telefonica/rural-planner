DROP TABLE IF EXISTS {schema}.{output_table}_links CASCADE; 
CREATE TABLE {schema}.{output_table}_links AS
SELECT
A.centroid,
A.node_2_id,
A.cluster_weight,
A.cluster_size,
N1.geom AS geom_centroid,
N2.geom AS geom_node,
ST_MakeLine(N1.geom::GEOMETRY, N2.geom::GEOMETRY) AS geom_line
FROM (
        SELECT
        C.centroid,
        TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) AS node_2_id,
        C.nodes,
        C.cluster_weight,
        C.cluster_size
        FROM {schema}.{output_table} C
) A
LEFT JOIN {schema}.{table_nodes_original} N1
ON N1.node_id = A.centroid
LEFT JOIN {schema}.{table_nodes_original} N2
ON N2.node_id = A.node_2_id

UNION

SELECT
O.centroid,
'' AS node_2_id,
O.cluster_weight,
O.cluster_size,
N1.geom AS geom_centroid,
N1.geom AS geom_node,
ST_MakeLine(N1.geom::GEOMETRY, N1.geom::GEOMETRY) AS geom_line
FROM {schema}.{output_table} O
LEFT JOIN {schema}.{table_nodes_original} N1
ON N1.node_id = O.centroid;


CREATE INDEX ON {schema}.{output_table}_links USING GIST (geom_centroid);