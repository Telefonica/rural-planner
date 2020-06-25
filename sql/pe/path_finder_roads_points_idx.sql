ALTER TABLE {schema}.{table_roads_points} ALTER geom_point TYPE geometry USING geom_point::geometry;

CREATE INDEX road_points_location_gix ON {schema}.{table_roads_points} USING GIST (geom_point);
CREATE INDEX road_points_ix ON {schema}.{table_roads_points} (stretch_id);
CREATE INDEX road_points_div_ix ON {schema}.{table_roads_points} (division);