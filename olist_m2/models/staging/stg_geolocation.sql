select
    lpad(trim(geolocation_zip_code_prefix), 5, '0')   as zip_code_prefix,
    try_cast(geolocation_lat as double)               as lat,
    try_cast(geolocation_lng as double)               as lng,
    {{ normalize_city('geolocation_city') }}          as city,
    upper(trim(geolocation_state))                    as state
from {{ source('olist', 'GEOLOCATION') }}
