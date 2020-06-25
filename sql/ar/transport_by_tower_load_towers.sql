SELECT tower_id
FROM {schema}.{table} S1
WHERE source NOT IN ({sources_omit})
AND in_service IN ('IN SERVICE','AVAILABLE')
ORDER BY tower_id