createNodesConsolidation <- function(schema, table_output, table_bbb, table_poblatowns){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd) 
  
  # Drop bbbike nodes with unneccessary types
  query <- paste0("DELETE FROM ",schema,".", table_bbb,"
                 WHERE type IN ('port', 'region', 'state', 'square', 'country', 'island', 'islet')")
  dbGetQuery(con, query)
  
  # Then merge poblatowns with bbbike nodes using the same methodologhy as before to create the final df with all input nodes avoiding duplicates
  
  dropTable(schema, table_output)
  
  query <- paste0("CREATE TABLE ",schema,".", table_output," 
                 AS( SELECT A.name, A.type, A.latitude, A.longitude, A.geom, NULL::integer AS settlement_id
                     FROM ",schema,".", table_bbb," A
                     WHERE A.geom NOT IN ( SELECT B.geom
                                           FROM ",schema,".", table_poblatowns," A
                                           INNER JOIN ",schema,".", table_bbb," B
                                           ON A.nam = B.name
                                           AND ST_DWithin(B.geom, A.geom, 3000) 
                                           ORDER BY B.name, ST_Distance(A.geom, B.geom))
                     UNION
                     (SELECT A.nam, 'settlement' AS type, A.latitude, A.longitude, A.geom, NULL::integer AS settlement_id
                     FROM ",schema,".", table_poblatowns," A)
                 )")
  dbGetQuery(con, query)
  
  dbDisconnect(con)
}