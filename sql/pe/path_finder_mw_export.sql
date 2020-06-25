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
FROM (SELECT 
        node_id,
        ST_Union(geom) AS geom
        FROM (
                SELECT 
                Q1.*,
                Q2.node_id AS node_id_2,
                ST_MakeLine(Q1.movistar_geom, Q2.movistar_geom) AS geom
                FROM (
                        SELECT A.*, 
                        I.geom::geometry AS movistar_geom
                        FROM (
                                SELECT
                                row_number() OVER () AS row_id,
                                P.*
                                FROM (
                                        SELECT node_id, UNNEST(string_to_array(path_movistar, ',')) AS movistar_nodes,
                                        path_movistar
                                        FROM {schema}.{output_table}
                                ) P
                        )A
                        LEFT JOIN {schema}.{table_towers} I
                        ON A.movistar_nodes=I.tower_id::text
                        ORDER BY a.row_id
                ) Q1
                LEFT JOIN (
                        SELECT A.*, 
                        I.geom::geometry AS movistar_geom
                        FROM (
                                SELECT
                                row_number() OVER () AS row_id,
                                P.*
                                FROM (
                                        SELECT node_id, UNNEST(string_to_array(path_movistar, ',')) AS movistar_nodes,
                                        path_movistar
                                        FROM {schema}.{output_table}
                                ) P
                        )A
                        LEFT JOIN {schema}.{table_towers} I
                        ON A.movistar_nodes=I.tower_id::text
                        ORDER BY a.row_id
                ) Q2
                ON (Q1.row_id = Q2.row_id - 1 AND Q1.node_id = Q2.node_id)
                WHERE Q2.row_id IS NOT NULL
                ORDER BY Q1.row_id
        ) F
        GROUP BY node_id) A
WHERE A.node_id = {output_table}.node_id;
                 
UPDATE {schema}.{output_table} SET geom_azteca = B.geom
FROM (SELECT 
        node_id,
        ST_Union(geom) AS geom
        FROM (
                SELECT 
                Q1.*,
                Q2.node_id AS node_id_2,
                ST_MakeLine(Q1.azteca_geom, Q2.azteca_geom) AS geom
                FROM (
                        SELECT A.*, 
                        I.geom::geometry AS azteca_geom
                        FROM (
                                SELECT
                                row_number() OVER () AS row_id,
                                P.*
                                FROM (
                                        SELECT node_id, UNNEST(string_to_array(path_azteca, ',')) AS azteca_nodes,
                                        path_azteca
                                        FROM {schema}.{output_table}
                                ) P
                        )A
                        LEFT JOIN {schema}.{table_towers} I
                        ON A.azteca_nodes=I.tower_id::text
                        ORDER BY a.row_id
                ) Q1
                LEFT JOIN (
                        SELECT A.*, 
                        I.geom::geometry AS azteca_geom
                        FROM (
                                SELECT
                                row_number() OVER () AS row_id,
                                P.*
                                FROM (
                                        SELECT node_id, UNNEST(string_to_array(path_azteca, ',')) AS azteca_nodes,
                                        path_azteca
                                        FROM {schema}.{output_table}
                                ) P
                        )A
                        LEFT JOIN {schema}.{table_towers} I
                        ON A.azteca_nodes=I.tower_id::text
                        ORDER BY a.row_id
                ) Q2
                ON (Q1.row_id = Q2.row_id - 1 AND Q1.node_id = Q2.node_id)
                WHERE Q2.row_id IS NOT NULL
                ORDER BY Q1.row_id
        ) F
        GROUP BY node_id) B
WHERE B.node_id = {output_table}.node_id;
                 
