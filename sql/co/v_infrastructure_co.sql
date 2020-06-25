CREATE OR REPLACE VIEW  {schema}.v_infrastructure
AS 
SELECT
i.tower_id,
latitude,
longitude,
tower_height,
owner,
location_detail,
tower_type,
tech_2g,
tech_3g,
tech_4g,
type,
subtype,
in_service,
vendor,
coverage_area_2g,
coverage_area_3g,
coverage_area_4g,
fiber,
radio,
satellite,
satellite_band_in_use,
radio_distance_km,
last_mile_bandwidth,
source_file,
source,
internal_id,
c.centroid as closest_cluster,
ST_Intersects(geom::geometry,c.convexhull) as in_cluster,
st_distance(geom::geography,c.geom_centroid::geography) as distance_to_centroid,
geom
FROM {schema}.infrastructure_global i
LEFT JOIN (select DISTINCT ON (tower_id) 
                tower_id, centroid
                from {schema}.infrastructure_global i left join {schema}.clusters_links c
                on st_dwithin(i.geom::geography,c.geom_centroid::geography, 150000)
                where c.centroid is not null
                order by tower_id, st_distance(i.geom::geography,c.geom_centroid::geography)) a
ON a.tower_id=i.tower_id
left join (SELECT centroid, ST_ConvexHull(ST_Collect(geom_node::geometry)) as convexhull, geom_centroid
from {schema}.clusters_links group by centroid, geom_centroid) c
on a.centroid=c.centroid
 ORDER BY i.tower_id
 
 