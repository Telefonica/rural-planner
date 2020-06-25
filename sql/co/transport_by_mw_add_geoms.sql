DROP TABLE IF EXISTS {schema}.{final_output};
CREATE TABLE {schema}.{final_output} AS
SELECT
A.*,
C.geom_centroid,
ST_Union(C.geom_node::GEOMETRY) as geom_nodes,
ST_Union(C.geom_line::GEOMETRY) as geom_links
FROM {schema}.{temporary_table} A
LEFT JOIN (SELECT A.*, I.geom as geom_centroid, C.geom_centroid as geom_node, ST_MakeLine(I.geom::GEOMETRY, C.geom_centroid::GEOMETRY) AS geom_line
            FROM (
            SELECT centroid,
            BTRIM(UNNEST(string_to_array(nodes,' ,')),'''') AS node
            FROM {schema}.{temporary_table}) A
            LEFT JOIN {schema}.{table_infrastructure} I
            ON A.centroid=I.tower_id::TEXT
            LEFT JOIN {schema}.{table_clusters} C
            ON A.node=C.centroid
            ) C
ON C.centroid=A.centroid
GROUP BY A.centroid, A.nodes, A.cluster_weight, A.cluster_size, C.centroid, C.geom_centroid
;

DROP TABLE {schema}.{temporary_table};