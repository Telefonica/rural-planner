exportClientes <- function(schema, table, clientes){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                     host = host, port = port,
                     user = user, password = pwd) 
    
    query <- paste0("DROP TABLE IF EXISTS ", schema,".",table)
    dbGetQuery(con,query)
    
    dbWriteTable(con, 
                 c(schema,table), 
                 value = data.frame(clientes), row.names = F, append= F, replace= T)
    
    query <- paste("UPDATE ", schema,".",table, " SET settlement_id = 
                    CASE WHEN admin_division_2_name = 'BUENOS AIRES' then CONCAT('BA',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'CIUDAD AUTONOMA DE BUENOS AIRES' then CONCAT('BA',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'CATAMARCA' then CONCAT('CA',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'CHACO' then CONCAT('CH',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'CHUBUT' then CONCAT('CT',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'CORDOBA' then CONCAT('CB',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'CORRIENTES' then CONCAT('CR',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'ENTRE RIOS' then CONCAT('ER',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'FORMOSA' then CONCAT('FO',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'JUJUY' then CONCAT('JY',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'LA PAMPA' then CONCAT('LP',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'LA RIOJA' then CONCAT('LR',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'MENDOZA' then CONCAT('MZ',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'MISIONES' then CONCAT('MI',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'NEUQUEN' then CONCAT('NQ',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'RIO NEGRO' then CONCAT('RN',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'SALTA' then CONCAT('SA',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'SAN JUAN' then CONCAT('SJ',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'SAN LUIS' then CONCAT('SL',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'SANTA CRUZ' then CONCAT('SC',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'SANTA FE' then CONCAT('SF',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'SANTIAGO DEL ESTERO' then CONCAT('SE',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'TIERRA DEL FUEGO' then CONCAT('TF',lpad(settlement_id,5,'0'))
                         WHEN admin_division_2_name = 'TUCUMAN' then CONCAT('TU',lpad(settlement_id,5,'0'))
                         END", sep = "")
    dbGetQuery(con,query)
    
    
    dbDisconnect(con)

}