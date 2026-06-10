view: order_items {
  sql_table_name: `lookerdemos.thelook_ecommerce_semgen.order_items` ;;

  dimension: id {
    type: number
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.id ;;
  }

  dimension: order_id {
    type: number
    hidden: yes
    sql: ${TABLE}.order_id ;;
  }

  dimension: user_id {
    type: number
    hidden: yes
    sql: ${TABLE}.user_id ;;
  }

  dimension: product_id {
    type: number
    hidden: yes
    sql: ${TABLE}.product_id ;;
  }

  dimension: inventory_item_id {
    type: number
    hidden: yes
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
    hidden: yes
    sql: ${TABLE}.receiver_user_id ;;
  }

  # Measures based on key metrics
  measure: count {
    type: count
    drill_fields: [products.product_hierarchy_drill*]
  }

  measure: total_sale_price {
    type: sum
    sql: ${sale_price} ;;
    value_format_name: usd
    description: "Total sales from items sold (sum of sale_price column in order_items table)"
    drill_fields: [products.product_hierarchy_drill*]
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
    drill_fields: [products.product_hierarchy_drill*]
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
    drill_fields: [products.product_hierarchy_drill*]
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

  # =========================================================================
  # PERIOD-OVER-PERIOD (PoP) FIELDS
  # =========================================================================

  filter: date_input {
    type: date
    description: "Select the date range for the current period to compare against the parallel previous period"
  }

  dimension: selected_period_start {
    type: date
    hidden: yes
    sql: 
      {% if date_input._is_filtered %}
        DATE({% date_start date_input %})
      {% else %}
        NULL
      {% endif %} ;;
  }

  dimension: selected_period_end {
    type: date
    hidden: yes
    sql: 
      {% if date_input._is_filtered %}
        DATE({% date_end date_input %})
      {% else %}
        NULL
      {% endif %} ;;
  }

  dimension: selected_period_length {
    type: number
    hidden: yes
    sql: 
      {% if date_input._is_filtered %}
        DATE_DIFF(DATE({% date_end date_input %}), DATE({% date_start date_input %}), DAY)
      {% else %}
        NULL
      {% endif %} ;;
  }

  dimension: parallel_period_start {
    type: date
    hidden: yes
    sql: 
      {% if date_input._is_filtered %}
        DATE_SUB(DATE({% date_start date_input %}), INTERVAL ${selected_period_length} DAY)
      {% else %}
        NULL
      {% endif %} ;;
  }

  dimension: parallel_period_end {
    type: date
    hidden: yes
    sql: 
      {% if date_input._is_filtered %}
        DATE({% date_start date_input %})
      {% else %}
        NULL
      {% endif %} ;;
  }

  dimension: period {
    type: string
    description: "Categorizes transactions into 'Current', 'Previous' (parallel), or 'Other' based on date_input"
    sql:
      {% if date_input._is_filtered %}
        CASE
          WHEN ${created_date} >= ${selected_period_start} AND ${created_date} < ${selected_period_end} THEN 'Current'
          WHEN ${created_date} >= ${parallel_period_start} AND ${created_date} < ${parallel_period_end} THEN 'Previous'
          ELSE 'Other'
        END
      {% else %}
        'No Filter Selected'
      {% endif %} ;;
  }

  dimension: days_from_start {
    type: number
    description: "Index day from the start of the period (0, 1, 2, ...). Ideal for comparing period trends."
    sql:
      {% if date_input._is_filtered %}
        CASE
          WHEN ${period} = 'Current' THEN DATE_DIFF(${created_date}, ${selected_period_start}, DAY)
          WHEN ${period} = 'Previous' THEN DATE_DIFF(${created_date}, ${parallel_period_start}, DAY)
          ELSE NULL
        END
      {% else %}
        NULL
      {% endif %} ;;
  }

  dimension: aligned_date {
    type: date
    description: "Aligns previous period's transaction dates with current period's dates on a single timeline."
    sql:
      {% if date_input._is_filtered %}
        CASE
          WHEN ${period} = 'Current' THEN ${created_date}
          WHEN ${period} = 'Previous' THEN DATE_ADD(${created_date}, INTERVAL ${selected_period_length} DAY)
          ELSE NULL
        END
      {% else %}
        NULL
      {% endif %} ;;
  }

  # -------------------------------------------------------------------------
  # POP MEASURES
  # -------------------------------------------------------------------------

  measure: current_period_sales {
    type: sum
    sql: ${sale_price} ;;
    filters: [period: "Current"]
    value_format_name: usd
    description: "Total sales in the user-selected current period."
  }

  measure: previous_period_sales {
    type: sum
    sql: ${sale_price} ;;
    filters: [period: "Previous"]
    value_format_name: usd
    description: "Total sales in the dynamically-computed parallel previous period."
  }

  measure: sales_absolute_difference {
    type: number
    sql: ${current_period_sales} - ${previous_period_sales} ;;
    value_format_name: usd
    description: "Absolute difference in sales: Current Sales - Previous Sales"
  }

  measure: sales_percentage_difference {
    type: number
    sql: (${current_period_sales} - ${previous_period_sales}) / NULLIF(${previous_period_sales}, 0) ;;
    value_format_name: percent_2
    description: "Percentage variance in sales from previous period to current period."
  }
}

