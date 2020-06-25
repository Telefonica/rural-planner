CREATE OR REPLACE VIEW {schema}.v_clusters_transporte as
(SELECT c.centroid as centroide,
        ct.centroid as id_centroide_transporte,
        CASE WHEN (s.settlement_name is null) then i.internal_id else s.settlement_name end AS nombre_centroide_transporte,
        ct.cluster_size as tamano_cluster_tx,
        ct.cluster_weight as poblacion_cluster_tx
        FROM {schema}.clusters c
        LEFT JOIN (SELECT centroid, 
                          BTRIM(UNNEST(string_to_array(nodes,' ,')),'''') AS node,
                          cluster_weight,
                          cluster_size 
                          FROM {schema}.transport_clusters
                   UNION
                   SELECT centroid,
                          centroid as node,
                          cluster_weight,
                          cluster_size
                   FROM {schema}.transport_clusters) ct
        ON c.centroid=ct.node
        LEFT JOIN {schema}.settlements s
        ON s.settlement_id=ct.centroid
        LEFT JOIN {schema}.infrastructure_global i
        ON i.tower_id::text=ct.centroid
        WHERE ct.centroid in (select tower_id::text FROM {schema}.infrastructure_global where source='SITES_TEF' and radio is true and fiber is false)     
        )