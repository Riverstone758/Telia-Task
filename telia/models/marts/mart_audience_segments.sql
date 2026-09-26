with consented as (

    -- Permission to make marketing contact by email, SMS or phone.
    select distinct customer_id
    from {{ ref('stg_consent_registry') }}
    where purpose_code in ('PP_012', 'PP_013', 'PP_014')
        and consent_at <= date '{{ var("as_of_date") }}'

),

eligible as (

    select metrics.*
    from {{ ref('int_customer_metrics') }} as metrics
    inner join consented on metrics.customer_id = consented.customer_id

),

flagged as (

    select
        customer_id,

        subscription_status = 'active'
            and subscription_plan = 'premium'
            and login_days_last_14d >= 5
            and open_rate_last_60d > 0.30 as is_high_value_engaged,

        subscription_status = 'active'
            and (days_since_last_login is null or days_since_last_login >= 14)
            and events_30_to_60d_ago > 0 as is_at_risk_dormant,

        subscription_status = 'active'
            and subscription_plan in ('basic', 'standard')
            and logins_last_30d >= 10
            and support_tickets_last_90d = 0 as is_upgrade_candidate,

        subscription_status = 'churned'
            and days_since_status_change between 0 and 89
            and open_rate_before_churn > 0.20 as is_winback_target,

        -- A customer with no activity in either window is not declining, so
        -- the earlier window has to hold something to compare against.
        subscription_status = 'active'
            and active_days_prior_14d > 0
            and active_days_last_14d < 0.5 * active_days_prior_14d as is_engagement_declining

    from eligible

)

select customer_id, 'high_value_engaged' as segment_name from flagged where is_high_value_engaged
union all
select customer_id, 'at_risk_dormant' from flagged where is_at_risk_dormant
union all
select customer_id, 'upgrade_candidate' from flagged where is_upgrade_candidate
union all
select customer_id, 'winback_target' from flagged where is_winback_target
union all
select customer_id, 'engagement_declining' from flagged where is_engagement_declining
