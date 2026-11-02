with stg_customers as (
    select * from {{ source('northwind', 'Customers') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['customerid']) }} as customerkey,
    customerid,
    companyname,
    contactname,
    contacttitle,
    address as customeraddress,
    city as customercity,
    region as customerregion,
    postalcode as customerpostalcode,
    country as customercountry,
    phone as customerphone,
    fax as customerfax
from stg_customers
