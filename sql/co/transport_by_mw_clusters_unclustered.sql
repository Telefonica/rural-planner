INSERT INTO {schema}.{temporary_table} 
SELECT
C.centroid,
'' AS nodes,
C.cluster_weight,
1 AS cluster_size
FROM {schema}.{table_clusters} C
WHERE C.cluster_weight>0 AND C.centroid NOT IN (
        SELECT
            BTRIM(UNNEST(string_to_array(nodes,' ,')),'''') AS node
            FROM {schema}.{temporary_table}
        UNION
        SELECT
            centroid
            FROM {schema}.{temporary_table}
    )