UPDATE {schema}.{output_table} SET geom_regional = C.geom
FROM (SELECT 
        node_id,
        ST_Union(geom) AS geom
        FROM (
                SELECT 
                Q1.*,
                Q2.node_id AS node_id_2,
                ST_MakeLine(Q1.regional_geom, Q2.regional_geom) AS geom
                FROM (
                        SELECT A.*, 
                        I.geom::geometry AS regional_geom
                        FROM (
                                SELECT
                                row_number() OVER () AS row_id,
                                P.*
                                FROM (
                                        SELECT node_id, UNNEST(string_to_array(path_regional, ',')) AS regional_nodes,
                                        path_regional
                                        FROM {schema}.{output_table}
                                ) P
                        )A
                        LEFT JOIN {schema}.{table_towers} I
                        ON A.regional_nodes=I.tower_id::text
                        ORDER BY a.row_id
                ) Q1
                LEFT JOIN (
                        SELECT A.*, 
                        I.geom::geometry AS regional_geom
                        FROM (
                                SELECT
                                row_number() OVER () AS row_id,
                                P.*
                                FROM (
                                        SELECT node_id, UNNEST(string_to_array(path_regional, ',')) AS regional_nodes,
                                        path_regional
                                        FROM {schema}.{output_table}
                                ) P
                        )A
                        LEFT JOIN {schema}.{table_towers} I
                        ON A.regional_nodes=I.tower_id::text
                        ORDER BY a.row_id
                ) Q2
                ON (Q1.row_id = Q2.row_id - 1 AND Q1.node_id = Q2.node_id)
                WHERE Q2.row_id IS NOT NULL
                ORDER BY Q1.row_id
        ) F
        GROUP BY node_id) C
WHERE C.node_id = {output_table}.node_id;
                 
UPDATE {schema}.{output_table} SET geom_third_party = D.geom
FROM (SELECT 
        node_id,
        ST_Union(geom) AS geom
        FROM (
                SELECT 
                Q1.*,
                Q2.node_id AS node_id_2,
                ST_MakeLine(Q1.third_party_geom, Q2.third_party_geom) AS geom
                FROM (
                        SELECT A.*, 
                        I.geom::geometry AS third_party_geom
                        FROM (
                                SELECT
                                row_number() OVER () AS row_id,
                                P.*
                                FROM (
                                        SELECT node_id, UNNEST(string_to_array(path_third_party, ',')) AS third_party_nodes,
                                        path_third_party
                                        FROM {schema}.{output_table}
                                ) P
                        )A
                        LEFT JOIN {schema}.{table_towers} I
                        ON A.third_party_nodes=I.tower_id::text
                        ORDER BY a.row_id
                ) Q1
                LEFT JOIN (
                        SELECT A.*, 
                        I.geom::geometry AS third_party_geom
                        FROM (
                                SELECT
                                row_number() OVER () AS row_id,
                                P.*
                                FROM (
                                        SELECT node_id, UNNEST(string_to_array(path_third_party, ',')) AS third_party_nodes,
                                        path_third_party
                                        FROM {schema}.{output_table}
                                ) P
                        )A
                        LEFT JOIN {schema}.{table_towers} I
                        ON A.third_party_nodes=I.tower_id::text
                        ORDER BY a.row_id
                ) Q2
                ON (Q1.row_id = Q2.row_id - 1 AND Q1.node_id = Q2.node_id)
                WHERE Q2.row_id IS NOT NULL
                ORDER BY Q1.row_id
        ) F
        GROUP BY node_id) D
WHERE D.node_id = {output_table}.node_id;
        
UPDATE {schema}.{output_table} SET path_movistar = 'NULL' WHERE path_movistar IS NULL;
UPDATE {schema}.{output_table} SET path_azteca = 'NULL' WHERE path_azteca IS NULL;
UPDATE {schema}.{output_table} SET path_regional = 'NULL' WHERE path_regional IS NULL;
UPDATE {schema}.{output_table} SET path_third_party = 'NULL' WHERE path_third_party IS NULL;
        
INSERT INTO {schema}.{output_table}
SELECT 
tower_id,
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
FROM {schema}.{table_towers} I
WHERE tower_id NOT IN (
    SELECT
    node_id
    FROM {schema}.{output_table}   
)
AND ipt_perimeter = 'IPT'
AND tech_3g IS FALSE
AND tech_4g IS FALSE
AND radio IS FALSE
AND fiber IS FALSE;
