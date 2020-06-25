 CREATE TABLE IF NOT EXISTS {schema}.competitors_presence_towers (
                        tower_id int,
                        claro_2g_presence float,
                        claro_3g_presence float,
                        claro_4g_presence float,
                        cnt_2g_presence float,
                        cnt_3g_presence float,
                        cnt_4g_presence float,
                        competitors_2g_presence float,
                        competitors_3g_presence float,
                        competitors_4g_presence float,
                        settlement_ids_distributed text,
                        settlement_names_distributed text,
                        covered_settlements_distributed bigint,
                        covered_population_distributed bigint,
                        internal_id text,
                        tower_name text,
                        tower_height float,
                        latitude float,
                        longitude float);
                        
TRUNCATE TABLE {schema}.competitors_presence_towers;
INSERT INTO {schema}.competitors_presence_towers
SELECT 
D.*,
i.settlement_ids_distributed,
i.settlement_names_distributed,
i.covered_settlements_distributed,
i.covered_population_distributed,
i.internal_id,
i.tower_name,
i.tower_height,
i.latitude,
i.longitude
FROM  {schema}.indirect_covered_population i
LEFT JOIN (
SELECT DISTINCT ON(C.tower_id)
C.tower_id,
CASE WHEN SUM(population_corrected) = 0 THEN 0
ELSE SUM(population_cnt_2g)::numeric/SUM(population_corrected)::numeric END AS cnt_presence_2g,
CASE WHEN SUM(population_corrected) = 0 THEN 0
ELSE SUM(population_cnt_3g)::numeric/SUM(population_corrected)::numeric END AS cnt_presence_3g,
CASE WHEN SUM(population_corrected) = 0 THEN 0
ELSE SUM(population_cnt_4g)::numeric/SUM(population_corrected)::numeric END AS cnt_presence_4g,

CASE WHEN SUM(population_corrected) = 0 THEN 0
ELSE SUM(population_claro_2g)::numeric/SUM(population_corrected)::numeric END AS claro_presence_2g,
CASE WHEN SUM(population_corrected) = 0 THEN 0
ELSE SUM(population_claro_3g)::numeric/SUM(population_corrected)::numeric END AS claro_presence_3g,
CASE WHEN SUM(population_corrected) = 0 THEN 0
ELSE SUM(population_claro_4g)::numeric/SUM(population_corrected)::numeric END AS claro_presence_4g,

CASE WHEN SUM(population_corrected) = 0 THEN 0
ELSE SUM(population_competitors_2g)::numeric/SUM(population_corrected)::numeric END AS competitors_presence_2g,
CASE WHEN SUM(population_corrected) = 0 THEN 0
ELSE SUM(population_competitors_3g)::numeric/SUM(population_corrected)::numeric END AS competitors_presence_3g,
CASE WHEN SUM(population_corrected) = 0 THEN 0
ELSE SUM(population_competitors_4g)::numeric/SUM(population_corrected)::numeric END AS competitors_presence_4g

FROM (
        SELECT 
        tower_id,
        settlement_id,
        population_corrected,
        CASE WHEN cnt_2g_corrected IS TRUE THEN population_corrected ELSE 0 END AS population_cnt_2g,
        CASE WHEN cnt_3g_corrected IS TRUE THEN population_corrected ELSE 0 END AS population_cnt_3g,
        CASE WHEN cnt_4g_corrected IS TRUE THEN population_corrected ELSE 0 END AS population_cnt_4g,
        
        CASE WHEN claro_2g_corrected IS TRUE THEN population_corrected ELSE 0 END AS population_claro_2g,
        CASE WHEN claro_3g_corrected IS TRUE THEN population_corrected ELSE 0 END AS population_claro_3g,
        CASE WHEN claro_4g_corrected IS TRUE THEN population_corrected ELSE 0 END AS population_claro_4g,       
        
        CASE WHEN competitors_2g_corrected IS TRUE THEN population_corrected ELSE 0 END AS population_competitors_2g,
        CASE WHEN competitors_3g_corrected IS TRUE THEN population_corrected ELSE 0 END AS population_competitors_3g,
        CASE WHEN competitors_4g_corrected IS TRUE THEN population_corrected ELSE 0 END AS population_competitors_4g
        FROM (
                SELECT DISTINCT ON (tower_id, nodes)
                C.*,
                CV.*,
                S.population_corrected
                FROM (
                SELECT
                tower_id, 
                CASE WHEN settlement_ids_distributed IS NULL THEN NULL
                     ELSE TRIM(UNNEST(string_to_array(settlement_ids_distributed, ', '))) END AS nodes
                FROM {schema}.indirect_covered_population 
                ) C
                LEFT JOIN {schema}.coverage CV
                ON CV.settlement_id = C.nodes
                LEFT JOIN {schema}.settlements S
                ON S.settlement_id = C.nodes
        )B
) C
GROUP BY C.tower_id
) D
ON i.tower_id=D.tower_id
WHERE NOT EXISTS (SELECT * FROM {schema}.competitors_presence_towers) ;
 
