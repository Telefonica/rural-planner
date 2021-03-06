SELECT DISTINCT ON (settlement_id)
*
FROM (
SELECT 
S.settlement_id,
'GREENFIELD' AS greenfield_segment
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_coverage} C
ON S.settlement_id = C.settlement_id
WHERE (C.vivo_3g_corrected IS FALSE AND C.vivo_4g_corrected IS FALSE AND C.vivo_2g_corrected IS FALSE)
) A
ORDER BY settlement_id