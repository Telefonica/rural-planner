DROP INDEX IF EXISTS {schema}.road_points_div_ix;
DROP INDEX IF EXISTS {schema}.road_points_ix;
DROP TABLE IF EXISTS {schema}.{table_cluster_points};

CREATE TABLE {schema}.{table_cluster_points} AS
SELECT DISTINCT ON (centroid)
*,
CASE WHEN distance <= 5000 AND hct_lbl IS NULL THEN 0
     WHEN distance <= 5000 AND hct_lbl = 'Red departamental' THEN 1
     WHEN distance > 5000 AND hct_lbl IS NULL THEN 2
     WHEN distance > 5000 AND hct_lbl = 'Red departamental' THEN 3 END AS score
FROM (  SELECT DISTINCT
        C.centroid,
        R.stretch_id,
        R.division,
        R.hct_lbl,
        R.geom_point AS geom_road_point,
        C.geom_centroid AS geom_centroid,
        ST_Distance(C.geom_centroid::geography, R.geom_point::geography) AS distance
        FROM {schema}.{table_roads_points} R
        JOIN {schema}.{auxiliary_table} C
        ON ST_DWithin(C.geom_centroid::geography, R.geom_point::geography, {radius})
) A
ORDER BY centroid, distance ASC;

CREATE INDEX road_points_div_ix ON {schema}.{table_roads_points} USING btree (division);
CREATE INDEX road_points_ix ON {schema}.{table_roads_points} USING btree (stretch_id);