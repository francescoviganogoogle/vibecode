view: order_items {
  sql_table_name: `lookerdemos.thelook_ecommerce_semgen.order_items` ;;

  dimension: id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }

  dimension: order_id {
    type: number
    sql: ${TABLE}.order_id ;;
  }

  dimension: user_id {
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: product_id {
    type: number
    sql: ${TABLE}.product_id ;;
  }

  dimension: inventory_item_id {
    type: number
    sql: ${TABLE}.inventory_item_id ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }

  dimension_group: shipped {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.shipped_at ;;
  }

  dimension_group: delivered {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.delivered_at ;;
  }

  dimension_group: returned {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.returned_at ;;
  }

  dimension: sale_price {
    type: number
    sql: ${TABLE}.sale_price ;;
  }

  dimension: receiver_user_id {
    type: number
    sql: ${TABLE}.receiver_user_id ;;
  }

  # Measures based on key metrics
  measure: count {
    type: count
  }

  measure: total_sale_price {
    type: sum
    sql: ${sale_price} ;;
    value_format_name: usd
    description: "Total sales from items sold (sum of sale_price column in order_items table)"
  }

  measure: average_sale_price {
    type: average
    sql: ${sale_price} ;;
    value_format_name: usd
    description: "Average sale price of an item sold"
  }

  measure: cumulative_total_sales {
    type: running_total
    sql: ${total_sale_price} ;;
    value_format_name: usd
    description: "Cumulative total sales from items sold (also known as a running total)"
  }

  measure: total_gross_revenue {
    type: sum
    sql: ${sale_price} ;;
    filters: [status: "-canceled,-returned"]
    value_format_name: usd
    description: "Total revenue from completed sales (order_items.status = canceled or returned excluded)"
  }

  measure: number_of_items_returned {
    type: count
    filters: [status: "returned"]
    description: "Number of items that were returned by dissatisfied customers (order_items.status = returned)"
  }

  measure: item_return_rate {
    type: number
    sql: 1.0 * ${number_of_items_returned} / NULLIF(${count}, 0) ;;
    value_format_name: percent_2
    description: "Number of Items Returned / total number of items sold"
  }

  # Cross-view Margin Measures (using order_items and inventory_items)
  measure: total_gross_margin_amount {
    type: number
    sql: ${total_gross_revenue} - ${inventory_items.total_cost} ;;
    value_format_name: usd
    description: "Total difference between the total revenue from completed sales and the cost of the goods that were sold"
  }

  measure: average_gross_margin {
    type: number
    sql: 1.0 * ${total_gross_margin_amount} / NULLIF(${count}, 0) ;;
    value_format_name: usd
    description: "Average difference between the total revenue from completed sales and the cost of the goods that were sold"
  }

  measure: gross_margin_percentage {
    type: number
    sql: 1.0 * ${total_gross_margin_amount} / NULLIF(${total_gross_revenue}, 0) ;;
    value_format_name: percent_2
    description: "Total Gross Margin Amount / Total Gross Revenue"
  }

  measure: number_of_customers_returning_items {
    type: count_distinct
    sql: ${user_id} ;;
    filters: [status: "returned"]
    description: "Number of users who have returned an item at some point"
  }

  measure: percent_of_users_with_returns {
    type: number
    sql: 1.0 * ${number_of_customers_returning_items} / NULLIF(${users.count}, 0) ;;
    value_format_name: percent_2
    description: "Number of Customer Returning Items / total number of customers"
  }

  measure: average_spend_per_customer {
    type: number
    sql: 1.0 * ${total_sale_price} / NULLIF(${users.count}, 0) ;;
    value_format_name: usd
    description: "Total Sale Price / total number of customers"
  }
}
