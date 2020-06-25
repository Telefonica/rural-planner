CREATE TABLE {schema}.{output_table} AS 
SELECT 
T.*,
T1.{tef_alias}_transport_id,
distance_{tef_alias}_transport_m,
line_of_sight_{tef_alias},
additional_height_tower_1_{tef_alias}_m,
additional_height_tower_2_{tef_alias}_m,
regional_transport_id,
distance_regional_transport_m,
line_of_sight_regional,
additional_height_tower_1_regional_m,
additional_height_tower_2_regional_m,
third_party_transport_id,
distance_third_party_transport_m,
line_of_sight_third_party,
additional_height_tower_1_third_party_m,
additional_height_tower_2_third_party_m
FROM {schema}.{temporary_table} T
LEFT JOIN {schema}.{transport_table} T1
ON T.intermediate_hop_id = T1.tower_id;

DROP TABLE {schema}.{temporary_table};