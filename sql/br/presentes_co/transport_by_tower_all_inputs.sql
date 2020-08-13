SELECT 
tower_id,
source as owner,
fiber,
radio,
FALSE AS tx_3g,
FALSE AS tx_third_pty,
satellite
FROM {schema}.{table} 
WHERE fiber IS FALSE AND radio IS FALSE AND tech_4g IS FALSE and source NOT LIKE '%%LINES' AND source NOT IN ({sources_omit})
ORDER BY tower_id