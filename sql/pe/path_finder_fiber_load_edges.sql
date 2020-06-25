SELECT 
E.*,
ST_MakeLine(N1.geom::geometry, N2.geom::geometry) AS geom
FROM {schema}.{table_edges} E
LEFT JOIN {schema}.{table_nodes} N1
ON E.node_1 = N1.node_id
LEFT JOIN {schema}.{table_nodes} N2
ON E.node_2 = N2.node_id