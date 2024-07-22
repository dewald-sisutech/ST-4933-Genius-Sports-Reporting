WITH

--PRE-FILTER LIVE-BET
sportsbook_data_v4 AS (SELECT *
                           FROM sisu_sportsbook.sportsbook_data_v3
                           WHERE selection_product = 'live_bet' AND
                                 bonus_wallet_id IS NOT NULL AND
                                 resulted_date BETWEEN
                                  DATE_SUB(DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH), INTERVAL 0 DAY) AND
                                  LAST_DAY(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))),

--TO CONFIRM THAT THERE WAS A POSITIVE PAYOUT FOR THE USER AND THAT THE BONUS WALLET WAS UNLOCKED
wallets_temp as (select wallet_id
                     from sisu_dwh.fact_locked_bonus_transactions lbt
                     where lbt.wallet_is_active = false
                       and lbt.brand = 'EPICBET'
                     group by wallet_id
                     having sum(COALESCE(bonus_locks_fulfilled_amount_eur, 0)) > 0),


--GET THE INITIAL ACTIVATION BONUS
activation_bonus as (select wallet_id,
                            sum(bonus_locks_activated_amount_eur) activation_bonus
                        from sisu_dwh.fact_locked_bonus_transactions
                         where wallet_id in (select wallet_id from wallets_temp)
                         group by wallet_id
                         ),

--TO GET SPORTSBOOK LIVE-BET WINNINGS FOR BONUS WALLET USERS
sportsbook_live_bet_winnings as (select
                                bonus_wallet_id,
                                --selection_id,
                                sum(attributed_won_amount_eur) AS bonus_wallet_winnings_sb_live_bet
                          from sportsbook_data_v4
                          group by bonus_wallet_id),

semi as (

--DOUBLE CHECK IF THE WALLET UNLOCK DATE IS WITHIN THE PERIOD!!!
    SELECT
    bonus_wallet_id,
    ab.activation_bonus,
    ABS(bonus_wallet_winnings_sb_live_bet) bonus_wallet_winnings,
        CASE
            WHEN ABS(bonus_wallet_winnings_sb_live_bet) > ABS(activation_bonus) THEN ABS(activation_bonus)
            ELSE ABS(bonus_wallet_winnings_sb_live_bet) END bonus_cost
    FROM wallets_temp wal
    INNER JOIN sportsbook_live_bet_winnings lbw ON wal.wallet_id = lbw.bonus_wallet_id
    INNER JOIN activation_bonus ab on wal.wallet_id = ab.wallet_id ORDER BY bonus_wallet_id asc)
,
    final as (SELECT *, bonus_cost * 0.1 bonus_allocation
              FROM semi)

select * from final;


SELECT SUM(bonus_cost) total_bonus, sum(bonus_cost) * 0.1 bonus_allocation  FROM semi