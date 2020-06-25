DROP TABLE {schema}.{table_intersections};

-- Intermediate table
CREATE TABLE {schema}.{table_intersections} AS
SELECT
R1.*,
R2.stretch_id AS stretch_id_2,
R2.division AS division_2,
R2.stretch_length AS stretch_length_2,
ST_Distance(R1.geom_point::geography, R2.geom_point::geography) AS distance
FROM {schema}.{table_roads_points} R1
LEFT JOIN {schema}.{table_roads_points} R2
ON ST_DWithin(R1.geom_point::geography, R2.geom_point::geography, 700)
WHERE R1.division IN (0,1)
AND R1.stretch_id <> R2.stretch_id
ORDER BY R1.stretch_id, R1.division, distance ASC;


-- Final intersercion table: 2 different criteria to define an intersection:
--1) Intersection = closest point belonging to another road stretch
--2) Intersection =  all points within a very small radius (to account for multi-road intersections)
CREATE TABLE {schema}.{table_intersections}_temp AS
SELECT DISTINCT ON (stretch_id, division, stretch_id_2, division_2)
*
FROM (
SELECT
stretch_id,
division,
stretch_id_2,
division_2,
distance
FROM {schema}.{table_intersections}
WHERE distance <= 500
OR 
WHERE stretch_id::text||'+'||division::text
IN (
        SELECT DISTINCT
        stretch_id::text||'+'||division::text AS stretch_division,
        COUNT(1)
        FROM {schema}.{table_intersections}
        GROUP BY stretch_id::text||'+'||division::text
        HAVING COUNT(1) <= 2
)
) U;


DROP TABLE {schema}.{table_intersections};

CREATE TABLE {schema}.{table_intersections} AS
SELECT * FROM {schema}.{table_intersections}_temp;

DROP TABLE {schema}.{table_intersections}_temp;