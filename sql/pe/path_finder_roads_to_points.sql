SELECT 
    stretch_id,
    road_id,
    road_type,
    stretch_length,
    ST_Line_Interpolate_Point(geom_dump, {k}) AS geom_point,
    {k} AS division
    FROM {schema}.{table_roads}
    WHERE stretch_id = {id_iteration}
    AND stretch_length - {length_iteration} < 0.1