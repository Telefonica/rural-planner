CREATE TABLE {schema}.{output_table}_temp AS
SELECT *
FROM {schema}.{output_table};

DROP TABLE {schema}.{output_table};

CREATE TABLE {schema}.{output_table} AS
SELECT 
O.*,
N.geom AS geom_centroid
FROM {schema}.{output_table}_temp O
LEFT JOIN {schema}.{table_nodes_original} N
ON O.centroid = N.node_id;

DROP TABLE {schema}.{output_table}_temp;