SELECT *
FROM rural_planner.{table_towers}
WHERE ipt_perimeter = 'IPT'
AND tech_3g IS FALSE
AND tech_4g IS FALSE
AND radio IS FALSE 
AND fiber IS FALSE