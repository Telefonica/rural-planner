SELECT centroid,
'-' as owner,
FALSE AS fiber,
FALSE AS radio
FROM {schema}.{table_clusters} S1
WHERE S1.centroid_type LIKE '%%SETTLEMENT%%'
ORDER BY centroid