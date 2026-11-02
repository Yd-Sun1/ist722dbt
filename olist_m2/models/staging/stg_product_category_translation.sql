select
    lower(trim(product_category_name))          as category_name_pt,
    lower(trim(product_category_name_english))  as category_name_en
from {{ source('olist', 'PRODUCT_CATEGORY_NAME_TRANSLATION') }}
