
SELECT
*
FROM (
SELECT DISTINCT
S.settlement_id,
'GREENFIELD' AS fully_unconnected_segment
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_coverage} C
ON S.settlement_id = C.settlement_id
WHERE (C.vivo_3g_corrected IS FALSE AND C.vivo_4g_corrected IS FALSE  AND C.vivo_2g_corrected IS FALSE)
AND (C.competitors_3g_corrected IS FALSE AND C.competitors_4g_corrected IS FALSE)

UNION

SELECT DISTINCT
S.settlement_id,
'OVERLAY' AS fully_unconnected_segment
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_coverage} C
ON S.settlement_id = C.settlement_id
WHERE (C.vivo_3g_corrected IS FALSE AND C.vivo_4g_corrected IS FALSE AND C.vivo_2g_corrected IS TRUE)
AND (C.competitors_3g_corrected IS FALSE AND C.competitors_4g_corrected IS FALSE)
) A
ORDER BY A.settlement_id