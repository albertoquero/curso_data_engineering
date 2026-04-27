with 

tabla as (

    select * from {{ ref('all_dates') }}

),

renamed as (

    select
       *

    from tabla

)

select * from renamed