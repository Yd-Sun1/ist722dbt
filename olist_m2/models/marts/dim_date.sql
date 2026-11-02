{# Bus Matrix: dim_date. One row per day from var('date_start') (2016-01-01) to 31 Dec of the year of the latest
   date in any source date column, plus -1 (Unknown or invalid) and -2 (Not yet occurred).
   The day list is built with plain cross joins (no package needed); the holiday flags come from seed_holidays. #}
with bounds as (
    select
        cast('{{ var("date_start") }}' as date) as start_d,
        cast(cast(extract(year from max(d)) as varchar) || '-12-31' as date) as end_d
    from (
        select purchase_at as d from {{ ref('stg_orders') }}
        union all select approved_at from {{ ref('stg_orders') }}
        union all select delivered_carrier_at from {{ ref('stg_orders') }}
        union all select delivered_customer_at from {{ ref('stg_orders') }}
        union all select estimated_delivery_at from {{ ref('stg_orders') }}
        union all select shipping_limit_at from {{ ref('stg_order_items') }}
    ) x
),
digits as (
    select 0 as n union all select 1 union all select 2 union all select 3 union all select 4
    union all select 5 union all select 6 union all select 7 union all select 8 union all select 9
),
numbers as (
    select a.n + 10*b.n + 100*c.n + 1000*d.n as n
    from digits a cross join digits b cross join digits c cross join digits d
),
days as (
    select cast({{ dbt.dateadd('day', 'numbers.n', 'bounds.start_d') }} as date) as full_date, bounds.end_d
    from bounds cross join numbers
),
cal as (
    select full_date from days where full_date <= end_d
),
calendar as (
    select
        {{ date_key('c.full_date') }}                                              as date_key,
        c.full_date                                                                as full_date,
        'Calendar'                                                                 as date_member_type,
        mod({{ dbt.datediff("cast('1900-01-01' as date)", 'c.full_date', 'day') }}, 7) + 1 as day_of_week_number,  -- ISO: Mon=1..Sun=7 (1900-01-01 was a Monday)
        extract(day from c.full_date)                                              as day_of_month,
        {{ iso_week('c.full_date') }}                                              as week_of_year,
        extract(month from c.full_date)                                            as month_number,
        extract(quarter from c.full_date)                                          as quarter_number,
        extract(year from c.full_date)                                             as year_number,
        coalesce(h.holiday_type = 'national', false)                               as is_national_holiday,
        coalesce(h.holiday_type = 'optional', false)                               as is_optional_observance,
        h.holiday_name                                                             as holiday_name
    from cal c
    left join {{ ref('seed_holidays') }} h on cast(h.holiday_date as date) = c.full_date
),
named as (
    select
        date_key, full_date, date_member_type, day_of_week_number,
        case day_of_week_number when 1 then 'Monday' when 2 then 'Tuesday' when 3 then 'Wednesday'
             when 4 then 'Thursday' when 5 then 'Friday' when 6 then 'Saturday' else 'Sunday' end as day_name,
        day_of_month, week_of_year, month_number,
        case month_number when 1 then 'January' when 2 then 'February' when 3 then 'March'
             when 4 then 'April' when 5 then 'May' when 6 then 'June' when 7 then 'July'
             when 8 then 'August' when 9 then 'September' when 10 then 'October'
             when 11 then 'November' else 'December' end                                              as month_name,
        cast(year_number as varchar) || '-' || lpad(cast(month_number as varchar), 2, '0')            as year_month,
        quarter_number, year_number,
        day_of_week_number >= 6                                                                       as is_weekend,
        is_national_holiday, is_optional_observance, holiday_name
    from calendar
),
special as (
    select -1 as date_key, cast('1900-01-01' as date) as full_date, 'Unknown or invalid' as date_member_type,
           0 as day_of_week_number, 'Unknown' as day_name, 0 as day_of_month, 0 as week_of_year, 0 as month_number,
           'Unknown' as month_name, 'Unknown' as year_month, 0 as quarter_number, 0 as year_number,
           false as is_weekend, false as is_national_holiday, false as is_optional_observance, cast(null as varchar) as holiday_name
    union all
    select -2, cast('9999-12-31' as date), 'Not yet occurred',
           0, 'Unknown', 0, 0, 0, 'Unknown', 'Unknown', 0, 0, false, false, false, cast(null as varchar)
),
final as (
    select * from named
    union all
    select * from special
)
select
    cast(date_key as integer)               as date_key,
    cast(full_date as date)                 as full_date,
    cast(date_member_type as varchar(20))   as date_member_type,
    cast(day_of_week_number as tinyint)     as day_of_week_number,
    cast(day_name as varchar(10))           as day_name,
    cast(day_of_month as tinyint)           as day_of_month,
    cast(week_of_year as tinyint)           as week_of_year,
    cast(month_number as tinyint)           as month_number,
    cast(month_name as varchar(10))         as month_name,
    cast(year_month as varchar(7))          as year_month,
    cast(quarter_number as tinyint)         as quarter_number,
    cast(year_number as smallint)           as year_number,
    cast(is_weekend as boolean)             as is_weekend,
    cast(is_national_holiday as boolean)    as is_national_holiday,
    cast(is_optional_observance as boolean) as is_optional_observance,
    cast(holiday_name as varchar(50))       as holiday_name
from final
