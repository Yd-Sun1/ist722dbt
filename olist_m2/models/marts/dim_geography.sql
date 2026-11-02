{# Bus Matrix: dim_geography. One row per 5-character zip prefix from the UNION of geolocation, customers and sellers.
   city/state = most frequent (MODE) normalized value in geolocation; prefixes not in geolocation fall back to the
   customer/seller city/state. latitude/longitude = average of the points inside Brazil (NULL if none). #}
with geo_city_counts as (
    select zip_code_prefix, city, state, count(*) as n
    from {{ ref('stg_geolocation') }}
    group by 1, 2, 3
),
geo_city as (
    select zip_code_prefix, city, state
    from (
        select *, row_number() over (partition by zip_code_prefix order by n desc, city, state) as rn
        from geo_city_counts
    ) t where rn = 1
),
geo_coords as (
    select zip_code_prefix, avg(lat) as latitude, avg(lng) as longitude
    from {{ ref('stg_geolocation') }}
    where lat between {{ var('brazil_lat_min') }} and {{ var('brazil_lat_max') }}
      and lng between {{ var('brazil_lng_min') }} and {{ var('brazil_lng_max') }}
    group by 1
),
other_counts as (
    select zip_code_prefix, city, state, count(*) as n
    from (
        select zip_code_prefix, city, state from {{ ref('stg_customers') }}
        union all
        select zip_code_prefix, city, state from {{ ref('stg_sellers') }}
    ) u
    where zip_code_prefix is not null
    group by 1, 2, 3
),
other_city as (
    select zip_code_prefix, city, state
    from (
        select *, row_number() over (partition by zip_code_prefix order by n desc, city, state) as rn
        from other_counts
    ) t where rn = 1
),
all_zips as (
    select zip_code_prefix from geo_city
    union
    select zip_code_prefix from other_city
),
joined as (
    select
        z.zip_code_prefix,
        coalesce(g.city, o.city)       as city,
        coalesce(g.state, o.state)     as state,
        c.latitude,
        c.longitude,
        g.zip_code_prefix is not null  as has_geolocation
    from all_zips z
    left join geo_city g   on g.zip_code_prefix = z.zip_code_prefix
    left join geo_coords c on c.zip_code_prefix = z.zip_code_prefix
    left join other_city o on o.zip_code_prefix = z.zip_code_prefix
),
final as (
    select
        {{ generate_surrogate_key(['j.zip_code_prefix']) }}  as geography_key,
        j.zip_code_prefix,
        j.city,
        j.state,
        coalesce(r.region, 'Unknown')                        as region,
        j.latitude,
        j.longitude,
        j.has_geolocation
    from joined j
    left join {{ ref('seed_state_region') }} r on r.state_code = j.state
    union all
    select {{ unknown_key() }}, '-1', 'Unknown', '-1', 'Unknown', cast(null as double), cast(null as double), false
)
select
    cast(geography_key as varchar(32))     as geography_key,
    cast(zip_code_prefix as char(5))       as zip_code_prefix,
    cast(city as varchar(50))              as city,
    cast(state as char(2))                 as state,
    cast(region as varchar(15))            as region,
    cast(latitude as decimal(9,6))         as latitude,
    cast(longitude as decimal(9,6))        as longitude,
    cast(has_geolocation as boolean)       as has_geolocation
from final
