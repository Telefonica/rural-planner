createPoblatowns <- function(schema, table_output, table_pob, table_tow){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
  # Create a new df (table poblatowns) merging towns and poblados nodes, avoid repeating settlements matching by name and within 3km radius
  
  dropTable(schema, table_output)
  
  query <- paste0("CREATE TABLE ",schema,".", table_output," 
                 AS ( SELECT *
                      FROM ",schema,".", table_pob," A
                      WHERE A.geom NOT IN (SELECT B.geom
                                           FROM ",schema,".", table_tow," A
                                           INNER JOIN ",schema,".", table_pob," B
                                           ON A.nam = B.nam
                                           AND ST_DWithin(B.geom, A.geom, 3000) 
                                           ORDER BY B.nam, ST_Distance(A.geom, B.geom))
                      UNION
                            ( SELECT * FROM ",schema,".", table_tow," )
                 )")
  dbGetQuery(con, query)
  
  dbDisconnect(con)
}