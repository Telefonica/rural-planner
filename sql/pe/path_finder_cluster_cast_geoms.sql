ALTER TABLE {schema}.{table_output}
ALTER COLUMN geom_node TYPE geometry USING geom_node::geometry;

ALTER TABLE {schema}.{table_output}
ALTER COLUMN geom_centroid TYPE geometry USING geom_centroid::geometry;

ALTER TABLE {schema}.{table_output}
ALTER COLUMN geom_line TYPE geometry USING geom_line::geometry;