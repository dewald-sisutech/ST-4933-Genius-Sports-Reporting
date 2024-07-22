   with wal as (
                    select
                    wallet_id,
                    sum(bonus_locks_activated_amount_eur) activation_bonus
                    from sisu_dwh.fact_locked_bonus_transactions lbt
                    where
                    lbt.wallet_is_active = false
                    and lbt.brand = 'EPICBET'
                    group by wallet_id
                    having sum(COALESCE(bonus_locks_fulfilled_amount_eur,0)) > 0

   )


                    select
                    sum(v.ggr_live_bet_eur)
                    from sisu_sportsbook.sportsbook_data_v3 v
                    where
                    v.selection_product = 'live_bet'
                    and v.bet_status = 'won'

                    and v.resulted_date between '2024-06-01' and '2024-07-01'
                    and v.bonus_wallet_id in
(
                    select
                    wallet_id,
                   from wal
                    );


select sum(ggr_live_bet_eur) from sisu_sportsbook.genius_reporting;

