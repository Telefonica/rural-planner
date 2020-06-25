DELETE FROM {schema}.{table_nodes} 
WHERE node_type LIKE '%%TOWER%%' OR node_type LIKE '%%3G%%';
