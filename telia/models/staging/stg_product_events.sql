with source as (

    select * from {{ source('raw', 'product_events') }}

)

select
    event_id,
    customer_id,
    event_type,
    event_ts::timestamp as event_at,
    event_properties::json as event_properties
from source
