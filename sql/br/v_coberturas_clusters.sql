CREATE OR REPLACE VIEW rural_planner.v_coberturas_clusters 
AS (
        SELECT 
                D.centroid,
                N.centroid_name,
                D.competitors_presence_2g,
                D.competitors_presence_3g,
                D.competitors_presence_4g,
                D.cluster_weight
        FROM (
                SELECT DISTINCT ON(C.centroid)
                       C.centroid,
                       CASE WHEN C.cluster_weight = 0 THEN 0
                            ELSE ROUND(ROUND(SUM(population_competitors_2g))::numeric/C.cluster_weight::numeric, 2) 
                         END AS competitors_presence_2g,
                       CASE WHEN C.cluster_weight = 0 THEN 0
                            ELSE ROUND(ROUND(SUM(population_competitors_3g))::numeric/C.cluster_weight::numeric, 2) 
                         END AS competitors_presence_3g,
                       CASE WHEN C.cluster_weight = 0 THEN 0
                            ELSE ROUND(ROUND(SUM(population_competitors_4g))::numeric/C.cluster_weight::numeric, 2) 
                         END AS competitors_presence_4g,
                       C.cluster_weight
                FROM (
                       SELECT centroid,
                              settlement_id,
                              cluster_weight,
                              CASE WHEN vivo_3g_corrected IS TRUE OR vivo_4g_corrected IS TRUE THEN 0
                                   WHEN competitors_2g_corrected IS TRUE THEN population_corrected::FLOAT 
                                   ELSE 0 
                                END AS population_competitors_2g,
                              CASE WHEN vivo_3g_corrected IS TRUE OR vivo_4g_corrected IS TRUE THEN 0
                                   WHEN competitors_3g_corrected IS TRUE THEN population_corrected::FLOAT 
                                   ELSE 0 
                                END AS population_competitors_3g,
                              CASE WHEN vivo_3g_corrected IS TRUE OR vivo_4g_corrected IS TRUE THEN 0
                                   WHEN competitors_4g_corrected IS TRUE THEN population_corrected::FLOAT 
                                   ELSE 0 
                                END AS population_competitors_4g
                        FROM (
                                SELECT DISTINCT ON (centroid, S.settlement_id)
                                        C.*,
                                        CV.*,
                                        S.population_corrected,
                                        T.access_tower_id
                                FROM (
                                        SELECT centroid,
                                               cluster_weight,
                                                CASE WHEN nodes = '' THEN NULL
                                                     ELSE TRIM(UNNEST(string_to_array(REPLACE(nodes,'''',''), ','))) 
                                                  END AS nodes
                                
                                        FROM rural_planner.clusters
                                
                                        UNION (SELECT centroid, 
                                                      cluster_weight, 
                                                      centroid AS nodes 
                                               FROM rural_planner.clusters) 
                                      ) C
                                LEFT JOIN rural_planner.coverage CV
                                     ON CV.settlement_id = C.nodes
                                LEFT JOIN rural_planner.settlements S
                                     ON S.settlement_id = C.nodes
                                LEFT JOIN rural_planner.transport_by_settlement T
                                     ON C.nodes=T.settlement_id
                                
                                WHERE C.nodes is not NULL
                        )B
                ) C
                
                GROUP BY C.centroid, C.cluster_weight
                 
             ) D
                 
        LEFT JOIN (
                    SELECT tower_id::text AS centroid_id,
                           --tower_name AS centroid_name
                           internal_id AS centroid_name
                    FROM rural_planner.infrastructure_global
                        
                    UNION
                        
                    SELECT settlement_id AS centroid_id,
                           settlement_id AS centroid_name
                    FROM rural_planner.settlements
                   ) N
        ON D.centroid = N.centroid_id )