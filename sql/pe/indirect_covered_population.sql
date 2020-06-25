CREATE TABLE IF NOT EXISTS {schema}.indirect_covered_population (
                        tower_id int,
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
                        tower_height float,
                        latitude float,
                        longitude float);
TRUNCATE TABLE {schema}.indirect_covered_population;
INSERT INTO {schema}.indirect_covered_population
SELECT A.tower_id,
        CASE WHEN A.settlement_ids_addition IS NULL THEN A.settlement_ids
             WHEN A.settlement_ids IS NULL THEN A.settlement_ids_addition
             ELSE CONCAT(A.settlement_ids,', ',A.settlement_ids_addition) END AS settlement_ids,
        CASE WHEN A.settlement_names_addition IS NULL THEN A.settlement_names
             WHEN A.settlement_names IS NULL THEN A.settlement_names_addition
             ELSE CONCAT(A.settlement_names,', ',A.settlement_names_addition) END AS settlement_names,
        A.covered_settlements,
        A.covered_population,
        CASE WHEN C.settlement_ids_distributed_addition IS NULL THEN C.settlement_ids_distributed
             WHEN C.settlement_ids_distributed IS NULL THEN C.settlement_ids_distributed_addition
             ELSE CONCAT(C.settlement_ids_distributed,', ',C.settlement_ids_distributed_addition) END AS settlement_ids_distributed,
        CASE WHEN C.settlement_names_distributed IS NULL THEN C.settlement_names_distributed_addition
             WHEN C.settlement_names_distributed_addition IS NULL THEN C.settlement_names_distributed
             ELSE CONCAT(C.settlement_names_distributed,', ',C.settlement_names_distributed_addition) END AS settlement_names_distributed,
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
        settlement_ids_addition,
        string_agg(s.settlement_name, ', ') AS settlement_names, 
        settlement_names_addition,
        COUNT(s.settlement_id)+ad_hoc_settlements_addition AS covered_settlements, 
        SUM(s.population_corrected)+ad_hoc_population_addition AS covered_population
        FROM {schema}.infrastructure_global i
        LEFT JOIN {schema}.settlements s
        ON ST_DWithin(s.geom, i.geom, 1000*i.tower_height/10)
        LEFT JOIN (
                SELECT a.access_tower_id, string_agg(a.settlement_id,', ') as settlement_ids_addition,  string_agg(a.settlement_name,', ') as settlement_names_addition, count(*) ad_hoc_settlements_addition, sum (a.population_corrected) as ad_hoc_population_addition
                FROM (
                SELECT t.settlement_id, s.settlement_name, s.population_corrected, t.access_tower_id 
                FROM {schema}.transport_by_settlement t
                LEFT JOIN {schema}.infrastructure_global i ON t.access_tower_id=i.tower_id
                LEFT JOIN {schema}.settlements s ON s.settlement_id=t.settlement_id
                LEFT JOIN {schema}.coverage c ON s.settlement_id=c.settlement_id
                WHERE distance_access_tower>GREATEST(i.tower_height*100,1500) and c.movistar_2g_corrected is true) a
                GROUP BY a.access_tower_id) D
        ON i.tower_id=D.access_tower_id
        GROUP BY i.tower_id, D.ad_hoc_settlements_addition, D.ad_hoc_population_addition, D.settlement_ids_addition, D.settlement_names_addition) A
LEFT JOIN (
        SELECT DISTINCT ON (s.tower_id)
                s.tower_id, 
                string_agg(s.settlement_id, ', ') AS settlement_ids_distributed,
                settlement_ids_distributed_addition, 
                string_agg(s.settlement_name, ', ') AS settlement_names_distributed, 
                settlement_names_distributed_addition,
                COUNT(s.settlement_id)+ad_hoc_settlements_addition AS covered_settlements_distributed, 
                SUM(s.population_corrected)+ad_hoc_population_addition AS covered_population_distributed 
                FROM (
                        SELECT 
                        DISTINCT ON (s.settlement_id) s.settlement_id, s.settlement_name, s.population_corrected, i.tower_id, ST_Distance(s.geom::geometry,i.geom::geometry)
                        FROM {schema}.infrastructure_global i, {schema}.settlements s
                                WHERE ST_Within(s.geom::geometry,i.coverage_area_2g) OR ST_Within(s.geom::geometry, i.coverage_area_3g) OR ST_Within(s.geom::geometry, i.coverage_area_4g)
                                ORDER BY s.settlement_id, ST_Distance(s.geom::geometry,i.geom::geometry)) s
                LEFT JOIN (
                        SELECT a.access_tower_id, string_agg(a.settlement_id,', ') as settlement_ids_distributed_addition,  string_agg(a.settlement_name,', ') as settlement_names_distributed_addition, count(*) ad_hoc_settlements_addition, sum (a.population_corrected) as ad_hoc_population_addition
                        FROM (
                        SELECT t.settlement_id, s.settlement_name, s.population_corrected, t.access_tower_id 
                        FROM {schema}.transport_by_settlement t
                        LEFT JOIN {schema}.infrastructure_global i ON t.access_tower_id=i.tower_id
                        LEFT JOIN {schema}.settlements s ON s.settlement_id=t.settlement_id
                        LEFT JOIN {schema}.coverage c ON s.settlement_id=c.settlement_id
                        WHERE distance_access_tower>GREATEST(i.tower_height*100,1500) and c.movistar_2g_corrected is true) a
                        GROUP BY a.access_tower_id) z
                ON s.tower_id=z.access_tower_id
                GROUP BY tower_id, ad_hoc_settlements_addition, ad_hoc_population_addition, settlement_ids_distributed_addition, settlement_names_distributed_addition) C
ON A.tower_id=C.tower_id
LEFT JOIN {schema}.infrastructure_global B
ON A.tower_id=B.tower_id
WHERE NOT EXISTS (SELECT * FROM {schema}.indirect_covered_population) ;