updateHousehold <- function(schema, table_admin_division_1, table_settlements, admin_division_1_wrong_capital, table_admin_division_2){
    drv <- dbDriver("PostgreSQL")
    con <- dbConnect(drv, dbname = dbname,
                    host = host, port = port,
                     user = user, password = pwd)
    
    #Duplicate original columns 
    query <- paste("ALTER TABLE ",schema, ".", table_admin_division_1," ADD COLUMN households_resto_original numeric", sep="")
    dbGetQuery(con, query)
    
    query <- paste("UPDATE ",schema, ".", table_admin_division_1," SET households_resto_original = households_resto", sep="")
    dbGetQuery(con, query)
    
    query <- paste("ALTER TABLE ",schema, ".", table_settlements," ADD COLUMN households_original numeric", sep="")
    dbGetQuery(con, query)
    
    query <- paste("UPDATE ",schema, ".", table_settlements," SET households_original = households", sep="")
    dbGetQuery(con, query)
    
    query <- paste("ALTER TABLE ",schema, ".", table_settlements," ADD COLUMN origen_households text", sep="")
    dbGetQuery(con, query)
    
    query <- paste("UPDATE ",schema, ".", table_settlements," SET origen_households = 'Recuento households'", sep="")
    dbGetQuery(con, query)
    
    # Create households for settlements with less than 20
    query <- paste0(
              "UPDATE ",schema, ".", table_settlements," I SET households = H.households_final, origen_households = 
              H.origen_households FROM (
             SELECT A.settlement_id,G.households_final, G.origen_households
             FROM ",schema, ".", table_settlements," A
             LEFT JOIN (
                    SELECT *, 
                            CASE 
                              WHEN num_settlements_lower_20 = num_settlements AND zrd = 1 THEN zrd_households
                              WHEN num_settlements_lower_20 = num_settlements AND zrd IS NULL THEN 1
                              ELSE avg_households_no_zrd
                              END AS households_final,
                            CASE 
                              WHEN num_settlements_lower_20 = num_settlements AND zrd = 1 THEN 'Igual a ZRD'
                              WHEN num_settlements_lower_20 = num_settlements AND zrd IS NULL THEN 'Todos settlements igual'
                              ELSE 'Media resto settlements'
                            END AS origen_households
                    FROM (
                            SELECT B.admin_division_1_id,B.num_settlements_lower_20, C.num_settlements, D.ZRD,D.ZRD_households,E.avg_households_no_ZRD
                            FROM (
                                    SELECT admin_division_1_id,count(*) AS num_settlements_lower_20
                                    FROM ",schema, ".", table_settlements,"  
                                    WHERE households <20 AND settlement_id NOT LIKE '%-%'
                                    AND (RIGHT(settlement_id,3) != '000' OR settlement_id LIKE '%-%')
                                    GROUP BY admin_division_1_id 
                            )B--429 municipios donde hay centros poblados oficiales con menos de 20 households
                            LEFT JOIN 
                            ( 
                                    SELECT admin_division_1_id, count(*) AS num_settlements
                                    FROM ",schema, ".", table_settlements," 
                                    WHERE (right(settlement_id,3) != '000' OR settlement_id like '%-%') AND settlement_id not like '%-ZRD'
                                    GROUP BY admin_division_1_id
                            ) C -- Numero total de centros poblados sin contar cabecera ni ZRD
                            ON B.admin_division_1_id = C.admin_division_1_id
                            LEFT JOIN
                            (
                                    SELECT admin_division_1_id, count(*) AS ZRD, households AS ZRD_households
                                    FROM ",schema, ".", table_settlements," 
                                    WHERE RIGHT(settlement_id,3) = 'ZRD'
                                    GROUP BY admin_division_1_id,households
                            ) D -- Tiene o no ZRD?
                            ON B.admin_division_1_id = D.admin_division_1_id
                            LEFT JOIN
                            (
                                    SELECT admin_division_1_id, avg(households)::integer AS avg_households_no_ZRD
                                    FROM ",schema, ".", table_settlements," 
                                    WHERE (RIGHT(settlement_id,3) != '000' OR settlement_id like '%-%') AND settlement_id NOT LIKE '%-ZRD'
                                    GROUP BY admin_division_1_id
                            )E -- Media de households sin contar ZRD
                            ON B.admin_division_1_id = E.admin_division_1_id
                            GROUP BY B.admin_division_1_id,B.num_settlements_lower_20, C.num_settlements, D.ZRD,D.ZRD_households, E.avg_households_no_ZRD
                            ORDER BY B.admin_division_1_id
                    ) F
             )G
             ON A.admin_division_1_id = G.admin_division_1_id
             WHERE A.households <20 and A.settlement_id NOT LIKE '%-%'
             AND (right(settlement_id,3) != '000' OR settlement_id LIKE '%-%')
        )H 
        WHERE I.settlement_id = H.settlement_id")
    dbGetQuery(con, query)
      
      #Update households_resto in admin_division_1 table with new households and recalculate norm_factor
    
    query <- paste0(" UPDATE ",schema, ".", table_admin_division_1," C SET households_resto = B.households_resto FROM (
             SELECT A.admin_division_1_id, sum(households) AS households_resto
             FROM ",schema, ".", table_settlements," A
             WHERE (RIGHT(settlement_id,3) != '000' OR settlement_id like '%-%')
             GROUP BY A.admin_division_1_id
             )B
             WHERE B.admin_division_1_id = C.admin_division_1_id")
    dbGetQuery(con, query)
    
    query <- paste("UPDATE ",schema, ".", table_admin_division_1," SET population_resto_estimation=  
                    households_resto*c.hab_house FROM ",schema, ".", table_admin_division_2," c
                    WHERE ",table_admin_division_1,".admin_division_2_id=c.admin_division_2_id AND admin_division_1_id NOT IN 
                    ('",paste(admin_division_1_wrong_capital,collapse="','"),"')", sep="")
    
    dbGetQuery(con,query)
    
    # We also take into account households in the capital in municipalities where the population is wrong
    query <- paste("UPDATE ",schema, ".", table_admin_division_1," SET population_resto_estimation = 
                    (households_resto+households_cabecera)*c.hab_house FROM 
                    ",schema, ".", table_admin_division_2," c
                    WHERE ",table_admin_division_1,".admin_division_2_id=c.admin_division_2_id 
                    AND population_cabecera = 0", sep="")
    
    dbGetQuery(con,query)  
    
    
    query <- paste0("UPDATE ",schema, ".", table_admin_division_1," SET norm_factor= population_resto/population_resto_estimation")
    dbGetQuery(con,query)
    
    # Recalculate population corrected
    
    query <- paste0("UPDATE ", schema, ".", table_settlements, " SET population_corrected = c.population_corrected
                   FROM (SELECT s.settlement_id,
                   CASE WHEN (RIGHT(s.settlement_id,3)='000' AND settlement_id NOT LIKE '%-%') THEN population_census
                   ELSE s.households*m.norm_factor*d.hab_house END as population_corrected
                   FROM  ",schema, ".", table_settlements," s 
                   LEFT JOIN ",schema, ".", table_admin_division_1," m
                   ON s.admin_division_1_id=m.admin_division_1_id
                   LEFT JOIN ",schema, ".", table_admin_division_2," d
                   ON s.admin_division_2_id=d.admin_division_2_id
                   GROUP BY s.settlement_id, s.population_census, m.norm_factor, d.hab_house,s.households) c 
                   WHERE ", table_settlements, ".settlement_id=c.settlement_id")
    
    dbGetQuery(con,query)
    
    #Update capitals with households = 0 
    
    query <- paste0("UPDATE ", schema, ".", table_settlements, " SET population_corrected = c.population_corrected
                   FROM (SELECT s.settlement_id,
                   s.households*m.norm_factor*d.hab_house as population_corrected
                   FROM  ",schema, ".", table_settlements," s 
                   LEFT JOIN ",schema, ".", table_admin_division_1," m
                   ON s.admin_division_1_id=m.admin_division_1_id
                   LEFT JOIN ",schema, ".", table_admin_division_2," d
                   ON s.admin_division_2_id=d.admin_division_2_id
                   WHERE (RIGHT(s.settlement_id,3)='000' AND settlement_id NOT LIKE '%-%')
                   AND population_census is null
                   GROUP BY s.settlement_id, s.population_census, m.norm_factor, d.hab_house,s.households) c 
                   WHERE ", table_settlements, ".settlement_id=c.settlement_id")
    
    dbGetQuery(con,query)
      
      
    dbDisconnect(con)
}