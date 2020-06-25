updateDBPartners <- function(schema, table_tmp, alianzas){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("DROP TABLE IF EXISTS ", schema,".",table_tmp)
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table_tmp), 
                 value = data.frame(alianzas), row.names = F, append= F, replace= T)
    
    
    query <- paste("ALTER TABLE ", schema,".",table_tmp, " ADD COLUMN geom GEOMETRY ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("ALTER TABLE ", schema,".",table_tmp, " ALTER COLUMN settlement_id TYPE text USING settlement_id::TEXT ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema,".",table_tmp, " SET geom = ST_SetSRID(ST_MakePoint(longitude::numeric, latitude::numeric), 4326) ", sep = "")
    dbGetQuery(con,query)
    
    query <- paste("UPDATE ", schema,".",table_tmp, " SET settlement_id = 
                    CASE WHEN admin_division_2_id = 'BUENOS AIRES' then CONCAT('BA',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'CIUDAD AUTONOMA DE BUENOS AIRES' then CONCAT('BA',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'CATAMARCA' then CONCAT('CA',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'CHACO' then CONCAT('CH',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'CHUBUT' then CONCAT('CT',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'CORDOBA' then CONCAT('CB',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'CORRIENTES' then CONCAT('CR',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'ENTRE RIOS' then CONCAT('ER',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'FORMOSA' then CONCAT('FO',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'JUJUY' then CONCAT('JY',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'LA PAMPA' then CONCAT('LP',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'LA RIOJA' then CONCAT('LR',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'MENDOZA' then CONCAT('MZ',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'MISIONES' then CONCAT('MI',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'NEUQUEN' then CONCAT('NQ',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'RIO NEGRO' then CONCAT('RN',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'SALTA' then CONCAT('SA',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'SAN JUAN' then CONCAT('SJ',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'SAN LUIS' then CONCAT('SL',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'SANTA CRUZ' then CONCAT('SC',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'SANTA FE' then CONCAT('SF',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'SANTIAGO DEL ESTERO' then CONCAT('SE',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'TIERRA DEL FUEGO' then CONCAT('TF',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_id = 'TUCUMAN' then CONCAT('TU',lpad(settlement_id,5,'0'))
                         END", sep = "")
    dbGetQuery(con,query)
    
    dbDisconnect(con)
}