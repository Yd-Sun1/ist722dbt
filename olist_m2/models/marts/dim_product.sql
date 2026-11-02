{# Bus Matrix: dim_product. One row per product; category flattened in; volume + weight band derived. #}
with final as (
    select
        {{ generate_surrogate_key(['p.product_id']) }}                                  as product_key,
        p.product_id,
        coalesce(p.category_name_pt, 'unknown')                                         as category_name_pt,
        coalesce(t.category_name_en, o.name_en, 'Unknown')                              as category_name_en,
        p.name_length                                                                   as product_name_length,
        p.description_length                                                            as product_description_length,
        p.photos_qty                                                                    as product_photos_qty,
        p.weight_g                                                                      as product_weight_g,
        p.length_cm                                                                     as product_length_cm,
        p.height_cm                                                                     as product_height_cm,
        p.width_cm                                                                      as product_width_cm,
        p.length_cm * p.height_cm * p.width_cm                                          as product_volume_cm3,
        case
            when p.weight_g is null    then 'Unknown'
            when p.weight_g < 500      then 'Under 500 g'
            when p.weight_g < 2000     then '500 g to under 2 kg'
            when p.weight_g < 10000    then '2 kg to under 10 kg'
            else '10 kg and over'
        end                                                                             as weight_band
    from {{ ref('stg_products') }} p
    left join {{ ref('stg_product_category_translation') }} t on t.category_name_pt = p.category_name_pt
    left join {{ ref('seed_category_override') }} o on o.product_category_name = p.category_name_pt
    union all
    select {{ unknown_key() }}, '-1', 'unknown', 'Unknown',
           cast(null as integer), cast(null as integer), cast(null as integer), cast(null as integer),
           cast(null as integer), cast(null as integer), cast(null as integer), cast(null as integer), 'Unknown'
)
select
    cast(product_key as varchar(32))              as product_key,
    cast(product_id as varchar(32))               as product_id,
    cast(category_name_pt as varchar(60))         as category_name_pt,
    cast(category_name_en as varchar(60))         as category_name_en,
    cast(product_name_length as integer)          as product_name_length,
    cast(product_description_length as integer)   as product_description_length,
    cast(product_photos_qty as integer)           as product_photos_qty,
    cast(product_weight_g as integer)             as product_weight_g,
    cast(product_length_cm as integer)            as product_length_cm,
    cast(product_height_cm as integer)            as product_height_cm,
    cast(product_width_cm as integer)             as product_width_cm,
    cast(product_volume_cm3 as integer)           as product_volume_cm3,
    cast(weight_band as varchar(20))              as weight_band
from final
