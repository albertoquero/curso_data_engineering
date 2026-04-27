with
source as (
    SELECT * FROM {{ source('google_sheets_cert','source_budget') }}
),
renamed as (
    select * from source
)
select * from renamed