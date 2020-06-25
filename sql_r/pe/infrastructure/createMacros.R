createMacros <- function(schema, table_global, table_old){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    
    query <- paste0("UPDATE ", schema, ".", table_global, "
                     SET tower_id = NULL")
    dbGetQuery(con,query)
    
    ## FIRST MACROS BY INTERNAL ID AND TOWER TYPE
    
    query <- paste0("UPDATE ", schema, ".", table_global, "
                     SET tower_id = a.tower_id 
                     FROM (SELECT * 
                           FROM ",schema,".",table_old, "
                           WHERE source='MACROS') a 
                     WHERE ", table_global, ".internal_id=a.internal_id 
                     AND ", table_global, ".source=a.source
                    AND ", table_global, ".type=a.type")
    dbGetQuery(con,query)
    
    ## THEN FEMTOS, CANON, OIMR, IPT, EHAS, GILAT, REGIONAL, LAMBAYEQUE AND FIBER PLANNED BY INTERNAL ID
    
    
    query <- paste0("UPDATE ", schema, ".", table_global, "
                     SET tower_id = a.tower_id 
                     FROM (SELECT * 
                           FROM ",schema,".",table_old, "
                           WHERE source not in ('PIA','AZTECA', 'TORRES ANDINAS','FIBER_PLANNED','OIMR',
                                                'IPT','ENTEL', 'CLARO FIBER','MACROS')) a 
                     WHERE ", table_global, ".internal_id=a.internal_id 
                     AND ", table_global, ".source=a.source")
    dbGetQuery(con,query)
    
    ## THEN TORRES ANDINAS AND IPT BY TOWER NAME (NUMERIC/ AMBIGUOUS INTERNAL ID)
    
    query <- paste0("UPDATE ", schema, ".", table_global, "
                     SET tower_id = a.tower_id 
                     FROM (SELECT * 
                           FROM ",schema,".",table_old, "
                           WHERE source IN ('TORRES ANDINAS','IPT')) a 
                     WHERE ", table_global, ".tower_name=a.tower_name 
                     AND ", table_global, ".source=a.source")
    dbGetQuery(con,query)
    
    ## THEN AZTECA BY TOWER NAME (NUMERIC INTERNAL ID AND TOWER NAME): MIN DIST BETWEEN TOWERS = 750m
    
    query <- paste0("UPDATE ", schema, ".", table_global, "
                     SET tower_id = a.tower_id 
                     FROM (SELECT * 
                           FROM ",schema,".",table_old, "
                           WHERE source IN ('AZTECA','FIBER_PLANNED')) a 
                     WHERE ", table_global, ".internal_id=a.internal_id 
                     AND ", table_global, ".source IN ('AZTECA','FIBER_PLANNED') 
                     AND ST_DWithin(a.geom, ", table_global, ".geom ,750) ")
    dbGetQuery(con,query)
    
    ## THEN OIMR BY TOWER NAME (NUMERIC INTERNAL ID AND TOWER NAME) AND LOC.DETAIL
    
    query <- paste0("UPDATE ", schema, ".", table_global, " 
                     SET tower_id = a.tower_id 
                     FROM (SELECT * 
                           FROM ",schema,".",table_old, "
                           WHERE source IN ('OIMR')) a 
                     WHERE ", table_global, ".internal_id=a.internal_id 
                     AND ", table_global, ".source=a.source 
                     AND a.location_detail=", table_global, ".location_detail ")
    dbGetQuery(con,query)
    
    ## THEN  PIA BY LOC.DETAIL
    
    query <- paste0("UPDATE ", schema, ".", table_global, " 
                     SET tower_id = a.tower_id 
                     FROM (SELECT * 
                           FROM ",schema,".",table_old, "
                           WHERE source IN ('PIA')) a 
                     WHERE ", table_global, ".tower_name=a.tower_name 
                     AND ", table_global, ".source IN ('PIA') 
                     AND a.location_detail=", table_global, ".location_detail ")
    dbGetQuery(con,query)
    
    ## THEN  FIBER_PLANNED BY LOC.DETAIL AND LOCATION
    
    query <- paste0("UPDATE ", schema, ".", table_global, " 
                     SET tower_id = a.tower_id 
                     FROM (SELECT * 
                           FROM ",schema,".",table_old, "
                           WHERE source IN ('FIBER_PLANNED')) a 
                     WHERE ", table_global, ".source IN ('FIBER_PLANNED') 
                     AND a.location_detail=", table_global, ".location_detail
                     AND a.latitude=", table_global, ".latitude
                     AND a.longitude=", table_global, ".longitude ")
    dbGetQuery(con,query)
    
    # 
    # ## AD-HOC: Same internal_id but different location
    # 
    # query <- paste0("UPDATE rural_planner_pe_dev.infrastructure_global SET tower_id = a.tower_id FROM (
    #SELECT * FROM rural_planner_pe_dev.infrastructure_global_old_id_map
    #WHERE source IN ('FIBER PLANNED')
    #and internal_id = 'San Marcos'
    #) a WHERE (infrastructure_global.internal_id=a.internal_id and 
    #(infrastructure_global.latitude=a.latitude and infrastructure_global.longitude=a.longitude))
    #AND infrastructure_global.source IN ('FIBER PLANNED')")
    # dbGetQuery(con,query)
    
    ##THEN REST OF THE TOWERS (NEW SOURCES AND COMPETITORS)
    
    query <- paste0("SELECT MAX(tower_id)
                     FROM ",schema,".",table_old)
    max_id <- dbGetQuery(con,query)
    
    query <- paste0("UPDATE ", schema, ".", table_global, " 
                     SET tower_id = a.tower_id
                     FROM (SELECT (ROW_NUMBER() 
                                   OVER (ORDER BY source, latitude,longitude))+",max_id$max," as tower_id,
                                   latitude, longitude, source, internal_id
                           FROM ", schema, ".", table_global, " 
                           WHERE tower_id IS NULL) a 
                     WHERE ", table_global, ".tower_id IS NULL
                        AND ", table_global, ".latitude= a.latitude
                        AND ", table_global, ".longitude=a.longitude
                        AND ", table_global, ".source=a.source
                        AND ", table_global, ".internal_id = a.internal_id")
    dbGetQuery(con,query)
    
    
    
    dbDisconnect(con,query)
}