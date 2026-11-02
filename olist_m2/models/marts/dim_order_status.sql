{# Bus Matrix: dim_order_status. PK = md5 hash of order_status_code; unknown member '-1'. #}
with statuses as (
    select distinct order_status as order_status_code
    from {{ ref('stg_orders') }}
    where order_status is not null
),
final as (
    select
        {{ generate_surrogate_key(['order_status_code']) }}                      as order_status_key,
        order_status_code,
        upper(substr(order_status_code, 1, 1)) || substr(order_status_code, 2)   as order_status_name,   -- INITCAP (single-word statuses)
        order_status_code = 'delivered'                                          as is_delivered,
        order_status_code in ('canceled', 'unavailable')                         as is_canceled_or_unavailable
    from statuses
    union all
    select {{ unknown_key() }}, '-1', 'Unknown', false, false
)
select
    cast(order_status_key as varchar(32))              as order_status_key,
    cast(order_status_code as varchar(20))             as order_status_code,
    cast(order_status_name as varchar(30))             as order_status_name,
    cast(is_delivered as boolean)                      as is_delivered,
    cast(is_canceled_or_unavailable as boolean)        as is_canceled_or_unavailable
from final
