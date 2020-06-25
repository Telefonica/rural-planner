DROP TABLE IF EXISTS {schema}.{table_nodes};
CREATE TABLE {schema}.{table_nodes} AS (
SELECT c.centroid as node_id,
        t.{tef_alias}_transport_id as tower_id_2,
        distance_{tef_alias}_transport_m as distance,
        line_of_sight_{tef_alias},
        additional_height_tower_1_{tef_alias}_m,
        additional_height_tower_2_{tef_alias}_m
       FROM {schema}.{clusters_table} c
       LEFT JOIN (SELECT tower_id::TEXT as centroid,
                           {tef_alias}_transport_id,
                            distance_{tef_alias}_transport_m,
                            line_of_sight_{tef_alias},
                            additional_height_tower_1_{tef_alias}_m,
                            additional_height_tower_2_{tef_alias}_m 
                            FROM {schema}.{transport_table}
                            UNION
                  SELECT centroid,
                           {tef_alias}_transport_id,
                            distance_{tef_alias}_transport_m,
                            line_of_sight_{tef_alias},
                            additional_height_tower_1_{tef_alias}_m,
                            additional_height_tower_2_{tef_alias}_m 
                            FROM {schema}.{transport_gf_cl_table}
                           ) t
           ON c.centroid=t.centroid           
        LEFT JOIN {schema}.{infrastructure_table} i
        on i.tower_id=t.{tef_alias}_transport_id
           WHERE c.cluster_weight>0 AND
           -- remove quick wins
          NOT ((t.line_of_sight_{tef_alias} IS TRUE OR line_of_sight_{tef_alias} IS FALSE AND distance_{tef_alias}_transport_m<={fiber_radius}) 
AND i.fiber IS TRUE)
);