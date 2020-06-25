createOldNewIdMapping <- function(schema, table_id_map, table_global, table_old){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd)
    
    query <- paste("DROP TABLE IF EXISTS ", schema, ".", table_id_map, sep = "")
    dbGetQuery(con,query)
    
    query <- paste0("CREATE TABLE ", schema, ".", table_id_map, " as (
                          SELECT a.tower_id as new_tower_id, b.tower_id as old_tower_id
                          FROM ", schema, ".", table_global, " a
                          LEFT JOIN ",schema,".",table_old, " b
                          ON (a.internal_id=b.internal_id and a.source=b.source)
                          WHERE a.source not in ('PIA','AZTECA', 'TORRES ANDINAS', 'FIBER PLANNED','IPT')
                          and b.source not in ('PIA','AZTECA', 'TORRES ANDINAS', 'FIBER PLANNED','IPT')
                          and a.internal_id <> 'UC00049' and b.internal_id <> 'UC00049'
                          
                          UNION
                          
                          SELECT a.tower_id as new_tower_id, b.tower_id as old_tower_id
                          FROM ", schema, ".", table_global, " a
                          LEFT JOIN ",schema,".",table_old, " b
                          ON a.tower_name=b.tower_name
                          WHERE a.source IN ('TORRES ANDINAS','IPT')
                          and b.source IN ('TORRES ANDINAS','IPT')
                          
                          UNION
                          
                          SELECT a.tower_id as new_tower_id, b.tower_id as old_tower_id
                          FROM ", schema, ".", table_global, " a
                          LEFT JOIN ",schema,".",table_old, " b
                          ON (a.internal_id=b.internal_id AND ST_DWithin(a.geom,b.geom, 200))
                          WHERE a.source IN ('AZTECA','FIBER PLANNED')
                          and b.source  IN ('AZTECA','FIBER PLANNED')
                                  
                          UNION
                          
                          SELECT a.tower_id as new_tower_id, b.tower_id as old_tower_id
                          FROM ", schema, ".", table_global, "  a
                          LEFT JOIN ",schema,".",table_old, " b
                          ON (a.internal_id=b.internal_id AND a.location_detail=b.location_detail)
                          WHERE a.source IN ('PIA','OIMR')
                          and b.source IN ('PIA','OIMR')
                          
                          UNION
                          
                          SELECT a.tower_id as new_tower_id, b.tower_id as old_tower_id
                          FROM ", schema, ".", table_global, "  a
                          LEFT JOIN ",schema,".",table_old, " b
                          ON (a.source=b.source AND a.type=b.type)
                          WHERE a.internal_id = 'UC00049'
                          and b.internal_id = 'UC00049'    
            )")
    
    dbGetQuery(con,query)
    
    ## Drop backup table
    
    query <- paste0("DROP TABLE ",schema,".",table_old)
    dbGetQuery(con,query)
    
    dbDisconnect(con,query)
}