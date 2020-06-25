
CREATE TABLE IF NOT EXISTS {schema}.indirect_covered_population_bc (
                tower_id integer,
                settlement_ids text,
                settlement_names text,
                covered_settlements bigint,
                covered_population bigint,
                settlement_ids_distributed text,
                settlement_names_distributed text, 
                covered_settlements_distributed bigint,
                covered_population_distributed bigint, 
                internal_id text, 
                tower_name text,
                tower_height double,
                latitude double,
                longitude double);
                
INSERT INTO {schema}.indirect_covered_population_bc
SELECT A.*,
        C.settlement_ids_distributed,
        C.settlement_names_distributed,
        C.covered_settlements_distributed,
        C.covered_population_distributed,
        B.internal_id,
        B.tower_name,
        B.tower_height,
        B.latitude,
        B.longitude
FROM (
        SELECT  
        i.tower_id, 
        string_agg(s.settlement_id, ', ') AS settlement_ids, 
        string_agg(s.settlement_name, ',') AS settlement_names, 
        COUNT(s.settlement_id) AS covered_settlements, 
        SUM(s.population_corrected) AS covered_population
        FROM (SELECT tower_id, geom,
                CASE WHEN type='MACRO' then 2*tower_height
                ELSE tower_height END AS tower_height FROM {schema}.infrastructure_global where ipt_perimeter='IPT') i
        LEFT JOIN {schema}.settlements s
        ON ST_DWithin(s.geom, i.geom, 1000*i.tower_height/10)
        GROUP BY i.tower_id) A
LEFT JOIN (
SELECT  DISTINCT ON (s.tower_id)
        s.tower_id, 
        string_agg(s.settlement_id, ', ') AS settlement_ids_distributed, 
        string_agg(s.settlement_name, ',') AS settlement_names_distributed, 
        COUNT(s.settlement_id) AS covered_settlements_distributed, 
        SUM(s.population_corrected) AS covered_population_distributed 
        FROM (
                SELECT 
                DISTINCT ON (s.settlement_id) s.settlement_id, s.settlement_name, s.population_corrected, i.tower_id, ST_Distance(s.geom::geometry,i.geom::geometry)
        FROM (SELECT tower_id, geom,
                CASE WHEN type='MACRO' then 2*tower_height
                ELSE tower_height END AS tower_height FROM {schema}.infrastructure_global where ipt_perimeter='IPT') i,
                {schema}.settlements s
                WHERE ST_DWithin(s.geom,i.geom,1000*i.tower_height/10)
                ORDER BY s.settlement_id, ST_Distance(s.geom::geometry,i.geom::geometry)) s
        GROUP BY s.tower_id) C
ON A.tower_id=C.tower_id
LEFT JOIN {schema}.infrastructure_global B
ON A.tower_id=B.tower_id
WHERE NOT EXISTS (SELECT * FROM {schema}.indirect_covered_population_bc) 