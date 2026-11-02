{# Bus Matrix: fact_order_items. Transaction fact. Grain: one row per order item (order_id + order_item_id).
   Every FK uses the dimension's unknown member ('-1' for hash keys, -1 for dates) when the lookup misses. #}
select
    cast(oi.order_id as varchar(32))                                                as order_id,
    cast(oi.order_item_id as integer)                                               as order_item_id,
    cast(coalesce(dd_p.date_key, -1) as integer)                                    as purchase_date_key,
    cast(coalesce(dd_s.date_key, -1) as integer)                                    as shipping_limit_date_key,
    cast(coalesce(dc.customer_key,      {{ unknown_key() }}) as varchar(32))        as customer_key,
    cast(coalesce(ds.seller_key,        {{ unknown_key() }}) as varchar(32))        as seller_key,
    cast(coalesce(dp.product_key,       {{ unknown_key() }}) as varchar(32))        as product_key,
    cast(coalesce(dgc.geography_key,    {{ unknown_key() }}) as varchar(32))        as customer_geography_key,
    cast(coalesce(dgs.geography_key,    {{ unknown_key() }}) as varchar(32))        as seller_geography_key,
    cast(coalesce(dos.order_status_key, {{ unknown_key() }}) as varchar(32))        as order_status_key,
    cast(1 as integer)                                                              as item_count,
    cast(oi.price_amount as decimal(12,2))                                          as price_amount,
    cast(oi.freight_amount as decimal(12,2))                                        as freight_amount,
    cast(oi.price_amount + oi.freight_amount as decimal(12,2))                      as item_total_amount
from {{ ref('stg_order_items') }} oi
left join {{ ref('stg_orders') }} o         on o.order_id = oi.order_id
left join {{ ref('stg_customers') }} sc     on sc.customer_id = o.customer_id
left join {{ ref('dim_customer') }} dc      on dc.customer_unique_id = sc.customer_unique_id
left join {{ ref('stg_sellers') }} ss       on ss.seller_id = oi.seller_id
left join {{ ref('dim_seller') }} ds        on ds.seller_id = oi.seller_id
left join {{ ref('dim_product') }} dp       on dp.product_id = oi.product_id
left join {{ ref('dim_geography') }} dgc    on dgc.zip_code_prefix = sc.zip_code_prefix
left join {{ ref('dim_geography') }} dgs    on dgs.zip_code_prefix = ss.zip_code_prefix
left join {{ ref('dim_order_status') }} dos on dos.order_status_code = o.order_status
left join {{ ref('dim_date') }} dd_p        on dd_p.date_key = {{ date_key('o.purchase_at') }}
left join {{ ref('dim_date') }} dd_s        on dd_s.date_key = {{ date_key('oi.shipping_limit_at') }}
