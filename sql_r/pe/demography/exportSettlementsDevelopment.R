exportSettlementsDevelopment <- function(schema, table, table_settlements, settlements_development_data){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)  
    
    query <- paste0("DROP TABLE IF EXISTS ", schema, ".", table)
    dbGetQuery(con,query)
    dbWriteTable(con, c(schema,table), value = data.frame(settlements_development_data), row.names = F, append= F)
    
    #Parse to desired format
    
    query<- paste0("ALTER TABLE ", schema, ".", table, " 
    ALTER COLUMN settlement_id TYPE varchar")
    dbGetQuery(con,query)
    
    query<-paste0("ALTER TABLE ", schema, ".", table, " 
    ALTER COLUMN settlement_name TYPE varchar")
    dbGetQuery(con,query)
    
    query<-paste0("ALTER TABLE ", schema, ".", table, " 
    ALTER COLUMN admin_division_1_id TYPE varchar")
    dbGetQuery(con,query)
    
    query<-paste0("ALTER TABLE ", schema, ".", table, " 
    ALTER COLUMN orography TYPE varchar")
    dbGetQuery(con,query)
    
    query<-paste0("ALTER TABLE ", schema, ".", table, " 
    ALTER COLUMN category TYPE varchar")
    dbGetQuery(con,query)
    
    query<-paste0("ALTER TABLE ", schema, ".", table, " 
    ALTER COLUMN classification TYPE varchar")
    dbGetQuery(con,query)
    
    query<-paste0("ALTER TABLE ", schema, ".", table, " 
    ALTER COLUMN admin_division_3_name TYPE varchar")
    dbGetQuery(con,query)
    
    # Delete settlements not in general settlements table
    query<-paste0("DELETE FROM ", schema, ".", table, " 
    WHERE settlement_id NOT IN (SELECT settlement_id FROM ", schema, ".", table_settlements, ")")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}