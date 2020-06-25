DROP TABLE {schema}.{table_cluster_node_map};

CREATE TABLE {schema}.{table_cluster_node_map} AS
SELECT 
B.centroid,
B.node_id,
N.geom AS geom_node,
B.geom_centroid,
ST_MakeLine(N.geom::geometry, B.geom_centroid::geometry) AS geom_line
FROM (
    SELECT DISTINCT
    A.centroid,
    node_update AS node_id,
    C.geom_centroid
    FROM (
            SELECT 
            centroid,
            N1.stretch_id,
            N1.division,
            N2.node_id,
            N3.node_1,
            N3.node_2,
            CASE WHEN node_1 IS NULL THEN node_id
            ELSE node_1 END AS node_update
            FROM {schema}.{table_nodes_roads} N1
            LEFT JOIN {schema}.{table_nodes_roads}_unaltered N2
            ON (N1.stretch_id = N2.stretch_id AND ABS(N1.division - N2.division) < 0.0001)
            LEFT JOIN {schema}.{table_node_replacement_map} N3
            ON N2.node_id = N3.node_2
            WHERE centroid <> 'BORDER'

    ) A
    LEFT JOIN {schema}.{auxiliary_table} C
    ON C.centroid = A.centroid

) B
LEFT JOIN {schema}.{table_nodes_roads} N
ON B.node_id = N.node_id;

DROP TABLE {schema}.{table_nodes_roads}_unaltered;