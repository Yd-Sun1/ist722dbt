-- Fails (returns rows) when item_total_amount <> price_amount + freight_amount.
select order_id, order_item_id
from {{ ref('fact_order_items') }}
where item_total_amount <> price_amount + freight_amount
