with source as (

    select * from {{ source('raw', 'customers') }}

)

select
    customer_id,

    case
        when lower(trim(email)) like '%_@_%._%' then lower(trim(email))
    end as email,

    regexp_replace(phone_number, '\s', '', 'g') as phone_number,

    signup_date::date as signup_date,
    subscription_plan,
    subscription_status,
    status_change_date::date as status_change_date

from source
