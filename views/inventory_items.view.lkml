view: inventory_items {
  sql_table_name: `lookerdemos.thelook_ecommerce_semgen.inventory_items` ;;

  dimension: id {
    type: number
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.id ;;
  }

  dimension: product_id {
    type: number
    hidden: yes
    sql: ${TABLE}.product_id ;;
  }

  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: sold {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.sold_at ;;
  }

  dimension: cost {
    type: number
    sql: ${TABLE}.cost ;;
  }

  # Inventory measures
  measure: count {
    type: count
  }

  measure: total_cost {
    type: sum
    sql: ${cost} ;;
    value_format_name: usd
    description: "Total cost of items sold from inventory (sum of cost column in inventory_items) table"
  }

  measure: average_cost {
    type: average
    sql: ${cost} ;;
    value_format_name: usd
    description: "Average cost of an item in inventory"
  }
}
