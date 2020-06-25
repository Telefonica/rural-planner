
CREATE TABLE {schema_dev}.lines_tx_clusters as (
SELECT z.ran_centroid,
centroid_name,
admin_division_3_id,
admin_division_3_name,
admin_division_2_id,
admin_division_2_name,
ddd,
ran_weight,
ran_size,
tamano,
type,
centroid_type,
segment_ov_gf,
segmento,
internal_id,
tower_height,
latitude,
longitude,
a.intermediate_hop_id,
latitude_intermediate_hop,
longitude_intermediate_hop,
distance_intermediate_hop_m,
tower_height_intermediate_hop,
internal_id_intermediate_hop,
case when z.type like '2hops%' then a.tower_id_tx else z.tower_id_tx end,
case when z.type like '2hops%' then a.internal_id_tx else z.internal_id_tx end,
case when z.type like '2hops%' then a.latitude_tx else z.latitude_tx end,
case when z.type like '2hops%' then a.longitude_tx else z.longitude_tx end,
case when z.type like '2hops%' then a.tower_height_tx else z.tower_height_tx end,
case when z.type like '2hops%' then distance_tx
 else st_length(z.line_tx::geography) end as distance_tx,
 CASE WHEN z.type like '2hops%' then a.line_hop ELSE NULL end as line_hop,
 CASE WHEN z.type like '2hops%' then a.line_tx when z.type<>'satellite' then z.line_tx else null end as line_tx 
FROM (
select a.*, i.internal_id, 
case when (length(centroid)>=15 and left(centroid,2)='13' or centroid in (select tower_id::text from {schema_dev}.amazonas_towers)) then 60
 ELSE COALESCE(i.tower_height,50) end as tower_height,
 COALESCE(i.latitude,s.latitude) as latitude, 
 COALESCE(i.longitude,s.longitude) as longitude,
 coalesce(i.geom,s.geom) as geom_centroid,
CASE WHEN a.type='satellite' then null else i2.tower_id end as tower_id_tx, 
CASE WHEN a.type='satellite' then null else i2.internal_id end as internal_id_tx, 
CASE WHEN a.type='satellite' then null 
        when i2.tower_id::text in (select tower_id::text from {schema_dev}.amazonas_towers) then 60
        WHEN i2.source LIKE '%LINES%' OR a.segment_ov_gf ='GREENFIELD' THEN 50 
        ELSE i2.tower_height END as tower_height_tx, 
CASE WHEN a.type='satellite' then null WHEN i2.source LIKE '%LINES%' THEN ST_Y(ST_ClosestPoint(i2.geom,t.geom_tower)) ELSE i2.latitude end as latitude_tx, 
CASE WHEN a.type='satellite' then null WHEN i2.source LIKE '%LINES%' THEN ST_X(ST_ClosestPoint(i2.geom,t.geom_tower)) ELSE i2.longitude end as longitude_tx, 
 i2.radio, i2.fiber, 
 st_MakeLine(coalesce(i.geom,s.geom), st_setSRID(ST_makepoint((CASE WHEN a.type='satellite' then null WHEN i2.source LIKE '%LINES%' THEN ST_X(ST_ClosestPoint(i2.geom,COALESCE(i.geom,s.geom))) ELSE i2.longitude end),(CASE WHEN a.type='satellite' then null WHEN i2.source LIKE '%LINES%' THEN ST_Y(ST_ClosestPoint(i2.geom,COALESCE(i.geom,s.geom))) ELSE i2.latitude end)),4326)) as line_tx
from {schema_dev}.analisis_clusters_ednei_v2 a
left join (SELECT tower_id::TEXT as centroid,                
                movistar_transport_id,
                distance_movistar_transport_m,
                line_of_sight_movistar,
                additional_height_tower_1_movistar_m,
                additional_height_tower_2_movistar_m,
                backhaul_movistar,
                regional_transport_id,
                distance_regional_transport_m,
                line_of_sight_regional,
                additional_height_tower_1_regional_m,
                additional_height_tower_2_regional_m,
                backhaul_regional,
                third_party_transport_id,
                distance_third_party_transport_m,
                line_of_sight_third_party,
                additional_height_tower_1_third_party_m,
                additional_height_tower_2_third_party_m,
                backhaul_third_party,
                geom_tower,
                geom_movistar,
                geom_regional,
                geom_third_party,
                geom_line_movistar,
                geom_line_regional,
                geom_line_third_party FROM {schema_dev}.transport_by_tower_north
UNION                
SELECT * FROM {schema_dev}.transport_greenfield_clusters_north_3g
UNION                
SELECT * FROM {schema_dev}.transport_greenfield_clusters_north) t
on a.ran_centroid=t.centroid
left join {schema_dev}.infrastructure_global i
on a.ran_centroid=i.tower_id::text
left join {schema_dev}.settlements s
on a.ran_centroid=s.settlement_id
left join {schema_dev}.infrastructure_global i2
on (CASE WHEN line_of_sight_movistar IS TRUE OR distance_movistar_transport_m<=5000 THEN movistar_transport_id
WHEN line_of_sight_regional IS TRUE OR distance_regional_transport_m<=5000 THEN regional_transport_id
ELSE third_party_transport_id END) =i2.tower_id) z
left join (SELECT a.centroid,
a.intermediate_hop_id, ii.latitude as latitude_intermediate_hop, ii.longitude as longitude_intermediate_hop,
a.distance_intermediate_hop_m as distance_intermediate_hop_m, ii.tower_height as tower_height_intermediate_hop,
ii.internal_id as internal_id_intermediate_hop,
it.tower_id as tower_id_tx,
it.internal_id as internal_id_tx,
case when it.tower_id in (select tower_id from {schema_dev}.amazonas_towers) then 60
when  it.tower_height=0 then 50 else it.tower_height end as tower_height_tx,
case when it.latitude=0 then ST_Y(ST_ClosestPoint(it.geom,ii.geom))
else it.latitude end as latitude_tx, 
case when it.longitude=0 then ST_X(ST_ClosestPoint(it.geom,ii.geom))
else it.longitude end as longitude_tx, 
st_distance(ii.geom::geography,it.geom::geography)/1000 as distance_tx,
st_makeline(ST_Transform(c.geom,4326), ii.geom) as line_hop,
st_makeline(ii.geom, it.geom) as line_tx
FROM {schema_dev}.transport_clusters_multihop a
LEFT JOIN {schema_dev}.infrastructure_global ii
on ii.tower_id=a.intermediate_hop_id
LEFT JOIN {schema_dev}.infrastructure_global it
on it.tower_id=(CASE WHEN line_of_sight_movistar IS TRUE OR distance_movistar_transport_m<=5000 THEN movistar_transport_id
WHEN line_of_sight_regional IS TRUE OR distance_regional_transport_m<=5000 THEN regional_transport_id
ELSE third_party_transport_id END)
LEFT JOIN (SELECT * FROM {schema_dev}.clusters_north UNION SELECT * FROM {schema_dev}.clusters_north_3g) c
on a.centroid=c.centroid) a
on a.centroid=z.ran_centroid)