ALTER TABLE {schema}.{output_table}
ALTER COLUMN node_id TYPE int USING node_id::int;

UPDATE {schema}.{output_table} SET path_movistar = replace(path_movistar, '{{', '');
UPDATE {schema}.{output_table} SET path_movistar = replace(path_movistar, '}}', '');

UPDATE {schema}.{output_table} SET path_azteca = replace(path_azteca, '{{', '');
UPDATE {schema}.{output_table} SET path_azteca = replace(path_azteca, '}}', '');

UPDATE {schema}.{output_table} SET path_regional = replace(path_regional, '{{', '');
UPDATE {schema}.{output_table} SET path_regional = replace(path_regional, '}}', '');

UPDATE {schema}.{output_table} SET path_third_party = replace(path_third_party, '{{', '');
UPDATE {schema}.{output_table} SET path_third_party = replace(path_third_party, '}}', '');

ALTER TABLE {schema}.{output_table}
ADD COLUMN geom_movistar GEOMETRY;

ALTER TABLE {schema}.{output_table}
ADD COLUMN geom_azteca GEOMETRY;

ALTER TABLE {schema}.{output_table}
ADD COLUMN geom_regional GEOMETRY;

ALTER TABLE {schema}.{output_table}
ADD COLUMN geom_third_party GEOMETRY;

UPDATE {schema}.{output_table} SET geom_movistar = A.geom
FROM (SELECT X.node_id, ST_Union(X.geom) AS geom FROM (
    SELECT 
    O.*,
    N.geom::geometry
    FROM (
            SELECT
            node_id,
            TRIM(UNNEST(string_to_array(REPLACE(path_movistar,'''',''), ',')))  AS nodes_movistar
            FROM {schema}.{output_table}
    ) O
    LEFT JOIN {schema}.{table_nodes} N
    ON O.nodes_movistar = N.node_id::text
    WHERE geom IS NOT NULL) X
    GROUP BY node_id) A
WHERE A.node_id = {output_table}.node_id;
                 
UPDATE {schema}.{output_table} SET geom_azteca = B.geom
FROM (SELECT X.node_id, ST_Union(X.geom) AS geom FROM (
    SELECT 
    O.*,
    N.geom::geometry
    FROM (
            SELECT
            node_id,
            TRIM(UNNEST(string_to_array(REPLACE(path_azteca,'''',''), ',')))  AS nodes_azteca
            FROM {schema}.{output_table}
    ) O
    LEFT JOIN {schema}.{table_nodes} N
    ON O.nodes_azteca = N.node_id::text
    WHERE geom IS NOT NULL) X
    GROUP BY node_id) B
WHERE B.node_id = {output_table}.node_id;
                 
UPDATE {schema}.{output_table} SET geom_regional = C.geom
FROM (SELECT X.node_id, ST_Union(X.geom) AS geom FROM (
    SELECT 
    O.*,
    N.geom::geometry
    FROM (
            SELECT
            node_id,
            TRIM(UNNEST(string_to_array(REPLACE(path_regional,'''',''), ',')))  AS nodes_regional
            FROM {schema}.{output_table}
    ) O
    LEFT JOIN {schema}.{table_nodes} N
    ON O.nodes_regional = N.node_id::text
    WHERE geom IS NOT NULL) X
    GROUP BY node_id) C
WHERE C.node_id = {output_table}.node_id;
                 
UPDATE {schema}.{output_table} SET geom_third_party = D.geom
FROM (SELECT X.node_id, ST_Union(X.geom) AS geom FROM (
    SELECT 
    O.*,
    N.geom::geometry
    FROM (
            SELECT
            node_id,
            TRIM(UNNEST(string_to_array(REPLACE(path_third_party,'''',''), ',')))  AS nodes_third_party
            FROM {schema}.{output_table}
    ) O
    LEFT JOIN {schema}.{table_nodes} N
    ON O.nodes_third_party = N.node_id::text
    WHERE geom IS NOT NULL) X
    GROUP BY node_id) D
WHERE D.node_id = {output_table}.node_id;
        
UPDATE {schema}.{output_table} SET path_movistar = 'NULL' WHERE path_movistar IS NULL;
UPDATE {schema}.{output_table} SET path_azteca = 'NULL' WHERE path_azteca IS NULL;
UPDATE {schema}.{output_table} SET path_regional = 'NULL' WHERE path_regional IS NULL;
UPDATE {schema}.{output_table} SET path_third_party = 'NULL' WHERE path_third_party IS NULL;
        
INSERT INTO {schema}.{output_table}
    SELECT DISTINCT ON (n.node_id) n.node_id,
    NULL AS length_movistar,
    'NULL' AS path_movistar,
    NULL AS fiber_node_movistar,
    NULL AS length_azteca,
    'NULL' AS path_azteca,
    NULL AS fiber_node_azteca,
    NULL AS length_regional,
    'NULL' AS path_regional,
    NULL AS fiber_node_regional,
    NULL AS length_third_party,
    'NULL' AS path_third_party,
    NULL AS fiber_node_third_party,
    NULL AS geom_movistar,
    NULL AS geom_azteca,
    NULL AS geom_regional,
    NULL AS geom_third_party
    FROM {schema}.{table_nodes} n
    LEFT JOIN {schema}.{table_cluster_node_map} c
    ON n.node_id=c.node_id 
    LEFT JOIN {schema}.{table_clusters} c2
    ON c.centroid=c2.centroid
    LEFT JOIN {schema}.{table_towers} i
    ON i.tower_id::text=c2.centroid
    LEFT JOIN {schema}.{table_initial_quick_wins} p
    ON p.centroid=i.tower_id
    WHERE ipt_perimeter = 'IPT'
    AND p.centroid IS NULL
    AND node_id NOT IN (
            SELECT
            node_id
            FROM {schema}.{output_table}
    );

