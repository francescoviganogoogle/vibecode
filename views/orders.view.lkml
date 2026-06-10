view: orders {
  sql_table_name: `lookerdemos.thelook_ecommerce_semgen.orders` ;;

  dimension: order_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.order_id ;;
    description: "A unique identifier for each order."
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
    description: "A unique identifier for the customer who placed the order."
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
    description: "The current status of the order."
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
    description: "The gender of the customer associated with the order."
  }

  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
    description: "The timestamp when the order was placed."
  }

  dimension_group: returned {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.returned_at ;;
    description: "The timestamp when the order was returned."
  }

  dimension_group: shipped {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.shipped_at ;;
    description: "The timestamp when the order was shipped."
  }

  dimension_group: delivered {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.delivered_at ;;
    description: "The timestamp when the order was delivered."
  }

  dimension: num_of_item {
    type: number
    sql: ${TABLE}.num_of_item ;;
    description: "The total number of items included in the order."
  }
}
