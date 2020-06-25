schoolsDirect <- function(schema, settlements_table, schools_table){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                         host = host, port = port,
                         user = user, password = pwd) 
    
    query <- paste0("SELECT s1.settlement_id, s2.educational_level,
                COUNT(s2.school_internal_id) AS school_count,
                SUM(s2.number_students::integer) as total_students
                FROM ",schema,".",settlements_table," s1
                LEFT JOIN ",schema,".",schools_table," s2
                ON s1.settlement_id=s2.settlement_id
                WHERE s2.status = 'ACTIVE'
                GROUP BY s1.settlement_id,s2.educational_level
                HAVING COUNT(s2.school_internal_id)>=1")
    
    schools_by_category_direct <- dbGetQuery(con,query)
    
    dbDisconnect(con)
    schools_by_category_direct
}