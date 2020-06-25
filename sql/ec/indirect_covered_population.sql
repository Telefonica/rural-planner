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
SELECT i.tower_id, string_agg(i.settlement_id, ', ') as settlement_ids, string_agg(i.settlement_name, ', ') as settlement_names,
CASE WHEN count(i.*) IS NULL THEN 0 ELSE count(i.*) END AS covered_settlements,
 CASE WHEN sum(i.population_corrected) IS NULL THEN 0 ELSE sum(i.population_corrected) END as covered_population, settlement_ids_distributed, 
settlement_names_distributed,
covered_settlements_distributed,
covered_population_distributed, 
i.internal_id,
i.tower_name,
i.tower_height,
i.latitude,
i.longitude
FROM ( SELECT i.tower_id,i.internal_id,
                i.tower_name,
                i.tower_height,
                i.latitude,
                i.longitude, i.source, i.type, s.settlement_id, s.settlement_name, s.population_corrected
from {schema}.infrastructure_global i
left join {schema}.settlements s
on st_dwithin(s.geom::geography, i.geom::geography, (case when tower_height <15 or tower_height is null then 1500
                                                        when tower_height >50 then 5000 else tower_height*100 end))                                       
) i
left join (SELECT tower_id, string_agg(settlement_id, ', ') as settlement_ids_distributed, 
 string_agg(settlement_name, ', ') as settlement_names_distributed,
 CASE WHEN count(*) IS NULL THEN 0 ELSE count(*) END AS covered_settlements_distributed,
 CASE WHEN sum(population_corrected) IS NULL THEN 0 ELSE sum(population_corrected) END as covered_population_distributed FROM
(SELECT distinct on (settlement_id) tower_id, settlement_id, settlement_name, population_corrected
from {schema}.settlements s
left join {schema}.infrastructure_global i
on st_dwithin(s.geom::geography, i.geom::geography, (case when tower_height <15 or tower_height is null then 1500
                                                        when tower_height >50 then 5000 else tower_height*100 end))
order by settlement_id, st_distance(s.geom::geography, i.geom::geography)/greatest(i.tower_height,1)) a
group by tower_id
) d
on d.tower_id=i.tower_id
WHERE EXISTS (SELECT * FROM {schema}.indirect_covered_population)
group by i.tower_id,i.internal_id,i.tower_name,i.tower_height,i.latitude,i.longitude,settlement_ids_distributed, 
settlement_names_distributed,
covered_settlements_distributed,
covered_population_distributed ;
