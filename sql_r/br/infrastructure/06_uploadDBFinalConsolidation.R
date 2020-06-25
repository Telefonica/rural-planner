uploadDBFinalConsolidation <- function(schema, table_global, infra_all, atoll_table_all){
  
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    
    #Upload old towers, add ID as integer and add geom field and change the coverage areas types to geom
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_global, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, c(schema, table_global), value = data.frame(infra_all), row.names = T, replace = T)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " RENAME \"row.names\" TO tower_id", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN geom TYPE GEOMETRY USING geom::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN coverage_area_2g TYPE GEOMETRY USING ST_Transform(coverage_area_2g,3857)", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN coverage_area_3g TYPE GEOMETRY USING coverage_area_3g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_global, " ALTER COLUMN coverage_area_4g TYPE GEOMETRY USING coverage_area_4g::GEOMETRY", sep = "")
    dbGetQuery(con,query)
    
    ## AD-HOC: do not take into account the coverage area that would give the infrastructure that is "PLANNED" (not "IN SERVICE")
    # 
    # query <- paste("UPDATE ", schema, ".", table_global, " SET coverage_area_2g = NULL WHERE in_service <> 'IN SERVICE'", sep = "")
    # dbGetQuery(con,query)
    # 
    # query <- paste("UPDATE ", schema, ".", table_global, " SET coverage_area_3g = NULL WHERE in_service <> 'IN SERVICE'", sep = "")
    # dbGetQuery(con,query)
    # 
    # query <- paste("UPDATE ", schema, ".", table_global, " SET coverage_area_4g = NULL WHERE in_service <> 'IN SERVICE'", sep = "")
    # dbGetQuery(con,query)
    
    ## Alter SRID
    query <- paste0("ALTER TABLE ", schema, ".", table_global, "
                      ALTER COLUMN coverage_area_2g TYPE geometry(MULTIPOLYGON, 3857)
                        USING ST_SetSRID(st_multi(coverage_area_2g),3857);
                    
                    ALTER TABLE ", schema, ".", table_global, "
                      ALTER COLUMN coverage_area_3g TYPE geometry(MULTIPOLYGON, 3857)
                        USING ST_SetSRID(st_multi(coverage_area_3g),3857);
                    
                    ALTER TABLE ", schema, ".", table_global, "
                      ALTER COLUMN coverage_area_4g TYPE geometry(MULTIPOLYGON, 3857)
                        USING ST_SetSRID(st_multi(coverage_area_4g),3857);")
    
    
    query <- paste0(" UPDATE ", schema, ".", table_global, " set coverage_area_2g=ST_Multi(B.coverage_area_2g)
                      FROM ", schema,".", atoll_table_all, " B
                      WHERE source='VIVO' AND tech_2g IS TRUE AND B.internal_id=",table_global,".internal_id;
                      UPDATE ", schema, ".", table_global, " set coverage_area_3g=ST_Multi(B.coverage_area_3g)
                      FROM ",schema,".",atoll_table_all, " B
                      WHERE source='VIVO' AND tech_3g IS TRUE AND B.internal_id=", table_global, ".internal_id;
                      UPDATE ", schema, ".", table_global, " set coverage_area_4g=ST_Multi(B.coverage_area_4g)
                      FROM ", schema,".", atoll_table_all, " B
                      WHERE source='VIVO' AND tech_4g IS TRUE AND B.internal_id=", table_global, ".internal_id;
                      UPDATE ", schema, ".", table_global, " set coverage_area_4g=ST_Multi(B.coverage_area_3g)
                      FROM ", schema, ".", atoll_table_all, " B
                      WHERE source='VIVO' AND tech_4g IS TRUE AND ", table_global, ".coverage_area_4g IS NULL AND B.internal_id=", table_global, ".internal_id;
                      UPDATE ", schema, ".", table_global, " set coverage_area_4g=ST_Multi(B.coverage_area_2g)
                      FROM ",schema, ".", atoll_table_all," B
                      WHERE source='VIVO' AND tech_4g IS TRUE AND ", table_global, ".coverage_area_4g IS NULL AND B.internal_id=", table_global, ".internal_id;
                      UPDATE ", schema, ".", table_global, " set coverage_area_2g=ST_Multi(ST_Buffer(ST_Transform(geom,3857), (CASE WHEN tower_height>50 THEN 5000
                                                                                                              WHEN tower_height<15 THEN 1500
                                                                                                              ELSE tower_height*100 END)))
                      WHERE source='VIVO' AND tech_2g IS TRUE AND ", table_global, ".coverage_area_2g IS NULL;
                      UPDATE ", schema, ".", table_global, " set coverage_area_3g=ST_Buffer(geom::geography, (CASE WHEN tower_height>50 THEN 5000
                                                                                                              WHEN tower_height<15 THEN 1500
                                                                                                              ELSE tower_height*100 END))::geometry
                      WHERE source='VIVO' AND tech_3g IS TRUE AND ", table_global, ".coverage_area_3g IS NULL;
                      UPDATE ", schema, ".", table_global, " set coverage_area_4g=ST_Multi(ST_Buffer(ST_Transform(geom,3857), (CASE WHEN tower_height>50 THEN 5000
                                                                                                              WHEN tower_height<15 THEN 1500
                                                                                                              ELSE tower_height*100 END)))
                      WHERE source='VIVO' AND tech_4g IS TRUE AND ", table_global, ".coverage_area_4g IS NULL;
    ")
    
    dbGetQuery(con,query)
    
    query <- paste(" CREATE INDEX infra_ix ON ", schema, ".", table_global, "  USING GIST(geom)", sep = "")
    dbGetQuery(con,query)
    
    
    dbDisconnect(con)
}