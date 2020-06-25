SELECT *
FROM (
SELECT DISTINCT
S.settlement_id,
CASE WHEN (C.movistar_3g_corrected IS TRUE OR C.movistar_4g_corrected IS TRUE) THEN 'TELEFONICA SERVED' 
    ELSE 'TELEFONICA UNSERVED' END AS telefonica_organic_segment
FROM {schema}.{table_settlements} S
LEFT JOIN {schema}.{table_coverage} C
ON S.settlement_id = C.settlement_id
) A
ORDER BY A.settlement_id