--GENIUS RAW DATA
WITH sport_mapping AS (
        SELECT DISTINCT
        CAST(provider_entity_id AS INT)                 AS provider_entity_id,
        entity_id                                       AS sport_id,
        s.name                                          AS sport_name
        from landing_zone_epicbet_prod.sport_mapping sm
        inner join landing_zone_epicbet_prod.sport_sport s on sm.entity_id = s.id
        where entity_type = 'sport'

),

league_mapping AS (
        SELECT DISTINCT
        provider_entity_id          AS provider_entity_id,
        sl.id                       AS league_id,
        sl.name                     AS league_name
        from landing_zone_epicbet_prod.sport_mapping sm
        inner join landing_zone_epicbet_prod.sport_league sl ON sm.entity_id = sl.id
        where entity_type = 'league'
        order by league_id asc
),

match_mapping AS (
        SELECT DISTINCT
            sm.provider_entity_id       AS provider_entity_id ,
            mat.id                      AS match_id,
            mat.name                    AS match_name
        from landing_zone_epicbet_prod.sport_mapping sm
        inner join landing_zone_epicbet_prod.sport_match mat
        ON sm.entity_id = mat.id AND sm.entity_type = 'match'
),

--PRE-FILTER LIVE-BET
    sportsbook_data_v4 AS (SELECT *
                           FROM sisu_sportsbook.sportsbook_data_v3
                           WHERE selection_product = 'live_bet' AND
                                 bonus_wallet_id IS NOT NULL AND
                                 resulted_date between '2024-06-01' and '2024-07-01'),


--ATTACH ADDITIONAL GENIUS MAPPING REPORT DATA
    final as (
    SELECT sb.sport_name                                                 AS                       sport,
                     sm.provider_entity_id                                         AS                       sport_id,
                     sb.league_name                                                AS                       competition,
                     lm.provider_entity_id                                         AS                       competition_id,
                     sb.match_name                                                 AS                       fixture_name,
                     mm.provider_entity_id                                         AS                       fixture_id,
                     sb.match_start_date                                           AS                       fixture_date,
                     'EUR'                                                         AS                       currency,
                     COUNT(DISTINCT sb.bet_id)                                     AS                       bet_count,
                    SUM(COALESCE(attributed_won_amount_eur,0)) AS attributed_won_amount_eur,
                     SUM(sb.ggr_live_bet_eur)                                      AS                       ggr_live_bet_eur,
                     COUNT(DISTINCT
                    CASE WHEN sb.bet_status in ('pushed', 'cancelled') THEN sb.bet_id ELSE null END) void_count
                FROM sportsbook_data_v4 sb
                INNER JOIN sport_mapping sm ON sb.sport_id = sm.sport_id
                       INNER JOIN league_mapping lm ON sb.league_id = lm.league_id
                       INNER JOIN match_mapping mm ON sb.match_id = mm.match_id
              GROUP BY sb.sport_name,
                       sm.provider_entity_id,
                       sb.league_name,
                       lm.provider_entity_id,
                       sb.match_name,
                       mm.provider_entity_id,
                       sb.match_start_date)

select * from final