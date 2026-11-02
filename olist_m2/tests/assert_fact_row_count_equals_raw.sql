-- Fails (returns a row) when the fact table does not have exactly one row per raw order item.
select f.n as fact_rows, r.n as raw_rows
from (select count(*) as n from {{ ref('fact_order_items') }}) f
cross join (select count(*) as n from {{ source('olist', 'ORDER_ITEMS') }}) r
where f.n <> r.n
