SELECT tower_id
FROM {schema}.{table} S1
WHERE source NOT IN ({sources_omit})
ORDER BY tower_id