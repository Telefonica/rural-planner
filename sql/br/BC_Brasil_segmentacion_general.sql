-- QUERY SEGMENTACIÓN GRAL BRASIL

--TEF UNSERVED (Greenfield ALL)
SELECT 'greenfield all' as segment, sum(c.cluster_weight), sum(c.cluster_size), count(*) , SUM(CASE WHEN node_type LIKE '%TOWER%' THEN 1 ELSE 0 END) AS real_towers, 0 AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
where node_type NOT LIKE '%2G%'
and cluster_weight>=500

UNION
--TEF UNSERVED (Greenfield vivo=comp)
SELECT 'greenfield vivo=comp' as segment, sum(c.cluster_weight), sum(c.cluster_size), count(*)  , SUM(CASE WHEN node_type LIKE '%TOWER%' THEN 1 ELSE 0 END) AS real_towers, 0 AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
left join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
where node_type NOT LIKE '%2G%'
and (max_competitors<=max_vivo)
and cluster_weight>=500

UNION
--TEF UNSERVED (Greenfield vivo<comp)
SELECT 'greenfield vivo<comp' as segment, sum(c.cluster_weight), sum(c.cluster_size), count(*)  , SUM(CASE WHEN node_type LIKE '%TOWER%' THEN 1 ELSE 0 END) AS real_towers, 0 AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
where node_type NOT LIKE '%2G%'
and max_competitors>max_vivo
and cluster_weight>=500

UNION
--TEF UNSERVED (Overlay 2G all)
SELECT 'overlay 2g all' as segment, sum(c.cluster_weight), sum(c.cluster_size), count(*), SUM(CASE WHEN node_type LIKE '%VIRTUAL%' THEN 0 ELSE 1 END) AS real_towers, SUM(CASE WHEN node_type LIKE '%VIRTUAL%' THEN 1 ELSE 0 END) AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
where node_type LIKE '%2G%'
and cluster_weight>=500

UNION
--TEF UNSERVED (Overlay 2G vivo>comp)
SELECT 'overlay 2g vivo>comp' as segment, sum(c.cluster_weight), sum(c.cluster_size), count(*), SUM(CASE WHEN node_type LIKE '%VIRTUAL%' THEN 0 ELSE 1 END) AS real_towers, SUM(CASE WHEN node_type LIKE '%VIRTUAL%' THEN 1 ELSE 0 END) AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
where node_type LIKE '%2G%'
and max_competitors<max_vivo
and cluster_weight>=500

UNION
--TEF UNSERVED (Overlay 2G vivo=comp)
SELECT 'overlay 2g vivo=comp' as segment,sum(c.cluster_weight), sum(c.cluster_size), count(*), SUM(CASE WHEN node_type LIKE '%VIRTUAL%' THEN 0 ELSE 1 END) AS real_towers, SUM(CASE WHEN node_type LIKE '%VIRTUAL%' THEN 1 ELSE 0 END) AS virtual_towers 
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
where node_type LIKE '%2G%'
and max_competitors=max_vivo
and cluster_weight>=500

UNION
--TEF UNSERVED (Overlay 2G vivo<comp)
SELECT 'overlay 2g vivo<comp' as segment,sum(c.cluster_weight), sum(c.cluster_size), count(*) , SUM(CASE WHEN node_type LIKE '%VIRTUAL%' THEN 0 ELSE 1 END) AS real_towers, SUM(CASE WHEN node_type LIKE '%VIRTUAL%' THEN 1 ELSE 0 END) AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
where node_type LIKE '%2G%'
and max_competitors>max_vivo
and cluster_weight>=500
UNION
-- 3G ONLY
--TEF UNDERSERVED (3G only all)
SELECT '3g only all' as segment,sum(c.cluster_weight), sum(c.cluster_size), count(*) , SUM(CASE WHEN node_type LIKE '%SETTLEMENT%' THEN 0 ELSE 1 END) AS real_towers, SUM(CASE WHEN node_type LIKE '%SETTLEMENT%' THEN 1 ELSE 0 END) AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_3g_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_3g_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_3g_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
where cluster_weight>=500
UNION
--TEF UNDERSERVED (3G only vivo>comp)
SELECT '3g only vivo>comp' as segment, sum(c.cluster_weight), sum(c.cluster_size), count(*) , SUM(CASE WHEN node_type LIKE '%SETTLEMENT%' THEN 0 ELSE 1 END) AS real_towers, SUM(CASE WHEN node_type LIKE '%SETTLEMENT%' THEN 1 ELSE 0 END) AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_3g_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_3g_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_3g_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
WHERE max_competitors<max_vivo
and cluster_weight>=500
UNION
--TEF UNDERSERVED (3G only vivo=comp)
SELECT '3g only vivo=comp' as segment,sum(c.cluster_weight), sum(c.cluster_size), count(*) , SUM(CASE WHEN node_type LIKE '%SETTLEMENT%' THEN 0 ELSE 1 END) AS real_towers, SUM(CASE WHEN node_type LIKE '%SETTLEMENT%' THEN 1 ELSE 0 END) AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_3g_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_3g_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_3g_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
WHERE max_competitors=max_vivo
and cluster_weight>=500
UNION
--TEF UNDERSERVED (3G only vivo<comp)
SELECT '3g only vivo<comp' as segment,sum(c.cluster_weight), sum(c.cluster_size), count(*) , SUM(CASE WHEN node_type LIKE '%SETTLEMENT%' THEN 0 ELSE 1 END) AS real_towers, SUM(CASE WHEN node_type LIKE '%SETTLEMENT%' THEN 1 ELSE 0 END) AS virtual_towers
FROM (
SELECT centroid, cluster_weight, cluster_size, sum(max_vivo) as max_vivo, sum(max_competitors) as max_competitors, sum(settlements_vivo_2g) as settlements_vivo_2g, sum(population_vivo_2g) as population_vivo_2g,n.node_type
FROM (
SELECT a.*, CASE WHEN vivo_4g_corrected is true then 4
                WHEN vivo_3g_corrected is true then 3
                WHEN vivo_2g_corrected is true then 2
                else 0 end as max_vivo,
            CASE WHEN competitors_4g_corrected is true then 4
                WHEN competitors_3g_corrected is true then 3
                WHEN competitors_2g_corrected is true then 2
                else 0 end as max_competitors,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then 1
                else 0 end as settlements_vivo_2g,
            CASE WHEN vivo_2g_corrected is true AND vivo_3g_corrected is false and vivo_4g_corrected is false then population_corrected
                else 0 end as population_vivo_2g
                 
FROM
(SELECT
    centroid,
    cluster_weight,
    cluster_size,
    CASE
        WHEN (nodes = ''::text)
        THEN NULL::text
        ELSE btrim(unnest(string_to_array(REPLACE(nodes,
            ''''::text, ''::text), ','::text)))
    END AS nodes
FROM
    rural_planner_dev.clusters_3g_jv
WHERE nodes<>''
UNION
SELECT
    centroid,
    cluster_weight,
    cluster_size,
    centroid AS nodes
FROM
    rural_planner_dev.clusters_3g_jv) A
Left Join rural_planner_dev.coverage c
on A.nodes=c.settlement_id 
Left Join rural_planner_dev.settlements s
on A.nodes=s.settlement_id 
where c.settlement_id is not null) B
LEFT JOIN rural_planner_dev.node_table_3g_jv n
ON B.centroid=n.node_id
where cluster_weight>0
GROUP BY centroid, cluster_weight, cluster_size,node_type
) c
where max_competitors>max_vivo
and cluster_weight>=500
