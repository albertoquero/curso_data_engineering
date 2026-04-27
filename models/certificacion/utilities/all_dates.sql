with dates as (

    -- generamos un rango de fechas de 2024 a 2026
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-01-01' as date)",
        end_date="cast('2026-12-31' as date)"
    ) }}

)

select
    date_day as date,
    to_char(date_day, 'YYYYMMDD')::int as date_key,
    extract(year from date_day) as year,
    extract(month from date_day) as month,
    to_char(date_day, 'Month') as month_name,
    extract(quarter from date_day) as quarter,
    extract(day from date_day) as day,
    to_char(date_day, 'DY') as weekday_name,
  case when extract(dayofweek from date_day) in (6,7) then true else false end as is_weekend
from dates