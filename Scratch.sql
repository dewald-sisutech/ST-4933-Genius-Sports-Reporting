WITH

--PRE-FILTER LIVE-BET
sportsbook_data_v4 AS
                (
                    SELECT *
                    FROM sisu_sportsbook.sportsbook_data_v3
                    WHERE selection_product = 'live_bet' AND
                    resulted_date BETWEEN
                    DATE_SUB(DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH), INTERVAL 0 DAY) AND
                    LAST_DAY(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
                ),


--TO CONFIRM THAT THERE WAS A POSITIVE PAYOUT FOR THE USER AND THAT THE BONUS WALLET WAS UNLOCKED
wallets_temp AS (
                    SELECT wallet_id
                    FROM sisu_dwh.fact_locked_bonus_transactions lbt
                    WHERE lbt.wallet_is_active = false
                    AND lbt.brand = 'EPICBET'
                    GROUP BY wallet_id
                    HAVING sum(COALESCE(bonus_locks_fulfilled_amount_eur, 0)) > 0
                ),


--GET THE INITIAL ACTIVATION BONUS
activation_bonus AS
                (
                    SELECT wallet_id,
                        SUM(bonus_locks_activated_amount_eur) activation_bonus
                    FROM sisu_dwh.fact_locked_bonus_transactions
                    WHERE wallet_id IN (SELECT wallet_id FROM wallets_temp)
                    GROUP BY wallet_id
                ),


--TO GET SPORTSBOOK LIVE-BET WINNINGS FOR BONUS WALLET USERS
sportsbook_live_bet_winnings AS
                (
                    SELECT
                    bonus_wallet_id,
                    SUM(attributed_won_amount_eur) AS bonus_wallet_winnings_sb_live_bet
                    FROM sportsbook_data_v4
                    GROUP BY bonus_wallet_id
                ),


semi AS         (

                    --DOUBLE CHECK IF THE WALLET UNLOCK DATE IS WITHIN THE PERIOD!!!
                    SELECT
                    bonus_wallet_id,
                    ab.activation_bonus,
                    ABS(bonus_wallet_winnings_sb_live_bet) bonus_wallet_winnings,
                    CASE
                    WHEN ABS(bonus_wallet_winnings_sb_live_bet) > ABS(activation_bonus) THEN ABS(activation_bonus)
                    ELSE ABS(bonus_wallet_winnings_sb_live_bet)                                                     END bonus_cost
                    FROM wallets_temp wal
                    INNER JOIN sportsbook_live_bet_winnings lbw ON wal.wallet_id = lbw.bonus_wallet_id
                    INNER JOIN activation_bonus ab on wal.wallet_id = ab.wallet_id ORDER BY bonus_wallet_id asc
                )
,
    final AS (SELECT * FROM semi)

SELECT * FROM final;