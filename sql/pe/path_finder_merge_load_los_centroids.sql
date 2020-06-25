SELECT 
*
FROM {schema}.{table_cluster_node_map_los} M
WHERE centroid IN (
    SELECT tower_id::text
    FROM rural_planner.{table_towers}
    WHERE ipt_perimeter = 'IPT'
)