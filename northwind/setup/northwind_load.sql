create database if not exists analytics;

create database if not exists raw;

create schema if not exists analytics.northwind;

create schema if not exists raw.northwind;

create schema if not exists raw.conformed;

create file format if not exists RAW.NORTHWIND.PARQUET 
    TYPE = parquet
    REPLACE_INVALID_CHARACTERS = TRUE;

create STAGE if not exists RAW.NORTHWIND.externalworld_database
  URL = 'azure://externalworld.blob.core.windows.net/database/'
  FILE_FORMAT = RAW.NORTHWIND.PARQUET;

create TABLE if not exists raw.conformed.datedimension (
    datekey int
    ,date date
    ,datetime timestamp
    ,year int
    ,quarter int
    ,quartername varchar(2)
    ,month int
    ,monthname varchar(3)
    ,day int
    ,dayofweek int
    ,dayname varchar(3)
    ,weekday varchar(1)
    ,weekofyear int
    ,dayofyear int
) AS
    WITH CTE_MY_DATE AS (
    SELECT DATEADD(DAY, SEQ4(), '1970-01-01 00:00:00') AS MY_DATE
    FROM TABLE(GENERATOR(ROWCOUNT=>365*30))
    )
    SELECT
    TO_CHAR(TO_DATE(MY_DATE), 'YYYYMMDD')::int  as datekey,
    TO_DATE(MY_DATE) as date
    ,TO_TIMESTAMP(MY_DATE) as datetime
    ,YEAR(MY_DATE) as year
    ,QUARTER(MY_DATE) as quarter
    ,CONCAT('Q', QUARTER(MY_DATE)::varchar) as quartername
    ,MONTH(MY_DATE) as month
    ,MONTHNAME(MY_DATE) as monthname
    ,DAY(MY_DATE) as day
    ,DAYOFWEEK(MY_DATE) as dayofweek
    ,DAYNAME(MY_DATE) as dayname
    ,case when DAYOFWEEK(MY_DATE) between 1 and 5 then 'Y' else 'N' end as weekday
    ,WEEKOFYEAR(MY_DATE) as weekofyear
    ,DAYOFYEAR(MY_DATE) as dayofyear
    FROM CTE_MY_DATE;

create table if not exists RAW.northwind.categories
(
    categoryid int,
    categoryname varchar,
    description varchar
);

copy into RAW.northwind.categories
    FROM '@RAW.NORTHWIND.externalworld_database/northwind.categories.parquet' 
    MATCH_BY_COLUMN_NAME='CASE_INSENSITIVE';

create table if not exists RAW.NORTHWIND.customers
(
    customerid varchar,
    companyname varchar,
    contactname varchar,
    contacttitle varchar,
    address varchar,
    city varchar,
    region varchar,
    postalcode varchar,
    country varchar,
    phone varchar,
    fax varchar
);

copy into RAW.northwind.customers
    FROM '@RAW.NORTHWIND.externalworld_database/northwind.customers.parquet' 
    MATCH_BY_COLUMN_NAME='CASE_INSENSITIVE';

create table if not exists RAW.NORTHWIND.employees
(
    employeeid int,
    lastname varchar,
    firstname varchar,
    title varchar,
    titleofcourtsey varchar,
    birthdate varchar,
    hiredate varchar,
    address varchar,
    city varchar,
    region varchar,
    postalcode varchar,
    country varchar,
    homephone varchar,
    extension varchar,
    notes varchar,
    reportsto int
) AS
    SELECT 
    $1:EmployeeID::int
    ,$1:LastName::varchar
    ,$1:FirstName::varchar
    ,$1:Title::varchar
    ,$1:TitleOfCourtesy::varchar
    ,$1:BirthDate
    ,$1:HireDate
    ,$1:Address::varchar
    ,$1:City::varchar
    ,$1:Region::varchar
    ,$1:PostalCode::varchar
    ,$1:Country::varchar
    ,$1:HomePhone::varchar
    ,$1:Extension::varchar
    ,$1:Notes::varchar
    ,$1:ReportsTo::int
    FROM '@RAW.NORTHWIND.externalworld_database/northwind.employees.parquet'
    (FILE_FORMAT=>RAW.NORTHWIND.PARQUET);

create table if not exists RAW.NORTHWIND.order_details
(
    orderid int,
    productid int,
    unitprice decimal(18,4),
    quantity int,
    discount decimal(18,4)
);

copy into RAW.northwind.order_details
    FROM '@RAW.NORTHWIND.externalworld_database/northwind.order_details.parquet' 
    MATCH_BY_COLUMN_NAME='CASE_INSENSITIVE';

create table if not exists RAW.NORTHWIND.orders
(
    orderid int,
    customerid varchar,
    employeeid int,
    orderdate varchar,
    requireddate varchar,
    shippeddate varchar,
    shipvia int,
    freight decimal(18,4),
    shipname varchar,
    shipaddress varchar,
    shipcity varchar,
    shipregion varchar,
    shippostalcode varchar,
    shipcountry varchar
);

copy into RAW.northwind.orders
    FROM '@RAW.NORTHWIND.externalworld_database/northwind.orders.parquet' 
    MATCH_BY_COLUMN_NAME='CASE_INSENSITIVE';

create table if not exists RAW.NORTHWIND.products
(
    productid int,
    productname varchar,
    supplierid int,
    categoryid int,
    quantityperunit varchar,
    unitprice decimal(18,4),
    unitsinstock int,
    unitsonorder int,
    reorderlevel int,
    discontinued int
);

copy into RAW.northwind.products
    FROM '@RAW.NORTHWIND.externalworld_database/northwind.products.parquet' 
    MATCH_BY_COLUMN_NAME='CASE_INSENSITIVE';

create table if not exists RAW.NORTHWIND.shippers
(
    shipperid int,
    companyname varchar,
    phone varchar
    
);

copy into RAW.northwind.shippers
    FROM '@RAW.NORTHWIND.externalworld_database/northwind.shippers.parquet' 
    MATCH_BY_COLUMN_NAME='CASE_INSENSITIVE';

create table if not exists RAW.NORTHWIND.suppliers
(
    supplierid int,
    companyname varchar,
    contactname varchar,
    contacttitle varchar,
    address varchar,
    city varchar,
    region varchar,
    postalcode varchar,
    country varchar,
    phone varchar,
    fax varchar,
    homepage varchar
);

copy into RAW.northwind.suppliers
    FROM '@RAW.NORTHWIND.externalworld_database/northwind.suppliers.parquet' 
    MATCH_BY_COLUMN_NAME='CASE_INSENSITIVE';

select table_catalog, table_schema, table_name, row_count
from RAW.INFORMATION_SCHEMA.TABLES
where table_schema in ('NORTHWIND', 'CONFORMED')
order by table_schema, table_name;
