WITH

    final_2 as (

        SELECT * FROM sisu_revenue.genius_report_raw_data
     ),


f3 as (
SELECT 1 _sort, '€0 - €300,000' AS revenue_range,
       15 AS revenue_share_perc,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 0 AND 300000 THEN sum(ggr_live_bet_eur) ELSE NULL END AS ggr

FROM final_2
UNION ALL
SELECT 2 _sort,'€300,001 - €500,000' AS revenue_range,12 AS revenue_share_perc,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 300001 AND 500000 THEN sum(ggr_live_bet_eur) ELSE NULL END AS ggr
FROM final_2
UNION ALL
SELECT 3 _sort, '€500,001 - €1,000,000' AS revenue_range,8 AS revenue_share_perc,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 500001 AND 1000000 THEN sum(ggr_live_bet_eur) ELSE NULL END AS ggr
FROM final_2
UNION ALL
SELECT 4 _sort,'€1,000,001 +' AS revenue_range,5 AS revenue_share_perc,
       CASE WHEN sum(ggr_live_bet_eur) > 1000000 THEN sum(ggr_live_bet_eur) ELSE NULL END AS ggr
FROM final_2)

     select _sort, revenue_range, revenue_share_perc, ggr, ggr * (revenue_share_perc / 100) revenue_share
     from f3 order by _sort asc