
SELECT 
*
FROM (
SELECT DISTINCT
S.settlement_id,
'OVERLAY' AS overlay_2g_segment
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_coverage} C
ON S.settlement_id = C.settlement_id
WHERE (C.movistar_3g_corrected IS FALSE AND movistar_4g_corrected IS FALSE AND movistar_2g_corrected IS TRUE)
) A
ORDER BY A.settlement_id