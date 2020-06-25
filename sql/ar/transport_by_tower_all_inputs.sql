SELECT 
tower_id,
source as owner,
fiber,
radio,
tx_3g,
tx_third_pty,
satellite
FROM {schema}.{table}
WHERE source NOT IN ({sources_omit})
AND in_service IN ('IN SERVICE','AVAILABLE')
ORDER BY tower_id