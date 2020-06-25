processSettlementsDB <- function(schema, table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    #Add geometry
    
    query <- paste0("ALTER TABLE ", schema,".",table, " ADD COLUMN geom geography")
    dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", schema,".",table, " SET geom = ST_SetSRID(ST_MakePoint(longitude::numeric, latitude::numeric),4326)")
    dbGetQuery(con,query)
    
    #Change wrongly transcribed letters; in this case, ? transcribed as ?
    # 
    # query<-"UPDATE rural_planner.settlements
    # SET admin_div_2 = REPLACE(admin_div_2,'?','?')
    # WHERE admin_div_2 LIKE '%?%';
    # 
    # UPDATE rural_planner.settlements
    # SET admin_div_1 = REPLACE(admin_div_1,'?','?')
    # WHERE admin_div_1 LIKE '%?%';
    # 
    # UPDATE rural_planner.settlements
    # SET settlement = REPLACE(settlement,'?','?')
    # WHERE settlement LIKE '%?%';"
    # dbGetQuery(con,query)
    
    #Parse to desired format
    
    query <- paste0("ALTER TABLE ", schema,".",table, "
    ALTER COLUMN settlement_id TYPE varchar")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema,".",table, "
    ALTER COLUMN settlement_name TYPE varchar")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema,".",table, "
    ALTER COLUMN admin_division_1_name TYPE varchar")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema,".",table, "
    ALTER COLUMN admin_division_1_id TYPE varchar")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema,".",table, "
    ALTER COLUMN admin_division_2_name TYPE varchar")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema,".",table, "
    ALTER COLUMN admin_division_2_id TYPE varchar")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema,".",table, "
    ALTER COLUMN admin_division_3_name TYPE varchar")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema,".",table, "
    ALTER COLUMN admin_division_3_id TYPE varchar")
    dbGetQuery(con,query)
    
    query <- paste0("ALTER TABLE ", schema,".",table, "
    ALTER COLUMN population_corrected TYPE int4")
    dbGetQuery(con,query)
    
    query <- paste0("DELETE FROM ", schema,".",table, "
    WHERE latitude IS NULL OR longitude IS NULL")
    dbGetQuery(con,query)
    
    query <- paste0("CREATE INDEX settlement_id_ix ON ", schema, ".", table, " (settlement_id)")
    dbGetQuery(con,query)
    
    
    dbDisconnect(con)

}