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
SUM(CASE WHEN i.settlement_id IS NULL THEN 0 ELSE 1 END) AS covered_settlements,
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
UNION
SELECT  i2.tower_id,i2.internal_id,
                i2.tower_name,
                i2.tower_height,
                i2.latitude,
                i2.longitude, i2.source, i2.type, s2.settlement_id, s2.settlement_name, s2.population_corrected
FROM (
select distinct poblado_id,codigo_unico from dat_2019.planta_celdas_rural) a
left join {schema}.infrastructure_global i2 
on a.codigo_unico = i2.internal_id
left join {schema}.settlements s2
on a.poblado_id=s2.settlement_id                                        
) i
left join (SELECT tower_id, string_agg(poblado_id,', ') as settlement_ids_distributed, 
 string_agg(settlement_name,', ') as settlement_names_distributed,
 count(*) AS covered_settlements_distributed,
 round(sum(population_corrected)) as covered_population_distributed
 FROM (
select distinct poblado_id,codigo_unico from dat_2019.planta_celdas_rural) a
left join {schema}.settlements s
on s.settlement_id=a.poblado_id
left join {schema}.infrastructure_global i
on i.internal_id=a.codigo_unico
group by tower_id
) d
on d.tower_id=i.tower_id
WHERE i.source NOT IN ('CLARO','TIGO','AZTECA') AND (i.type<>'FIJA' OR i.type is NULL)
AND NOT EXISTS (SELECT * FROM {schema}.indirect_covered_population)
group by i.tower_id,i.internal_id,i.tower_name,i.tower_height,i.latitude,i.longitude,settlement_ids_distributed, 
settlement_names_distributed,
covered_settlements_distributed,
covered_population_distributed ;