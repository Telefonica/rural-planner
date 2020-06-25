createSettlements <- function(schema_dev, table_settlements, table_households_pop, table_all, table_parroquias, table_projections){
  
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
  query <- paste0('CREATE TABLE ', schema_dev, '.', table_settlements,' AS (
                  SELECT settlement_id,
                  settlement_name,
                  c.admin_division_1_id,
                  admin_division_1_name,
                  admin_division_2_id,
                  admin_division_2_name,
                  admin_division_3_id,
                  admin_division_3_name,
                  ROUND(sum(c.population)) as population_census,
                  ROUND(sum(c.population)*b.norm_factor) as population_corrected,
                  ST_Y(geom::geometry) as latitude,
                  ST_X(geom::geometry) as longitude,
                  c.geom
                  FROM (SELECT distinct on (manzana_id)
                  a.parroquia_id,
                  a.population,
                  b.*
                  FROM ', schema_dev, '.', table_households_pop, ' a
                  LEFT JOIN (SELECT CONCAT(b.dpa_parroq,'-',row_number() OVER (ORDER BY b.dpa_parroq, a.id)) as settlement_id,
                  name as settlement_name,
                  dpa_parroq as admin_division_1_id,
                  dpa_despar as admin_division_1_name,
                  dpa_canton as admin_division_2_id,
                  dpa_descan as admin_division_2_name,
                  dpa_provin as admin_division_3_id,
                  dpa_despro as admin_division_3_name,
                  a.geom
                  FROM ', schema_dev, '.', table_all, ' a
                  LEFT JOIN ', schema_dev, '.', table_parroquias, ' b
                  ON ST_Within(a.geom::geometry,b.geom)) b
                  on a.parroquia_id=b.admin_division_1_id AND ST_DWithin(a.geom::geometry, b.geom::geometry, 3000)
                  ORDER BY manzana_id, st_distance(a.geom::geometry, b.geom::geometry) asc) c
                  left join (SELECT a.canton_id, sum(a.population) as population, b.pop_2019/sum(a.population) as norm_factor
                  from ', schema_dev, '.ec_census_households_shp a
                  left join ', schema_dev, '.', table_projections, ' b
                  on a.canton_id=b.admin_division_1_id
                  group by a.canton_id, b.admin_division_1_id, b.pop_2019) b
                  on c.admin_division_2_id=b.canton_id
                  WHERE settlement_id IS NOT NULL
                  GROUP BY settlement_id,settlement_name,c.admin_division_1_id,admin_division_1_name,admin_division_2_id,admin_division_2_name,admin_division_3_id,admin_division_3_name, geom, norm_factor
                  HAVING sum(c.population)>0
                  )')
  dbGetQuery(con,query)
  
  dbDisconnect(con)
  
}