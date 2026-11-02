{# Bus Matrix: dim_customer. One row per customer_unique_id. Location = survivorship rule "most recent order wins"
   (latest order_purchase_timestamp, tie-break highest order_id). Order stats count orders of any status. #}
with cust_orders as (
    select
        c.customer_unique_id,
        c.zip_code_prefix,
        c.city,
        c.state,
        o.order_id,
        o.purchase_at
    from {{ ref('stg_customers') }} c
    left join {{ ref('stg_orders') }} o on o.customer_id = c.customer_id
),
latest as (
    select customer_unique_id, zip_code_prefix, city, state
    from (
        select *, row_number() over (
            partition by customer_unique_id
            order by purchase_at desc nulls last, order_id desc
        ) as rn
        from cust_orders
    ) t where rn = 1
),
stats as (
    select
        customer_unique_id,
        cast(min(purchase_at) as date)  as first_order_date,
        cast(max(purchase_at) as date)  as last_order_date,
        count(distinct order_id)        as order_count
    from cust_orders
    group by 1
),
final as (
    select
        {{ generate_surrogate_key(['l.customer_unique_id']) }}  as customer_key,
        l.customer_unique_id,
        l.zip_code_prefix                                       as customer_zip_code_prefix,
        l.city                                                  as customer_city,
        l.state                                                 as customer_state,
        coalesce(r.region, 'Unknown')                           as customer_region,
        coalesce(s.first_order_date, cast('1900-01-01' as date)) as first_order_date,
        coalesce(s.last_order_date,  cast('1900-01-01' as date)) as last_order_date,
        s.order_count                                           as order_count,
        s.order_count > 1                                       as is_repeat_customer
    from latest l
    join stats s on s.customer_unique_id = l.customer_unique_id
    left join {{ ref('seed_state_region') }} r on r.state_code = l.state
    union all
    select {{ unknown_key() }}, '-1', '-1', 'Unknown', '-1', 'Unknown',
           cast('1900-01-01' as date), cast('1900-01-01' as date), 0, false
)
select
    cast(customer_key as varchar(32))            as customer_key,
    cast(customer_unique_id as varchar(32))      as customer_unique_id,
    cast(customer_zip_code_prefix as char(5))    as customer_zip_code_prefix,
    cast(customer_city as varchar(50))           as customer_city,
    cast(customer_state as char(2))              as customer_state,
    cast(customer_region as varchar(15))         as customer_region,
    cast(first_order_date as date)               as first_order_date,
    cast(last_order_date as date)                as last_order_date,
    cast(order_count as integer)                 as order_count,
    cast(is_repeat_customer as boolean)          as is_repeat_customer
from final
