## Create auxiliar infra table
createInfraAuxTable <- function(schema, infrastructure_table, infrastructure_beams_table, table_satellite_ka_beams){
    
    #Set connection data
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    
    query <- paste0("SELECT i.tower_id, 
                      i.internal_id,
                    i.source,
                    i.geom,
                    CASE WHEN ST_Within(i.geom::geometry, s1.geom) THEN '-1'
                       WHEN ST_Within(i.geom::geometry, s2.geom) THEN '-2'
                       WHEN ST_Within(i.geom::geometry, s3.geom) THEN '-3'
                       WHEN ST_Within(i.geom::geometry, s4.geom) THEN '-4'
                       WHEN ST_Within(i.geom::geometry, s5.geom) THEN '-5'
                    END AS ka_beam_signal
              FROM ",schema,".",infrastructure_table,
              " i, (SELECT * FROM ",schema,".",table_satellite_ka_beams," WHERE signal_strength='-1') s1,
               (SELECT * FROM ",schema,".",table_satellite_ka_beams," WHERE signal_strength='-2') s2,
               (SELECT * FROM ",schema,".",table_satellite_ka_beams," WHERE signal_strength='-3') s3,
               (SELECT * FROM ",schema,".",table_satellite_ka_beams," WHERE signal_strength='-4') s4,
               (SELECT * FROM ",schema,".",table_satellite_ka_beams," WHERE signal_strength='-5') s5
    ")
    
    infrastructure_beams <- dbGetQuery(con, query)
    
    dbWriteTable(con, c(schema, infrastructure_beams_table), value= data.frame(infrastructure_beams), row.names=F)
    
    query <- paste("
    ALTER TABLE ", schema,".", infrastructure_beams_table,
    " ALTER geom TYPE geometry"
                   , sep = "")
    dbGetQuery(con, query)
    
    dbDisconnect(con)
  }