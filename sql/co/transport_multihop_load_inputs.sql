SELECT * FROM (
    SELECT S1.centroid,
    S1.latitude AS latitude_1,
    S1.longitude AS longitude_1,
    S1.tower_height as tower_height_1,
    S2.tower_id AS tower_id_2,
    S2.latitude AS latitude_2,
    S2.longitude AS longitude_2,
    S2.tower_height AS tower_height_2,
    S2.source AS owner_2,
    ST_Distance(S1.geom, ST_Transform(S2.geom,3857)) AS distance
    FROM (SELECT A.centroid,
    COALESCE(I.latitude, S.latitude) AS latitude,
    COALESCE(I.longitude, S.longitude) AS longitude,
    COALESCE(I.tower_height, 50) AS tower_height,
    ST_Transform(COALESCE(I.geom, S.geom),3857) AS geom
    FROM (SELECT * FROM {schema}.{table_clusters}) A
    LEFT JOIN {schema}.{table} i
    ON A.centroid=i.tower_id::text
    LEFT JOIN {schema}.{table_settlements} s
    ON A.centroid=s.settlement_id
    LEFT JOIN (SELECT tower_id::TEXT as centroid,                
                    {tef_alias}_transport_id,
                    distance_{tef_alias}_transport_m,
                    line_of_sight_{tef_alias},
                    additional_height_tower_1_{tef_alias}_m,
                    additional_height_tower_2_{tef_alias}_m,
                    backhaul_{tef_alias},
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
                    geom_{tef_alias},
                    geom_regional,
                    geom_third_party,
                    geom_line_{tef_alias},
                    geom_line_regional,
                    geom_line_third_party
                    FROM {schema}.{table_transport}
                    UNION                
                    SELECT * FROM {schema}.{table_transport_clusters}) T
    ON T.centroid=A.centroid
    WHERE (T.line_of_sight_{tef_alias} IS FALSE AND T.line_of_sight_regional IS FALSE AND T.line_of_sight_third_party IS FALSE)
    AND (T.distance_{tef_alias}_transport_m>{fiber_radius} AND T.distance_regional_transport_m>{fiber_radius} 
    AND T.distance_third_party_transport_m>{fiber_radius})
     OR (T.distance_{tef_alias}_transport_m IS NULL AND T.distance_regional_transport_m IS NULL AND T.distance_third_party_transport_m IS NULL)) S1
    LEFT JOIN (SELECT I.tower_id::text,
    I.latitude,
    I.longitude,
    I.tower_height,
    I.source ,
    I.geom
    FROM {schema}.{table} I
    LEFT JOIN {schema}.{table_transport} T
    on I.tower_id=T.tower_id
    WHERE source NOT LIKE '%%LINES%%' AND (T.line_of_sight_{tef_alias} IS TRUE OR T.line_of_sight_regional IS TRUE OR T.line_of_sight_third_party IS TRUE)
    AND tower_height>0
) S2
ON ST_DWithin(S1.geom,ST_Transform(S2.geom,3857), {mw_radius})) B
ORDER BY centroid, distance DESC--, line_of_sight_{tef_alias} DESC, line_of_sight_regional DESC, line_of_sight_third_party DESC