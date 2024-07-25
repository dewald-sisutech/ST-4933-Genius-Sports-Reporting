WITH

    final_2 as (

        SELECT * FROM sisu_revenue.genius_report_raw_data),

    total_bonus_cost as (
        select SUM(bonus_cost) bonus_cost from sisu_revenue.live_bet_bonus_cost
    ),


f3 as (
SELECT 1 _sort, '€0 - €300,000' AS revenue_range,
       15 AS revenue_share_perc,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 0 AND 300000 THEN sum(ggr_live_bet_eur) * 0.15 ELSE NULL END AS revenue_share,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 0 AND 300000 THEN sum(ggr_live_bet_eur) ELSE NULL END AS ggr,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 0 AND 300000 THEN (select bonus_cost from total_bonus_cost) ELSE NULL END AS bonus_cost,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 0 AND 300000 THEN sum(ggr_live_bet_eur)*0.2 ELSE NULL END AS max_allocation

FROM final_2
UNION ALL
SELECT 2 _sort,'€300,001 - €500,000' AS revenue_range,12 AS revenue_share_perc,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 300001 AND 500000 THEN sum(ggr_live_bet_eur) * 0.12 ELSE NULL END AS revenue_share,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 300001 AND 500000 THEN sum(ggr_live_bet_eur) ELSE NULL END AS ggr,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 300001 AND 500000 THEN (select bonus_cost from total_bonus_cost) ELSE NULL END AS bonus_cost,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 300001 AND 500000 THEN sum(ggr_live_bet_eur)*0.2 ELSE NULL END AS max_allocation
FROM final_2
UNION ALL
SELECT 3 _sort, '€500,001 - €1,000,000' AS revenue_range,8 AS revenue_share_perc,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 500001 AND 1000000 THEN sum(ggr_live_bet_eur) * 0.08 ELSE NULL END AS revenue_share,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 500001 AND 1000000 THEN sum(ggr_live_bet_eur) ELSE NULL END AS ggr,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 500001 AND 1000000 THEN (select bonus_cost from total_bonus_cost) ELSE NULL END AS bonus_cost,
       CASE WHEN sum(ggr_live_bet_eur) BETWEEN 500001 AND 1000000 THEN sum(ggr_live_bet_eur)*0.2 ELSE NULL END AS max_allocation
FROM final_2
UNION ALL
SELECT 4 _sort,'€1,000,001 +' AS revenue_range,5 AS revenue_share_perc,
       CASE WHEN sum(ggr_live_bet_eur) > 1000000 THEN sum(ggr_live_bet_eur) * 0.05 ELSE NULL END AS revenue_share,
       CASE WHEN sum(ggr_live_bet_eur) > 1000000 THEN sum(ggr_live_bet_eur) ELSE NULL END AS ggr,
       CASE WHEN sum(ggr_live_bet_eur) > 1000000 THEN (select bonus_cost from total_bonus_cost) ELSE NULL END AS bonus_cost,
       CASE WHEN sum(ggr_live_bet_eur) > 1000000 THEN sum(ggr_live_bet_eur)*0.2 ELSE NULL END AS max_allocation
FROM final_2),

    f4 as (select _sort,
                  revenue_range,
                  revenue_share_perc,
                  ggr,
                  revenue_share,
                  bonus_cost,
                  max_allocation,
                  CASE WHEN bonus_cost > max_allocation THEN max_allocation ELSE bonus_cost end bonus_allocation
           from f3
           order by _sort asc)

select * from f4