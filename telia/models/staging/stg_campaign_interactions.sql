with source as (

    select * from {{ source('raw', 'campaign_interactions') }}

)

select
    interaction_id,
    customer_id,
    campaign_id,
    channel,
    interaction_type,
    interaction_ts::timestamp as interaction_at
from source
