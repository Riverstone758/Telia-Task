-- Nobody may be activated without marketing consent, so every customer in the
-- mart has to hold one of the direct marketing purposes.

select segments.customer_id
from {{ ref('mart_audience_segments') }} as segments
where not exists (
    select 1
    from {{ ref('stg_consent_registry') }} as consents
    where consents.customer_id = segments.customer_id
        and consents.purpose_code in ('PP_012', 'PP_013', 'PP_014')
)
