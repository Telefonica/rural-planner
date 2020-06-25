DROP TABLE {schema}.{table_roads_linestring};
CREATE TABLE {schema}.{table_roads_linestring} AS
SELECT
row_number() OVER (ORDER BY  (ST_Dump(geom)).geom) AS stretch_id,
road_id,
hct_lbl as road_type,
geom,
(ST_Dump(geom)).geom AS geom_dump,
ST_Length((ST_Dump(geom)).geom::GEOGRAPHY) AS stretch_length
FROM {schema}.{table_roads};

DROP TABLE {schema}.{table_roads};