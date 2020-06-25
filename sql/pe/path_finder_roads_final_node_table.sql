DROP TABLE IF EXISTS {schema}.{table_nodes_roads}_temp;
CREATE TABLE {schema}.{table_nodes_roads}_temp AS 

SELECT
row_number() OVER (ORDER BY stretch_id, division) AS node_id,
stretch_id,
division,
score,
SUM(cluster_weight) AS cluster_weight,
SUM(node_weight) AS node_weight,
stretch_length,
geom
FROM {schema}.{table_nodes_roads}
GROUP BY stretch_id, division, score, stretch_length, geom
ORDER BY stretch_id, division;


DROP TABLE IF EXISTS {schema}.{table_nodes_roads};

CREATE TABLE {schema}.{table_nodes_roads} AS 
SELECT * FROM {schema}.{table_nodes_roads}_temp;

DROP TABLE IF EXISTS {schema}.{table_nodes_roads}_unaltered;

CREATE TABLE {schema}.{table_nodes_roads}_unaltered AS 
SELECT * FROM {schema}.{table_nodes_roads};