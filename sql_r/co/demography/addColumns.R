addColumns <- function(schema,table_admin_division_1, population_admin_division_1, table_households, table_admin_division_2, admin_division_1_wrong_capital){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd)
                     
    query <- paste("ALTER TABLE ",schema, ".", table_admin_division_1," ADD COLUMN population_cabecera numeric", sep="")
    dbGetQuery(con, query)
    
    query <- paste("ALTER TABLE ",schema, ".", table_admin_division_1," ADD COLUMN population_resto numeric", sep="")
    dbGetQuery(con, query)
    
    query <- paste("ALTER TABLE ",schema, ".", table_admin_division_1," ADD COLUMN households_cabecera numeric", sep="")
    dbGetQuery(con, query)
    
    query <- paste("ALTER TABLE ",schema, ".", table_admin_division_1," ADD COLUMN households_resto numeric", sep="")
    dbGetQuery(con, query)
    
    query <- paste("ALTER TABLE ",schema, ".", table_admin_division_1," ADD COLUMN population_resto_estimation numeric", sep="")
    dbGetQuery(con, query)
    
    query <- paste("ALTER TABLE ",schema, ".", table_admin_division_1," ADD COLUMN norm_factor numeric", sep="")
    dbGetQuery(con, query)
    
    for (i in (1:nrow(population_admin_division_1))){
      
      query <- paste("UPDATE ",schema, ".", table_admin_division_1," 
                 SET population_cabecera=", population_admin_division_1[i,'capital'], ",
                 population_resto = ",population_admin_division_1[i,'rest'],"
                 WHERE admin_division_1_id='",population_admin_division_1[i,'admin_division_1_id'],"'", sep="")
      
      dbGetQuery(con,query)
    }
    
    query <- paste("UPDATE ",schema, ".", table_admin_division_1," A SET households_cabecera= c.households_capital FROM (SELECT admin_division_1_id, COUNT(*) as households_capital FROM ",schema, ".", table_households," WHERE right(closest_settlement,3) = '000' GROUP BY admin_division_1_id) C WHERE A.admin_division_1_id= C.admin_division_1_id", sep="")
    
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ",schema, ".", table_admin_division_1," A SET households_resto= c.households_rest FROM (SELECT admin_division_1_id, COUNT(*) as households_rest FROM ",schema, ".", table_households," WHERE right(closest_settlement,3)!='000' or closest_settlement is null GROUP BY admin_division_1_id) C WHERE A.admin_division_1_id= C.admin_division_1_id", sep="")
    
    dbGetQuery(con,query)
    
    
    query <- paste("UPDATE ",schema, ".", table_admin_division_1," SET population_resto_estimation = households_resto::numeric*c.hab_house::numeric FROM 
      ",schema, ".", table_admin_division_2," c
      WHERE ",table_admin_division_1,".admin_division_2_id=c.admin_division_2_id AND admin_division_1_id NOT IN ('",paste(admin_division_1_wrong_capital,collapse="','"),"')", sep="")
    
    dbGetQuery(con,query)
    
    # We also take into account households in the capital in municipalities where the population is wrong
    query <- paste("UPDATE ",schema, ".", table_admin_division_1," SET population_resto_estimation = (households_resto+households_cabecera)*c.hab_house FROM 
      ",schema, ".", table_admin_division_2," c
      WHERE ",table_admin_division_1,".admin_division_2_id=c.admin_division_2_id AND
      population_cabecera = 0", sep="")
    
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ",schema, ".", table_admin_division_1," SET norm_factor= population_resto/population_resto_estimation", sep="")
    
    dbGetQuery(con,query)
    
  
  dbDisconnect(con)

}