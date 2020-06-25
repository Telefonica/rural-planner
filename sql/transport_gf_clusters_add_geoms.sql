CREATE TABLE {schema}.{temporary_table} AS 
SELECT
A.*,
ST_MakeLine(geom_centroid::GEOMETRY, geom_{tef_alias}::GEOMETRY) AS geom_line_{tef_alias},
ST_MakeLine(geom_centroid::GEOMETRY, geom_regional::GEOMETRY) AS geom_line_regional,
ST_MakeLine(geom_centroid::GEOMETRY, geom_third_party::GEOMETRY) AS geom_line_third_party
FROM (
SELECT 
T.*,
T1.geom_centroid,
T2.geom AS geom_{tef_alias},
T3.geom AS geom_regional,
T4.geom AS geom_third_party
FROM {schema}.{output_table} T
LEFT JOIN {schema}.{table_clusters} T1
ON T.centroid = T1.centroid
LEFT JOIN {schema}.{infrastructure_table} T2
ON T.{tef_alias}_transport_id = T2.tower_id
LEFT JOIN {schema}.{infrastructure_table} T3
ON T.regional_transport_id = T3.tower_id
LEFT JOIN {schema}.{infrastructure_table} T4
ON T.third_party_transport_id = T4.tower_id
) A;

DROP TABLE {schema}.{output_table};
CREATE TABLE {schema}.{output_table} AS SELECT * FROM {schema}.{temporary_table} ORDER BY centroid;
DROP TABLE {schema}.{temporary_table};
