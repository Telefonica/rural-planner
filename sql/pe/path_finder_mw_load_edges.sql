SELECT 
L.*,
ST_MakeLine(I1.geom::geometry, I2.geom::geometry) AS geom
FROM rural_planner.{table_line_of_sight} L
LEFT JOIN rural_planner.{table_towers} I1
ON L.tower_id_1 = I1.tower_id
LEFT JOIN rural_planner.{table_towers} I2
ON L.tower_id_2 = I2.tower_id
WHERE line_of_sight IS TRUE
AND error_flag IS FALSE
ORDER BY tower_id_1, distance