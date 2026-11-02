{# Bus Matrix: dim_seller. One row per seller + unknown member '-1'. Used only by fact_order_items. #}
with final as (
    select
        {{ generate_surrogate_key(['s.seller_id']) }}  as seller_key,
        s.seller_id,
        s.zip_code_prefix                              as seller_zip_code_prefix,
        s.city                                         as seller_city,
        s.state                                        as seller_state,
        coalesce(r.region, 'Unknown')                  as seller_region
    from {{ ref('stg_sellers') }} s
    left join {{ ref('seed_state_region') }} r on r.state_code = s.state
    union all
    select {{ unknown_key() }}, '-1', '-1', 'Unknown', '-1', 'Unknown'
)
select
    cast(seller_key as varchar(32))              as seller_key,
    cast(seller_id as varchar(32))               as seller_id,
    cast(seller_zip_code_prefix as char(5))      as seller_zip_code_prefix,
    cast(seller_city as varchar(50))             as seller_city,
    cast(seller_state as char(2))                as seller_state,
    cast(seller_region as varchar(15))           as seller_region
from final
