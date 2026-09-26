with events as (

    select
        customer_id,
        event_type,
        event_at::date as event_date,
        date_diff('day', event_at::date, date '{{ var("as_of_date") }}') as days_ago
    from {{ ref('stg_product_events') }}
    where days_ago >= 0

),

activity as (

    select
        customer_id,

        count(*) filter (where event_type = 'login' and days_ago < 30) as logins_last_30d,
        count(*) filter (where event_type = 'support_ticket' and days_ago < 90) as support_tickets_last_90d,

        min(days_ago) as days_since_last_activity,
        min(days_ago) filter (where event_type = 'login') as days_since_last_login,

        count(distinct event_date) filter (where days_ago < 14) as active_days_last_14d,
        count(distinct event_date) filter (where days_ago between 14 and 27) as active_days_prior_14d,
        count(distinct event_date) filter (where event_type = 'login' and days_ago < 14) as login_days_last_14d,

        count(*) filter (where days_ago between 30 and 59) as events_30_to_60d_ago

    from events
    group by customer_id

),

sends as (

    select
        customer_id,
        max(interaction_at) filter (where interaction_type = 'delivered') as delivered_at,
        bool_or(interaction_type = 'opened') as was_opened
    from {{ ref('stg_campaign_interactions') }}
    group by customer_id, campaign_id, channel

),

deliveries as (

    select
        sends.customer_id,
        sends.was_opened,
        date_diff('day', sends.delivered_at::date, date '{{ var("as_of_date") }}') as days_ago,
        customers.subscription_status = 'churned'
            and sends.delivered_at < customers.status_change_date as before_churn
    from sends
    inner join {{ ref('stg_customers') }} as customers
        on sends.customer_id = customers.customer_id
    where sends.delivered_at is not null
        and days_ago >= 0

),

engagement as (

    select
        customer_id,
        count(*) filter (where days_ago < 60) as delivered_last_60d,
        count(*) filter (where days_ago < 60 and was_opened) as opened_last_60d,

        count(*) filter (where before_churn) as delivered_before_churn,
        count(*) filter (where before_churn and was_opened) as opened_before_churn
    from deliveries
    group by customer_id

)

select
    customers.customer_id,
    customers.subscription_plan,
    customers.subscription_status,
    date_diff('day', customers.status_change_date, date '{{ var("as_of_date") }}') as days_since_status_change,

    coalesce(activity.logins_last_30d, 0) as logins_last_30d,
    coalesce(activity.support_tickets_last_90d, 0) as support_tickets_last_90d,
    coalesce(activity.active_days_last_14d, 0) as active_days_last_14d,
    coalesce(activity.active_days_prior_14d, 0) as active_days_prior_14d,
    coalesce(activity.login_days_last_14d, 0) as login_days_last_14d,
    coalesce(activity.events_30_to_60d_ago, 0) as events_30_to_60d_ago,

    activity.days_since_last_activity,
    activity.days_since_last_login,

    coalesce(engagement.delivered_last_60d, 0) as delivered_last_60d,
    coalesce(engagement.opened_last_60d, 0) as opened_last_60d,

    engagement.opened_last_60d::double
        / nullif(engagement.delivered_last_60d, 0) as open_rate_last_60d,
    engagement.opened_before_churn::double
        / nullif(engagement.delivered_before_churn, 0) as open_rate_before_churn

from {{ ref('stg_customers') }} as customers
left join activity on customers.customer_id = activity.customer_id
left join engagement on customers.customer_id = engagement.customer_id
