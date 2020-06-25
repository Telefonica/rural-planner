SELECT A.* FROM 
{schema}.{table_path_finder_fiber} A
LEFT JOIN rural_planner.{table_towers} I
ON A.centroid=I.tower_id::text
LEFT JOIN {schema}.{table_initial_quick_wins} B
ON I.tower_id=B.centroid
LEFT JOIN ((SELECT centroid
FROM {schema}.{table_path_finder_radio} C
LEFT JOIN rural_planner.{table_towers} I2
ON C.fiber_node_movistar=I2.tower_id::text
WHERE hops_movistar<=1 AND in_service='IN SERVICE')) C
ON A.centroid = C.centroid
WHERE I.ipt_perimeter = 'IPT' AND B.centroid IS NULL
AND C.centroid IS NULL
