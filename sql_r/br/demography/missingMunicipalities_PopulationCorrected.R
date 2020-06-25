
library(readxl)
library(RPostgreSQL)
library(rpostgis)
library(stringr)
library(XLConnect)
library(XLConnectJars)
library(foreign)
library(rgdal)
library(xlsx)


# AD-HOC: Add settlements from 5 missing municipalities using facebook polygons: ('4220000','1504752','5006275','4212650','4314548')

missingMunicipalities_PopulationCorrected <- function(schema, schema_dev, table, table_municipality, table_population, table_facebook_polygons, table_municipality_correction, municipality_pop){

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
  query <- paste0("CREATE INDEX ON ", schema, ".", table_facebook_polygons," USING GIST(geom)")
  dbGetQuery(con, query)
  
  query <- paste0("CREATE INDEX ON ", schema_dev, ".", table_municipality," USING GIST(geom)")
  dbGetQuery(con, query)
                   
  query <- paste0("
  INSERT INTO ", schema_dev,".", table," (
  SELECT settlement_id,
  settlement_id AS settlement_name,
  LEFT(settlement_id, 9) as admin_division_1_id,
  '' as admin_division_1_name,
  admin_division_2_id,
  admin_division_2_name,
  LEFT(settlement_id,2) as admin_division_3_id,
  S.admin_division_3_name,
  0 as population_census,
  ROUND(population) as population_corrected,
  ST_Y(geom) as latitude,
  ST_X(geom) as longitude,
  geom
  FROM (
  select CONCAT(m.cd_geocmu, LPAD((row_number() OVER (ORDER BY f.settlement_id))::text,8,'0')) as settlement_id,
   m.cd_geocmu as admin_division_2_id, 
   m.nm_municip as admin_division_2_name,
   ST_Centroid(ST_SetSRID(f.geom,4326)) as geom,
  f.population from ", schema, ".", table_facebook_polygons," f
  left join (SELECT * FROM ", schema_dev, ".", table_municipality," 
  where cd_geocmu IN ('4220000','1504752','5006275','4212650','4314548')) m
  on ST_Within(f.geom,m.geom)
  WHERE m.cd_geocmu IS NOT NULL) A
  LEFT JOIN (SELECT DISTINCT ON (admin_division_3_id) 
  admin_division_3_id, admin_division_3_name
  FROM ", schema_dev, ".", table,") S
  ON LEFT(A.settlement_id,2)= S.admin_division_3_id)")
  
  dbGetQuery(con, query)
  
  
  #AD-HOC: Add corrected population using fb polygons:
  
  dbWriteTable(con, c(schema_dev,table_municipality_correction), 
               value = data.frame(municipality_pop), row.names = F, append= T)
   
  query <- paste0("DROP TABLE IF EXISTS ", schema_dev,".",table_population)
  dbGetQuery(con,query)
  
  query <- paste0("create table ", schema_dev, ".", table_population, " as (
                      SELECT s.settlement_id,
                      s.geom,
                      b.settlement_id as polygon_id,
                      b.population,
                      b.geom as geom_polygon
                      FROM ",schema_dev, ".", table, " s
                      left join ",schema, ".", table_facebook_polygons, " b
                      ON ST_Within(s.geom::geometry,b.geom::geometry))")
  dbGetQuery(con,query)
  
  
  query <- paste0("update ",schema_dev, ".", table, " set population_corrected = b.population from (
                    select a.settlement_id, population from ", schema_dev, ".", table_population, " a
                        left join ",schema_dev, ".", table, " s
                        on a.settlement_id=s.settlement_id
                        where polygon_id is not null and 
                        s.population_census is null and a.settlement_id in
                        (SELECT settlement_id from ", schema_dev, ".", table_population, " where polygon_id is not null and polygon_id in 
                          ( select distinct(polygon_id)
                                FROM ", schema_dev, ".", table_population, " group by polygon_id having count(*)=1))
           union
                  select b.settlement_id, population_unassigned/settlements_no_pop as population
                        from (
                        select polygon_id, (population-SUM(case when population_census is null then 0 else population_census end)) as population_unassigned,
                        sum(case when population_census is null then 1 else 0 end) as settlements_no_pop
                        from ", schema_dev, ".", table_population, " a
                        left join ", schema_dev, ".", table, " s
                        on a.settlement_id=s.settlement_id
                        where polygon_id is not null
                        group by polygon_id, population
                        having sum(case when population_census is null then 1 else 0 end)>0 and (population-SUM(case when population_census is null then 0 else population_census end))>0) a
                        LEFT JOIN ", schema_dev, ".", table_population, " b
                        on b.polygon_id=a.polygon_id
                        left join ", schema_dev, ".", table, " s
                        on b.settlement_id=s.settlement_id
                        where s.population_census is null and b.settlement_id is not null) b
                        where b.settlement_id=", table, ".settlement_id
                        ")
  
  dbGetQuery(con,query)
  
  
  query <- paste("UPDATE ", schema_dev,".",table, " set population_corrected = population_census where population_corrected is null", sep = "")
  dbGetQuery(con,query)

  
  query <- paste("UPDATE ", schema_dev,".",table, " set population_corrected = 0 where population_corrected is null", sep = "")
  dbGetQuery(con,query)
  
  ## Correct with 2017 municipality projections
  
  query <- paste0(" update ", schema_dev, ".", table, " set population_corrected = population_corrected*z.norm_factor
                    FROM (SELECT m.population_corrected/s.population_corrected as norm_factor, m.admin_division_2_id
                    FROM (SELECT admin_division_2_id, sum(population_corrected) as population_corrected
                    FROM ", schema_dev, ".", table, "
                    group by admin_division_2_id) s
                    LEFT JOIN ", schema_dev, ".", table_municipality_correction," m
                    on s.admin_division_2_id=m.admin_division_2_id) z
                    WHERE z.admin_division_2_id=", table,".admin_division_2_id
                        ")
  
  dbGetQuery(con,query)
  
  dbDisconnect(con)
}