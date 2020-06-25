DROP TABLE IF EXISTS {schema}.{table_nodes};
CREATE TABLE {schema}.{table_nodes} AS 
SELECT * FROM {schema}.{table_nodes_original};

CREATE INDEX ON {schema}.{table_nodes} USING GIST (geom);
CREATE INDEX ON {schema}.{table_nodes} (node_id);