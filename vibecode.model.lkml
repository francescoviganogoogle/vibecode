connection: "ecommerce"

include: "/views/**/*.view.lkml"
include: "/*.dashboard"

explore: order_items {
  label: "Order Items (Ecommerce)"

  sql_always_where:
    {% if order_items.date_input._is_filtered %}
      ${order_items.created_date} >= ${order_items.parallel_period_start}
      AND ${order_items.created_date} < ${order_items.selected_period_end}
    {% else %}
      1=1
    {% endif %} ;;

  join: users {
    type: left_outer
    sql_on: ${order_items.user_id} = ${users.id} ;;
    relationship: many_to_one
  }

  join: orders {
    type: left_outer
    sql_on: ${order_items.order_id} = ${orders.order_id} ;;
    relationship: many_to_one
  }

  join: inventory_items {
    type: left_outer
    sql_on: ${order_items.inventory_item_id} = ${inventory_items.id} ;;
    relationship: many_to_one
  }

  join: products {
    type: left_outer
    sql_on: ${order_items.product_id} = ${products.id} ;;
    relationship: many_to_one
  }

  join: distribution_centers {
    type: left_outer
    sql_on: ${products.distribution_center_id} = ${distribution_centers.id} ;;
    relationship: many_to_one
  }
}

explore: events {
  label: "Events (Ecommerce)"

  join: users {
    type: left_outer
    sql_on: ${events.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
}
