schoolsIndirect <- function(schools_by_category_indirect_table, settlements_table, schema, schools_table, school_radius_km){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                         host = host, port = port,
                         user = user, password = pwd) 
    
    query <- paste0("CREATE TABLE ",schema,'.',schools_by_category_indirect_table," AS (
                (SELECT DISTINCT(s1.settlement_id) AS settlement_id, s2.educational_level,
                COUNT(s2.school_internal_id) AS school_count,
                SUM(s2.number_students::integer) as total_students
                FROM ",schema,".",settlements_table," s1
                LEFT JOIN ",schema,".",schools_table," s2
                ON ST_Dwithin(s1.geom::geography,s2.geom::geography,", school_radius_km,"*1000)
                WHERE (s2.status = 'ACTIVE')
                GROUP BY s1.settlement_id, s2.educational_level
                HAVING COUNT(s2.school_internal_id)>=1))")

    dbGetQuery(con,query)
    
    query <- paste0("SELECT * FROM ",schema,".",schools_by_category_indirect_table)
    schools_by_category_indirect <- dbGetQuery(con,query)
    
    
    dbDisconnect(con)
    schools_by_category_indirect
}