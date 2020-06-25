CREATE MATERIALIZED VIEW {schema}.v_coberturas_clusters_all
AS (
        SELECT 
                D.centroid,
                N.centroid_name,
                D.vivo_presence_2g,
                D.vivo_presence_3g,
                D.vivo_presence_4g,
                D.competitors_presence_2g,
                D.competitors_presence_3g,
                D.competitors_presence_4g
        FROM (
                SELECT DISTINCT ON(C.centroid)
                       C.centroid,
                       CASE WHEN SUM(C.population_corrected) = 0 THEN 0
                            ELSE ROUND(ROUND(SUM(population_vivo_2g))::numeric/SUM(C.population_corrected)::numeric, 2) 
                         END AS vivo_presence_2g,
                       CASE WHEN SUM(C.population_corrected) = 0 THEN 0
                            ELSE ROUND(ROUND(SUM(population_vivo_3g))::numeric/SUM(C.population_corrected)::numeric, 2) 
                         END AS vivo_presence_3g,
                       CASE WHEN SUM(C.population_corrected) = 0 THEN 0
                            ELSE ROUND(ROUND(SUM(population_vivo_4g))::numeric/SUM(C.population_corrected)::numeric, 2) 
                         END AS vivo_presence_4g,
                       CASE WHEN SUM(C.population_corrected) = 0 THEN 0
                            ELSE ROUND(ROUND(SUM(population_competitors_2g))::numeric/SUM(C.population_corrected)::numeric, 2) 
                         END AS competitors_presence_2g,
                       CASE WHEN SUM(C.population_corrected) = 0 THEN 0
                            ELSE ROUND(ROUND(SUM(population_competitors_3g))::numeric/SUM(C.population_corrected)::numeric, 2) 
                         END AS competitors_presence_3g,
                       CASE WHEN SUM(C.population_corrected) = 0 THEN 0
                            ELSE ROUND(ROUND(SUM(population_competitors_4g))::numeric/SUM(C.population_corrected)::numeric, 2) 
                         END AS competitors_presence_4g
                FROM (
                       SELECT centroid,
                              settlement_id,
                              population_corrected,
                              CASE WHEN vivo_2g_corrected IS TRUE THEN population_corrected::FLOAT 
                                   ELSE 0 
                                END AS population_vivo_2g,
                              CASE WHEN vivo_3g_corrected IS TRUE THEN population_corrected::FLOAT 
                                   ELSE 0 
                                END AS population_vivo_3g,
                              CASE WHEN vivo_4g_corrected IS TRUE THEN population_corrected::FLOAT 
                                   ELSE 0 
                                END AS population_vivo_4g,
                              CASE WHEN vivo_4g_corrected IS TRUE THEN 0
                                   WHEN competitors_2g_corrected IS TRUE THEN population_corrected::FLOAT 
                                   ELSE 0 
                                END AS population_competitors_2g,
                              CASE WHEN vivo_4g_corrected IS TRUE THEN 0
                                   WHEN competitors_3g_corrected IS TRUE THEN population_corrected::FLOAT 
                                   ELSE 0 
                                END AS population_competitors_3g,
                              CASE WHEN vivo_4g_corrected IS TRUE THEN 0
                                   WHEN competitors_4g_corrected IS TRUE THEN population_corrected::FLOAT 
                                   ELSE 0 
                                END AS population_competitors_4g
                        FROM (
                                SELECT DISTINCT ON (centroid, S.settlement_id)
                                        C.*,
                                        CV.*,
                                        S.population_corrected
                                FROM (
                                        SELECT centroid,
                                               cluster_weight,
                                                CASE WHEN nodes = '' THEN NULL
                                                     ELSE TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) 
                                                  END AS nodes
                                
                                        FROM {schema}.clusters_north
                                
                                        UNION (SELECT centroid, 
                                                      cluster_weight, 
                                                      centroid AS nodes 
                                               FROM {schema}.clusters_north) 
                                       UNION
                                       
                                        SELECT centroid,
                                               cluster_weight,
                                                CASE WHEN nodes = '' THEN NULL
                                                     ELSE TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) 
                                                  END AS nodes
                                
                                        FROM {schema}.clusters_north_3g
                                
                                        UNION (SELECT centroid, 
                                                      cluster_weight, 
                                                      centroid AS nodes 
                                               FROM {schema}.clusters_north_3g) 
                                      ) C
                                LEFT JOIN (SELECT * FROM {schema}.coverage) CV
                                     ON CV.settlement_id = C.nodes
                                LEFT JOIN (SELECT * FROM {schema}.settlements) S
                                     ON S.settlement_id = C.nodes
                                
                                WHERE C.nodes is not NULL
                        )B
                ) C
                
                GROUP BY C.centroid
                 
             ) D
                 
        LEFT JOIN (
                    SELECT tower_id::text AS centroid_id,
                           --tower_name AS centroid_name
                           internal_id AS centroid_name
                    FROM {schema}.infrastructure_global
                        
                    UNION
                     
                    SELECT settlement_id AS centroid_id,
                           settlement_id AS centroid_name
                    FROM {schema}.settlements
                   ) N
        ON D.centroid = N.centroid_id )