
WITH
bonus_locks_fulfilled as (
                        SELECT
                        wallet_id,
                        dim_user_id,
                        sum(bonus_locks_fulfilled_amount_eur) bonus_locks_fulfilled_amount_eur
--                                ,                      transaction_date bonus_lock_fulfilled_date
                        FROM sisu_dwh.fact_locked_bonus_transactions
                        inner join sisu_dwh.dim_date dat ON transaction_date = dat.full_date
                        WHERE
                        brand = 'EPICBET' and
                        wallet_is_active = false and
                        product = 'SPORTSBOOK'
                        and transaction_date >= '2024-06-01' and transaction_date <= '2024-06-30'
                        GROUP BY wallet_id, dim_user_id, transaction_date
                     ),

bonus_allocation as (select wallet_id, bonus_locks_activated_amount_eur, transaction_date bonus_allocation_date
                      from sisu_dwh.fact_locked_bonus_transactions
                      where bonus_transaction_type = 'activation'
                        and product = 'SPORTSBOOK'
                        and brand = 'EPICBET'
                      order by wallet_id asc),

semi as (select bonus_wallet_id,
                SUM(attributed_won_amount_eur)  won_amount_eur,
                SUM(attributed_lost_amount_eur) lost_amount_eur,
                CASE
                    WHEN SUM(attributed_won_amount_eur) - SUM(attributed_lost_amount_eur) > 0
                        THEN SUM(attributed_won_amount_eur) - SUM(attributed_lost_amount_eur)
                    ELSE 0 END AS balance
         from sisu_sportsbook.sportsbook_data_v3
         where bonus_wallet_id in (select wallet_id from bonus_locks_fulfilled) AND selection_product = 'live_bet'
         group by bonus_wallet_id),

semi_raw as (
select *
         from sisu_sportsbook.sportsbook_data_v3
         where bonus_wallet_id in (select wallet_id from bonus_locks_fulfilled) AND selection_product = 'live_bet'

),


bonus as (select *,
                 CASE
                     WHEN balance > bonus_locks_activated_amount_eur THEN bonus_locks_activated_amount_eur
                     ELSE balance END bonus_cost
          from semi s
                   inner join bonus_allocation ba on s.bonus_wallet_id = ba.wallet_id)

select * from semi_raw;

select bonus_wallet_id,
       bonus_allocation_date,
       sum(won_amount_eur) won_amount_eur,
       sum(lost_amount_eur) lost_amount_eur,
       sum(bonus_locks_activated_amount_eur) bonus_locks_activated_amount_eur,
       sum(bonus_cost) bonus_cost
from bonus
group by bonus_wallet_id, bonus_allocation_date
order by bonus_wallet_id asc
