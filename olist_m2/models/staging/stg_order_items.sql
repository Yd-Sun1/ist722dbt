select
    trim(order_id)                                   as order_id,
    try_cast(order_item_id as integer)               as order_item_id,
    trim(product_id)                                 as product_id,
    trim(seller_id)                                  as seller_id,
    try_cast(shipping_limit_date as timestamp)       as shipping_limit_at,
    try_cast(price as decimal(12,2))                 as price_amount,
    try_cast(freight_value as decimal(12,2))         as freight_amount
from {{ source('olist', 'ORDER_ITEMS') }}
