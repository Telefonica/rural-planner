facebookHouseholds <- function(schema,table_households,households, table_admin_division_2){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste("DROP TABLE IF EXISTS ", schema,".",table_households, sep = "")
    dbGetQuery(con,query)
    
    dbWriteTable(con, c(schema,table_households),value = data.frame(households), row.names = F, append = F)
    
    query <- paste("ALTER TABLE ", schema,".",table_households, " ADD COLUMN geom geography", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema, ".", table_households, " SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude),4326)", sep = "")
    dbGetQuery(con,query)
    
    
    #Create spatial index
    
    query <- paste("CREATE INDEX co_households_gix ON ", schema,".",table_households, " USING GIST (geom)", sep = "")
    dbGetQuery(con,query)
    
    # Clean and normalize Facebook households' data
    
    ## Add household_id
    
    query <-paste(" ALTER TABLE ",schema,".",table_households,
                  " ADD column household_id integer",sep = "")
                 
    dbGetQuery(con,query)
    
    query <-paste(" UPDATE ",schema,".",table_households,
                  " A SET household_id = C.id from (select *, row_number() over (order by geom) as id from ",
                  schema,".",table_households, " ) C WHERE A.latitude = C.latitude and A.longitude = C.longitude",sep = "")
    
    dbGetQuery(con,query)
    
    
    ## Administrative division 2 (DEPARTAMENTO)
    
    query <-paste(" ALTER TABLE ",schema,".",table_households,
                  " ADD column admin_division_2_id text",sep = "")
                 
    dbGetQuery(con,query)
    
    query <-paste(" UPDATE ",schema,".",table_households,
                  " SET admin_division_2_id=",table_admin_division_2, ".admin_division_2_id
                  FROM ", schema,".",table_admin_division_2, "
                  WHERE ST_Within(",table_households,".geom::geometry, ",table_admin_division_2,".geom)",sep = "")
                 
    dbGetQuery(con,query)
    
    ## Administrative division 1 (MUNICIPIO)
    
    query <-paste(" ALTER TABLE ",schema,".",table_households,
                  " ADD column admin_division_1_id text",sep = "")
                 
    dbGetQuery(con,query)
    dbDisconnect(con)

}