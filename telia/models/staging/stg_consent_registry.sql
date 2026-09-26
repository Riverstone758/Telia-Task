with source as (

    select * from {{ source('raw', 'consent_registry') }}

)

select
    -- The registry stores only the numeric part of the identifier, so the
    -- prefix is added here to make it joinable to customers.
    'CUST_' || customer_id as customer_id,
    purpose_code,
    consent_ts::timestamp as consent_at
from source
