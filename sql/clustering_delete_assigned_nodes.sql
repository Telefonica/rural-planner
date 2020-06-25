DELETE FROM {schema}.{table_nodes} 
WHERE node_id IN ({excluded_ids});