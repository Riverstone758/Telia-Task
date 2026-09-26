with source as (

    select * from {{ source('raw', 'consent_purpose_code') }}

)

select
    purpose_code,
    name as purpose_name,
    legal_ground
from source
