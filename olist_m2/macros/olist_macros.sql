{# Hash natural keys with MD5. The null marker and separator follow
   dbt_utils.generate_surrogate_key conventions. This local macro needs no package. #}
{% macro generate_surrogate_key(field_list) %}
{%- set parts = [] -%}
{%- for f in field_list -%}
    {%- do parts.append("coalesce(cast(" ~ f ~ " as varchar), '_dbt_utils_surrogate_key_null_')") -%}
{%- endfor -%}
md5(cast({{ parts | join(" || '-' || ") }} as varchar))
{%- endmacro %}

{# Unknown-member key for every hash-keyed dimension (Bus Matrix: '-1'). #}
{% macro unknown_key() %}'-1'{% endmacro %}

{# City normalisation: lower case, trimmed, accents removed (translate exists in DuckDB and Snowflake). #}
{% macro normalize_city(col) %}
translate(lower(trim({{ col }})),
          'áàâãäéèêëíìîïóòôõöúùûüçñ',
          'aaaaaeeeeiiiiooooouuuucn')
{% endmacro %}

{# YYYYMMDD integer from a date/timestamp expression (arithmetic: no to_char/strftime differences). #}
{% macro date_key(col) %}
cast(extract(year from cast({{ col }} as date)) * 10000
     + extract(month from cast({{ col }} as date)) * 100
     + extract(day from cast({{ col }} as date)) as integer)
{% endmacro %}

{# ISO week number: the only place the two databases differ (DuckDB weekofyear / Snowflake weekiso). #}
{% macro iso_week(col) %}{{ return(adapter.dispatch('iso_week', 'olist_m2')(col)) }}{% endmacro %}
{% macro default__iso_week(col) %}weekiso({{ col }}){% endmacro %}
{% macro duckdb__iso_week(col) %}weekofyear({{ col }}){% endmacro %}
