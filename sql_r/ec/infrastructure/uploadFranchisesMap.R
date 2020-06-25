uploadFranchisesMap <- function(schema_dev, table_franchises_map, franchises_map, table_cluster_franchise, table_infrastructure,
                        table_cantones, table_settlements){
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, dbname = dbname,
                   host = host, port = port,
                   user = user, password = pwd)
  
  query <- paste("DROP TABLE IF EXISTS ", schema_dev, ".", table_franchises_map, sep="")
  dbGetQuery(con, query)
  
  dbWriteTable(con, c(schema_dev, table_franchises_map), franchises_map, row.names=FALSE)
  
  query <- paste0("create table ",schema_dev,".",table_cluster_franchise," as (
                    SELECT i.tower_id::text as centroid, b.franchise 
                    FROM ",schema_dev,".", table_infrastructure," i
                    left join (
                    select t.*, s.geom
                        from ",schema_dev,".",table_franchises_map," t
                        left join ",schema_dev,".",table_cantones," s
                        on t.admin_division_1_name=s.\"DPA_DESCAN\") b
                    on ST_Within(i.geom::geometry,b.geom)
                    UNION
                    SELECT i.settlement_id as centroid, b.franchise 
                    FROM ",schema_dev,".", table_settlements, " i
                    left join ",schema_dev,".",table_franchises_map," b
                    on i.admin_division_2_name=b.admin_division_1_name)")
  dbGetQuery(con,query)
  
  query <- paste0("UPDATE ",schema_dev,".",table_cluster_franchise," SET franchise='TELEFONICA' WHERE franchise IS NULL")
  dbGetQuery(con, query)
  
  dbDisconnect(con)
}