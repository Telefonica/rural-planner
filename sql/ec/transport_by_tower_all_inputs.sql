SELECT 
tower_id,
source as owner,
fiber,
radio,
satellite
FROM {schema}.{table}
WHERE source NOT IN ({sources_omit})
ORDER BY tower_id