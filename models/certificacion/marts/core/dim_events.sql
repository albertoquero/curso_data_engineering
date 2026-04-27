with 

tabla_staging as (

    select * from {{ ref('stg_sql_server_dbo_cert__events') }}

),

renamed as (

    select
        event_id,
        page_url,
        event_type,
        user_id,
        product_id,
        session_id,
        created_at,
        order_id,
        _fivetran_deleted,
        _fivetran_synced

    from tabla_staging

)

select * from renamed