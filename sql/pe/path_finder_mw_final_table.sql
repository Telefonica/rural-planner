DROP TABLE {schema}.{final_table};
CREATE TABLE {schema}.{final_table} AS

SELECT 
O.node_id AS centroid,
I.tower_name AS site,
I.type,
C.cluster_weight AS direct_population,
O.length_movistar::integer AS hops_movistar,
O.length_azteca::integer AS hops_azteca,
O.length_regional::integer AS hops_regional,
O.length_third_party::integer AS hops_third_party,
P1.population_movistar,
P2.population_azteca,
P3.population_regional,
P4.population_third_party,
O.path_movistar,
O.fiber_node_movistar,
O.path_azteca,
O.fiber_node_azteca,
O.path_regional,
O.fiber_node_regional,
O.path_third_party,
O.fiber_node_third_party,
O.geom_movistar,
O.geom_azteca,
O.geom_regional,
O.geom_third_party
FROM {schema}.{output_table} O
LEFT JOIN {schema}.{table_towers} I
ON I.tower_id::text = O.node_id
LEFT JOIN {schema}.{table_clusters} C
ON C.centroid = O.node_id
LEFT JOIN (
        SELECT 
        P.node_id,
        SUM(C.cluster_weight) AS population_movistar
        FROM (
                SELECT DISTINCT
                node_id,
                TRIM(UNNEST(string_to_array(REPLACE(path_movistar,'''',''), ',')))  AS nodes_movistar
                FROM {schema}.{output_table}
        ) P
        JOIN {schema}.{table_clusters} C
        ON P.nodes_movistar = C.centroid
        GROUP BY P.node_id
) P1
ON P1.node_id = O.node_id
LEFT JOIN (
        SELECT 
        P.node_id,
        SUM(C.cluster_weight) AS population_azteca
        FROM (
                SELECT DISTINCT
                node_id,
                TRIM(UNNEST(string_to_array(REPLACE(path_azteca,'''',''), ',')))  AS nodes_azteca
                FROM {schema}.{output_table}
        ) P
        JOIN {schema}.{table_clusters} C
        ON P.nodes_azteca = C.centroid
        GROUP BY P.node_id
) P2
ON P2.node_id = O.node_id
LEFT JOIN (
        SELECT 
        P.node_id,
        SUM(C.cluster_weight) AS population_regional
        FROM (
                SELECT DISTINCT
                node_id,
                TRIM(UNNEST(string_to_array(REPLACE(path_regional,'''',''), ',')))  AS nodes_regional
                FROM {schema}.{output_table}
        ) P
        JOIN {schema}.{table_clusters} C
        ON P.nodes_regional = C.centroid
        GROUP BY P.node_id
) P3
ON P3.node_id = O.node_id
LEFT JOIN (
        SELECT 
        P.node_id,
        SUM(C.cluster_weight) AS population_third_party
        FROM (
                SELECT DISTINCT
                node_id,
                TRIM(UNNEST(string_to_array(REPLACE(path_third_party,'''',''), ',')))  AS nodes_third_party
                FROM {schema}.{output_table}
        ) P
        JOIN {schema}.{table_clusters} C
        ON P.nodes_third_party = C.centroid
        GROUP BY P.node_id
) P4
ON P4.node_id = O.node_id

