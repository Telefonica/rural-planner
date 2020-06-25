DROP TABLE {schema}.{final_table};
CREATE TABLE {schema}.{final_table} AS
SELECT
A.centroid,
O.node_id,
I.tower_name AS site,
I.type,
A.cluster_weight AS direct_population,
A.distance AS distance_to_road,
O.length_movistar AS length_fiber_movistar,
O.length_azteca AS length_fiber_azteca,
O.length_regional AS length_fiber_regional,
O.length_third_party AS length_fiber_third_party,
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
A.geom_line AS geom_microwave,
O.geom_movistar,
O.geom_azteca,
O.geom_regional,
O.geom_third_party
FROM (
SELECT 
C.centroid,
CN.node_id,
C.cluster_weight,
ST_MakeLine(CN.geom_centroid::geometry, CN.geom_node::geometry) AS geom_line,
ST_Distance(CN.geom_centroid::geography, CN.geom_node::geography) AS distance
FROM {schema}.{table_clusters} C
LEFT JOIN {schema}.{table_cluster_node_map} CN
ON C.centroid = CN.centroid
WHERE C.centroid IN (
        SELECT tower_id::text
        FROM {schema}.{table_towers}
        WHERE ipt_perimeter = 'IPT'
        AND tower_id NOT IN (
                        SELECT centroid
                        FROM {schema}.{table_initial_quick_wins}
        )
)
AND node_id IS NOT NULL
) A
LEFT JOIN {schema}.{output_table} O
ON A.node_id = O.node_id
LEFT JOIN {schema}.{table_towers} I
ON A.centroid = I.tower_id::text
LEFT JOIN (
        SELECT 
        O.node_id,
        SUM(N.cluster_weight) AS population_movistar
        FROM (
        SELECT DISTINCT
        node_id,
        TRIM(UNNEST(string_to_array(REPLACE(path_movistar,'''',''), ',')))  AS nodes_movistar
        FROM {schema}.{output_table}
        ) O
        LEFT JOIN {schema}.{table_nodes} N
        ON O.nodes_movistar = N.node_id::text
        GROUP BY O.node_id
) P1
ON O.node_id = P1.node_id
LEFT JOIN (
        SELECT 
        O.node_id,
        SUM(N.cluster_weight) AS population_azteca
        FROM (
        SELECT DISTINCT
        node_id,
        TRIM(UNNEST(string_to_array(REPLACE(path_azteca,'''',''), ',')))  AS nodes_azteca
        FROM {schema}.{output_table}
        ) O
        LEFT JOIN {schema}.{table_nodes} N
        ON O.nodes_azteca = N.node_id::text
        GROUP BY O.node_id
) P2
ON O.node_id = P2.node_id
LEFT JOIN (
        SELECT 
        O.node_id,
        SUM(N.cluster_weight) AS population_regional
        FROM (
        SELECT DISTINCT
        node_id,
        TRIM(UNNEST(string_to_array(REPLACE(path_regional,'''',''), ',')))  AS nodes_regional
        FROM {schema}.{output_table}
        ) O
        LEFT JOIN {schema}.{table_nodes} N
        ON O.nodes_regional = N.node_id::text
        GROUP BY O.node_id
) P3
ON O.node_id = P3.node_id
LEFT JOIN (
        SELECT 
        O.node_id,
        SUM(N.cluster_weight) AS population_third_party
        FROM (
        SELECT DISTINCT
        node_id,
        TRIM(UNNEST(string_to_array(REPLACE(path_third_party,'''',''), ',')))  AS nodes_third_party
        FROM {schema}.{output_table}
        ) O
        LEFT JOIN {schema}.{table_nodes} N
        ON O.nodes_third_party = N.node_id::text
        GROUP BY O.node_id
) P4
ON O.node_id = P4.node_id


UNION

--Nodes not projected to a road because they are too far
SELECT 
C.centroid,
NULL AS node_id,
I.tower_name AS site,
I.type,
C.cluster_weight AS direct_population,
NULL AS distance_to_road,
NULL AS length_fiber_movistar,
NULL AS length_fiber_azteca,
NULL AS length_fiber_regional,
NULL AS length_fiber_third_party,
NULL AS population_movistar,
NULL AS population_azteca,
NULL AS population_regional,
NULL AS population_third_party,
'NULL' AS path_movistar,
NULL AS fiber_node_movistar,
'NULL' AS path_azteca,
NULL AS fiber_node_azteca,
'NULL' AS path_regional,
NULL AS fiber_node_regional,
'NULL' AS path_third_party,
NULL AS fiber_node_third_party,
NULL AS geom_microwave,
NULL AS geom_movistar,
NULL AS geom_azteca,
NULL AS geom_regional,
NULL AS geom_third_party
FROM {schema}.{table_clusters} C
LEFT JOIN {schema}.{table_towers} I
ON C.centroid = I.tower_id::text
WHERE centroid NOT IN (
SELECT centroid
FROM {schema}.{table_cluster_node_map}
)
AND centroid IN (
        SELECT tower_id::text
        FROM {schema}.{table_towers}
        WHERE ipt_perimeter = 'IPT'
        AND tower_id NOT IN (
                        SELECT centroid
                        FROM {schema}.{table_initial_quick_wins}
        )
)

