with stg_orders as (
    select
        orderid,
        {{ dbt_utils.generate_surrogate_key(['employeeid']) }} as employeekey,
        {{ dbt_utils.generate_surrogate_key(['customerid']) }} as customerkey,
        to_char(to_date(orderdate), 'YYYYMMDD')::int as orderdatekey,
        to_char(to_date(shippeddate), 'YYYYMMDD')::int as shippeddatekey,
        to_char(to_date(requireddate), 'YYYYMMDD')::int as requireddatekey,
        to_date(orderdate) as orderdate,
        to_date(shippeddate) as shippeddate,
        to_date(requireddate) as requireddate,
        shipname,
        shipaddress,
        shipcity,
        shipregion,
        shippostalcode,
        shipcountry,
        freight,
        shipvia
    from {{ source('northwind', 'Orders') }}
),
stg_order_details as (
    select
        orderid,
        sum(quantity) as quantityonorder,
        sum(quantity * unitprice * (1 - discount)) as totalorderamount
    from {{ source('northwind', 'Order_Details') }}
    group by orderid
),
stg_shippers as (
    select * from {{ source('northwind', 'Shippers') }}
)
select
    o.orderid,
    o.employeekey,
    o.customerkey,
    o.orderdatekey,
    o.shippeddatekey,
    o.requireddatekey,
    o.shipname,
    o.shipaddress,
    o.shipcity,
    o.shipregion,
    o.shippostalcode,
    o.shipcountry,
    o.freight,
    o.shipvia,
    s.companyname as shippercompanyname,
    od.quantityonorder,
    od.totalorderamount,
    datediff('day', o.orderdate, o.shippeddate) as daysfromordertoshipped,
    datediff('day', o.orderdate, o.requireddate) as daysfromordertorequired,
    datediff('day', o.requireddate, o.shippeddate) as shippedtorequireddelta,
    case
        when o.shippeddate is null or o.requireddate is null then null
        when o.shippeddate <= o.requireddate then 'Y'
        else 'N'
    end as shippedontime
from stg_orders o
join stg_order_details od on o.orderid = od.orderid
join stg_shippers s on s.shipperid = o.shipvia
