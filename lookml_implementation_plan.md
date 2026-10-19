# LookML Implementation Plan: thelook_ecommerce_semgen Data Product

## 1. Executive Summary

This plan outlines the architecture, data modeling, view definitions, and explore configurations to build the LookML semantic layer for the **`thelook_ecommerce_semgen`** data product cataloged in Google Cloud Knowledge Catalog (Dataplex).

### Project Configuration
* **Project Name**: `vibecode`
* **Model Name**: `vibecode` (`models/vibecode.model.lkml`)
* **Connection**: `looker_demo_data_2`
* **Source BigQuery Dataset**: `lookerdemos.thelook_ecommerce_semgen`
* **Data Product Resource**: `projects/200733507790/locations/us/dataProducts/thelookecommerce`
* **Catalog Entry**: `projects/200733507790/locations/us/entryGroups/@dataplex/entries/projects/200733507790/locations/us/dataProducts/thelookecommerce`

---

## 2. Business Context & Domain Semantics

From the Knowledge Catalog documentation and data product overview for **Fashion.ly**:

* **Customer Lifecycle**:
  * An individual user's relationship begins upon website registration (`created_at` in `users`).
  * Registered users may place single or recurring orders over time.
* **Inventory Flow**:
  * Incoming merchandise is received at a warehouse facility and recorded with an inventory creation date (`created_at` in `inventory_items`).
  * When an order is placed, the physical unit is immediately earmarked as sold (`sold_at` in `inventory_items`) to synchronize available stock levels on the storefront.
* **Order Processing**:
  * Upon successful payment processing, the order record is created (`created_at` in `orders` and `order_items`).
  * Order items represent line items within an order; an order may contain one or multiple items, and a user may purchase multiple quantities of the same item.
* **Order Fulfillment Statuses**:
  * `Shipped`: In transit to customer.
  * `Complete`: Payment verified and delivered successfully.
  * `Processing`: Under fulfillment in warehouse.
  * `Cancelled`: Order terminated prior to shipment.
  * `Returned`: Item sent back by customer post-delivery.

---

## 3. Key Metrics & KPI Specifications

All formulas, filtering rules, and display formatting are taken directly from the Knowledge Catalog documentation:

| Metric Name | Calculation / Logic | Format | LookML Implementation |
| :--- | :--- | :--- | :--- |
| **Revenues** | Sum of sales price for completed order lines | Currency (`$#,##0.0`) | `type: sum`<br>`sql: ${sale_price} ;;`<br>`filters: [status: "Complete"]`<br>`value_format: "$#,##0.0"` |
| **Total Sale Price** | Total sales from items sold | USD (`$#,##0.00`) | `type: sum`<br>`sql: ${sale_price} ;;`<br>`value_format_name: usd` |
| **Average Sale Price** | Average sale price of an item sold | USD (`$#,##0.00`) | `type: average`<br>`sql: ${sale_price} ;;`<br>`value_format_name: usd` |
| **Cumulative Total Sales** | Running total of sales from items sold | USD (`$#,##0.00`) | `type: running_total`<br>`sql: ${total_sale_price} ;;`<br>`value_format_name: usd` |
| **Total Gross Revenue** | Total revenue from completed sales (excluding canceled or returned) | USD (`$#,##0.00`) | `type: sum`<br>`sql: ${sale_price} ;;`<br>`filters: [status: "-Cancelled, -Returned"]`<br>`value_format_name: usd` |
| **Total Cost** | Total cost of items sold from inventory | USD (`$#,##0.00`) | `type: sum`<br>`sql: ${inventory_items.cost} ;;`<br>`value_format_name: usd` |
| **Average Cost** | Average cost of an item in inventory | USD (`$#,##0.00`) | `type: average`<br>`sql: ${cost} ;;`<br>`value_format_name: usd` |
| **Margins / Total Gross Margin Amount** | Difference between total revenue from completed sales and cost of goods sold | USD (`$#,##0.00`) | `type: number`<br>`sql: ${total_gross_revenue} - ${inventory_items.total_cost} ;;`<br>`value_format_name: usd` |
| **Average Gross Margin** | Average gross margin per sold order item | USD (`$#,##0.00`) | `type: number`<br>`sql: 1.0 * ${total_gross_margin_amount} / NULLIF(${count}, 0) ;;`<br>`value_format_name: usd` |
| **Gross Margin %** | Total Gross Margin Amount / Total Gross Revenue | Percentage (`0.00%`) | `type: number`<br>`sql: 1.0 * ${total_gross_margin_amount} / NULLIF(${total_gross_revenue}, 0) ;;`<br>`value_format_name: percent_2` |
| **Number of Items Returned** | Items returned by dissatisfied customers | Integer | `type: count`<br>`filters: [status: "Returned"]` |
| **Item Return Rate** | Number of items returned / Total items sold | Percentage (`0.00%`) | `type: number`<br>`sql: 1.0 * ${number_of_items_returned} / NULLIF(${count}, 0) ;;`<br>`value_format_name: percent_2` |
| **Number of Customers Returning Items** | Distinct count of users with at least one return | Integer | `type: count_distinct`<br>`sql: ${user_id} ;;`<br>`filters: [status: "Returned"]` |
| **% of Users with Returns** | Customers returning items / Total registered customers | Percentage (`0.00%`) | `type: number`<br>`sql: 1.0 * ${count_returning_customers} / NULLIF(${users.count}, 0) ;;`<br>`value_format_name: percent_2` |
| **Average Spend per Customer** | Total Sale Price / Total registered customers | USD (`$#,##0.00`) | `type: number`<br>`sql: 1.0 * ${total_sale_price} / NULLIF(${users.count}, 0) ;;`<br>`value_format_name: usd` |
| **Count of Users** | Distinct count of customers | Integer | `type: count_distinct`<br>`sql: ${id} ;;` |

---

## 4. Entity Relationship Diagram & Joins

```
                      +-----------------------+
                      | distribution_centers  |
                      +-----------------------+
                                  ^
                                  | 1:N
                      +-----------------------+
                      |       products        |
                      +-----------------------+
                             ^         ^
                        1:N  |         | 1:N
                             |         |
+-------------------+        |    +-----------------------+
|  inventory_items  |        |    |      order_items      | (Fact)
+-------------------+        |    +-----------------------+
         ^                   |        |        |        |
         |                   +--------+        |        |
         | 1:1                                 |        |
         +-------------------------------------+        |
                                               | 1:N    | 1:N
                                               v        v
                                          +--------+ +-------+
                                          | orders | | users |
                                          +--------+ +-------+
                                                         ^
                                                         | 1:N
                                                    +--------+
                                                    | events |
                                                    +--------+
```

### Explores & Join Configurations

1. **`order_items` Explore (Primary Star/Snowflake Schema)**
   * **Base View**: `order_items`
   * **Label**: "Order Items & Sales Performance"
   * **Description**: "Primary sales explore combining line items with orders, products, inventory, users, and distribution centers."
   * **Joins**:
     * `orders`: `many_to_one` on `${order_items.order_id} = ${orders.order_id}`
     * `users`: `many_to_one` on `${order_items.user_id} = ${users.id}`
     * `products`: `many_to_one` on `${order_items.product_id} = ${products.id}`
     * `inventory_items`: `one_to_one` on `${order_items.inventory_item_id} = ${inventory_items.id}`
     * `distribution_centers`: `many_to_one` on `${products.distribution_center_id} = ${distribution_centers.id}`

2. **`orders` Explore (Order Lifecycle)**
   * **Base View**: `orders`
   * **Label**: "Orders & Fulfillment"
   * **Description**: "Order-level tracking of checkout, shipping, fulfillment, and customer ordering patterns."
   * **Joins**:
     * `users`: `many_to_one` on `${orders.user_id} = ${users.id}`

3. **`events` Explore (Customer Web Traffic & Behavioral Analytics)**
   * **Base View**: `events`
   * **Label**: "Web Events & Funnels"
   * **Description**: "User clickstream tracking, session progression, and attribution."
   * **Joins**:
     * `users`: `many_to_one` on `${events.user_id} = ${users.id}`

4. **`inventory_items` Explore (Supply Chain & Inventory Management)**
   * **Base View**: `inventory_items`
   * **Label**: "Inventory & Warehousing"
   * **Description**: "Stock levels, holding costs, and origin distribution facilities."
   * **Joins**:
     * `products`: `many_to_one` on `${inventory_items.product_id} = ${products.id}`
     * `distribution_centers`: `many_to_one` on `${products.distribution_center_id} = ${distribution_centers.id}`

---

## 5. File & Directory Layout

```
vibecode/
├── manifest.lkml
├── models/
│   └── vibecode.model.lkml
└── views/
    ├── distribution_centers.view.lkml
    ├── events.view.lkml
    ├── inventory_items.view.lkml
    ├── order_items.view.lkml
    ├── orders.view.lkml
    ├── products.view.lkml
    └── users.view.lkml
```

---

## 6. Detailed View Specifications

### View 1: `order_items.view.lkml`
* **Table Source**: `lookerdemos.thelook_ecommerce_semgen.order_items`
* **View Description**: "Line-item transactional data detailing each product purchased within an order, tracking its status, fulfillment dates, sale price, and associated inventory item."
* **Primary Key**: `id`
* **Dimensions**:
  * `id` (INTEGER): `primary_key: yes`, Label: "Order Item ID"
  * `order_id` (INTEGER): Label: "Order ID", Description: "Foreign key reference to the order."
  * `user_id` (INTEGER): Label: "User ID", Description: "Foreign key reference to the purchasing customer."
  * `product_id` (INTEGER): Label: "Product ID", Description: "Foreign key reference to the purchased product."
  * `inventory_item_id` (INTEGER): Label: "Inventory Item ID", Description: "Foreign key reference to the physical inventory unit in the warehouse."
  * `receiver_user_id` (INTEGER): Label: "Receiver User ID", Description: "Identifier for the recipient user if different from purchaser."
  * `status` (STRING): Label: "Status", Description: "Current fulfillment status (Complete, Cancelled, Returned, Shipped, Processing)."
  * `sale_price` (NUMBER): Label: "Sale Price", Description: "The sale price of the order item.", `value_format_name: usd`
  * `gross_margin` (NUMBER): Label: "Gross Margin", Description: "Difference between item sale price and inventory cost: ${sale_price} - ${inventory_items.cost}.", `value_format_name: usd`
  * `is_returned` (YESNO): Label: "Is Returned?", `sql: ${status} = 'Returned' ;;`
  * `is_completed` (YESNO): Label: "Is Completed?", `sql: ${status} = 'Complete' ;;`
* **Dimension Groups**:
  * `created`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "Timestamp when the order item was purchased."
  * `shipped`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "Timestamp when the order item was shipped."
  * `delivered`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "Timestamp when the order item was delivered."
  * `returned`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "Timestamp when the order item was returned."
* **Measures**:
  * `count`: `type: count`, Label: "Count of Order Items"
  * `total_sale_price`: `type: sum`, `sql: ${sale_price} ;;`, Label: "Total Sale Price", `value_format_name: usd`
  * `average_sale_price`: `type: average`, `sql: ${sale_price} ;;`, Label: "Average Sale Price", `value_format_name: usd`
  * `cumulative_total_sales`: `type: running_total`, `sql: ${total_sale_price} ;;`, Label: "Cumulative Total Sales", `value_format_name: usd`
  * `revenues`: `type: sum`, `sql: ${sale_price} ;;`, `filters: [status: "Complete"]`, Label: "Revenues", `value_format: "$#,##0.0"`
  * `total_gross_revenue`: `type: sum`, `sql: ${sale_price} ;;`, `filters: [status: "-Cancelled, -Returned"]`, Label: "Total Gross Revenue", `value_format_name: usd`
  * `total_gross_margin_amount`: `type: number`, `sql: ${total_gross_revenue} - ${inventory_items.total_cost} ;;`, Label: "Total Gross Margin Amount", `value_format_name: usd`
  * `average_gross_margin`: `type: number`, `sql: 1.0 * ${total_gross_margin_amount} / NULLIF(${count}, 0) ;;`, Label: "Average Gross Margin", `value_format_name: usd`
  * `gross_margin_pct`: `type: number`, `sql: 1.0 * ${total_gross_margin_amount} / NULLIF(${total_gross_revenue}, 0) ;;`, Label: "Gross Margin %", `value_format_name: percent_2`
  * `number_of_items_returned`: `type: count`, `filters: [status: "Returned"]`, Label: "Number of Items Returned"
  * `item_return_rate`: `type: number`, `sql: 1.0 * ${number_of_items_returned} / NULLIF(${count}, 0) ;;`, Label: "Item Return Rate", `value_format_name: percent_2`
  * `count_returning_customers`: `type: count_distinct`, `sql: ${user_id} ;;`, `filters: [status: "Returned"]`, Label: "Number of Customers Returning Items"
  * `pct_users_with_returns`: `type: number`, `sql: 1.0 * ${count_returning_customers} / NULLIF(${users.count}, 0) ;;`, Label: "% of Users with Returns", `value_format_name: percent_2`
  * `average_spend_per_customer`: `type: number`, `sql: 1.0 * ${total_sale_price} / NULLIF(${users.count}, 0) ;;`, Label: "Average Spend per Customer", `value_format_name: usd`

---

### View 2: `orders.view.lkml`
* **Table Source**: `lookerdemos.thelook_ecommerce_semgen.orders`
* **View Description**: "This table stores comprehensive information about customer orders. It tracks the lifecycle of each order from creation through delivery. The table supports analysis of order statuses, fulfillment times, and customer purchasing patterns. It provides a complete record of individual transactions."
* **Primary Key**: `order_id`
* **Dimensions**:
  * `order_id` (INTEGER): `primary_key: yes`, Label: "Order ID", Description: "A unique identifier for each order."
  * `user_id` (INTEGER): Label: "User ID", Description: "A unique identifier for the customer who placed the order."
  * `status` (STRING): Label: "Order Status", Description: "The current status of the order."
  * `gender` (STRING): Label: "Customer Gender", Description: "The gender of the customer associated with the order."
  * `num_of_item` (INTEGER): Label: "Number of Items", Description: "The total number of items included in the order."
* **Dimension Groups**:
  * `created`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "The timestamp when the order was placed."
  * `shipped`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "The timestamp when the order was shipped."
  * `delivered`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "The timestamp when the order was delivered."
  * `returned`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "The timestamp when the order was returned."
* **Measures**:
  * `count`: `type: count`, Label: "Count of Orders"
  * `count_distinct_users`: `type: count_distinct`, `sql: ${user_id} ;;`, Label: "Count of Ordering Customers"
  * `total_items_ordered`: `type: sum`, `sql: ${num_of_item} ;;`, Label: "Total Items Ordered"
  * `average_items_per_order`: `type: average`, `sql: ${num_of_item} ;;`, Label: "Average Items per Order", `value_format_name: decimal_1`

---

### View 3: `products.view.lkml`
* **Table Source**: `lookerdemos.thelook_ecommerce_semgen.products`
* **View Description**: "Master catalog of products, providing classification by department and category, pricing, brand metadata, and distribution center origins."
* **Primary Key**: `id`
* **Dimensions**:
  * `id` (INTEGER): `primary_key: yes`, Label: "Product ID", Description: "This column contains a unique numerical identifier for each product."
  * `name` (STRING): Label: "Product Name", Description: "This column contains the full name of the product, such as Wigwam Men's Husky Sock."
  * `brand` (STRING): Label: "Brand", Description: "This column contains the brand name of the product, such as Allegra K or Calvin Klein."
  * `category` (STRING): Label: "Category", Description: "This column holds the product category, for example, Intimates or Jeans."
  * `department` (STRING): Label: "Department", Description: "This column specifies the department the product belongs to, such as Women or Men."
  * `retail_price` (NUMBER): Label: "Retail Price", Description: "This column contains the retail price of the product.", `value_format_name: usd`
  * `sku` (STRING): Label: "SKU", Description: "This column contains the Stock Keeping Unit (SKU) for the product, which is a unique alphanumeric identifier."
  * `distribution_center_id` (INTEGER): Label: "Distribution Center ID", Description: "This column contains a numerical identifier for the distribution center where the product is located."
* **Measures**:
  * `count`: `type: count`, Label: "Count of Products"
  * `count_distinct_brands`: `type: count_distinct`, `sql: ${brand} ;;`, Label: "Count of Brands"
  * `count_distinct_categories`: `type: count_distinct`, `sql: ${category} ;;`, Label: "Count of Categories"
  * `average_retail_price`: `type: average`, `sql: ${retail_price} ;;`, Label: "Average Retail Price", `value_format_name: usd`

---

### View 4: `users.view.lkml`
* **Table Source**: `lookerdemos.thelook_ecommerce_semgen.users`
* **View Description**: "This table stores comprehensive information about individual users. It provides demographic details, contact information, and geographical coordinates for each user. This data supports analysis of user demographics, geographical distribution, and engagement patterns. It is a foundational dataset for understanding the customer base."
* **Primary Key**: `id`
* **Dimensions**:
  * `id` (INTEGER): `primary_key: yes`, Label: "User ID", Description: "This column contains a unique identifier for each user."
  * `first_name` (STRING): Label: "First Name", Description: "This column holds the first name of the user."
  * `last_name` (STRING): Label: "Last Name", Description: "This column holds the last name of the user."
  * `name` (STRING): Label: "Full Name", Description: "Full name of the user.", `sql: CONCAT(${first_name}, ' ', ${last_name}) ;;`
  * `email` (STRING): Label: "Email", Description: "This column stores the email address of the user."
  * `age` (INTEGER): Label: "Age", Description: "This column contains the age of the user."
  * `age_tier` (TIER): Label: "Age Tier", `type: tier`, `tiers: [0, 18, 25, 35, 50, 65]`, `style: integer`
  * `gender` (STRING): Label: "Gender", Description: "This column specifies the gender of the user."
  * `street_address` (STRING): Label: "Street Address", Description: "This column contains the street address of the user."
  * `city` (STRING): Label: "City", Description: "This column indicates the city where the user resides."
  * `state` (STRING): Label: "State", Description: "This column indicates the state where the user resides."
  * `postal_code` (STRING): Label: "Postal Code", Description: "This column stores the postal code of the user's address."
  * `country` (STRING): Label: "Country", Description: "This column specifies the country where the user resides."
  * `latitude` (FLOAT): Label: "Latitude", Description: "This column holds the geographical latitude coordinate of the user's location."
  * `longitude` (FLOAT): Label: "Longitude", Description: "This column holds the geographical longitude coordinate of the user's location."
  * `location` (LOCATION): Label: "User Coordinates", `type: location`, `sql_latitude: ${latitude} ;;`, `sql_longitude: ${longitude} ;;`
  * `traffic_source` (STRING): Label: "Traffic Source", Description: "This column indicates the source through which the user arrived."
* **Dimension Group**:
  * `created`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "This column stores the timestamp when the user record was created."
* **Measures**:
  * `count`: `type: count_distinct`, `sql: ${id} ;;`, Label: "Count of Users", Description: "Distinct count of registered users."
  * `average_age`: `type: average`, `sql: ${age} ;;`, Label: "Average Age", `value_format_name: decimal_1`

---

### View 5: `inventory_items.view.lkml`
* **Table Source**: `lookerdemos.thelook_ecommerce_semgen.inventory_items`
* **View Description**: "Detailed physical inventory tracking each individual stock unit from its entry into warehouse inventory through to its sale."
* **Primary Key**: `id`
* **Dimensions**:
  * `id` (INTEGER): `primary_key: yes`, Label: "Inventory Item ID", Description: "Unique identifier for each inventory unit."
  * `product_id` (INTEGER): Label: "Product ID", Description: "Foreign key reference linking inventory item to product catalog."
  * `cost` (NUMBER): Label: "Cost", Description: "Cost of the inventory item to the business.", `value_format_name: usd`
  * `is_sold` (YESNO): Label: "Is Sold?", `sql: ${sold_raw} IS NOT NULL ;;`
* **Dimension Groups**:
  * `created`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "Timestamp when item was entered into inventory."
  * `sold`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "Timestamp when item was marked as sold."
* **Measures**:
  * `count`: `type: count`, Label: "Count of Inventory Items"
  * `total_cost`: `type: sum`, `sql: ${cost} ;;`, Label: "Total Cost", Description: "Total cost of items sold from inventory.", `value_format_name: usd`
  * `average_cost`: `type: average`, `sql: ${cost} ;;`, Label: "Average Cost", Description: "Average cost of an item in inventory.", `value_format_name: usd`
  * `number_of_items_sold`: `type: count`, `filters: [is_sold: "yes"]`, Label: "Number of Items Sold"

---

### View 6: `distribution_centers.view.lkml`
* **Table Source**: `lookerdemos.thelook_ecommerce_semgen.distribution_centers`
* **View Description**: "This table stores information about various physical locations. It provides details necessary to identify and locate these facilities. The data supports geographical analysis and spatial queries related to these points of interest. It is used for understanding the distribution and placement of these sites."
* **Primary Key**: `id`
* **Dimensions**:
  * `id` (INTEGER): `primary_key: yes`, Label: "Distribution Center ID", Description: "A unique identifier for each location."
  * `name` (STRING): Label: "Distribution Center Name", Description: "The designated name of the location."
  * `latitude` (FLOAT): Label: "Latitude", Description: "The geographical latitude coordinate of the location."
  * `longitude` (FLOAT): Label: "Longitude", Description: "The geographical longitude coordinate of the location."
  * `location` (LOCATION): Label: "Distribution Center Location", `type: location`, `sql_latitude: ${latitude} ;;`, `sql_longitude: ${longitude} ;;`
* **Measures**:
  * `count`: `type: count`, Label: "Count of Distribution Centers"

---

### View 7: `events.view.lkml`
* **Table Source**: `lookerdemos.thelook_ecommerce_semgen.events`
* **View Description**: "This table captures user interaction data within an e-commerce platform. It records individual actions and associated contextual information. The data supports analysis of user behavior, session tracking, and event sequencing. It provides insights into customer journeys and platform usage patterns."
* **Primary Key**: `id`
* **Dimensions**:
  * `id` (INTEGER): `primary_key: yes`, Label: "Event ID", Description: "A unique identifier for each recorded event."
  * `user_id` (INTEGER): Label: "User ID", Description: "An identifier for the user performing the event."
  * `sequence_number` (INTEGER): Label: "Sequence Number", Description: "The order of events within a user's session."
  * `session_id` (STRING): Label: "Session ID", Description: "A unique identifier for a user's continuous interaction period."
  * `event_type` (STRING): Label: "Event Type", Description: "The classification or nature of the user's action."
  * `ip_address` (STRING): Label: "IP Address", Description: "The IP address from which the event originated."
  * `city` (STRING): Label: "City", Description: "The city where the event took place."
  * `state` (STRING): Label: "State", Description: "The state where the event took place."
  * `postal_code` (STRING): Label: "Postal Code", Description: "The postal code associated with the event's location."
  * `browser` (STRING): Label: "Browser", Description: "The web browser used by the user."
  * `traffic_source` (STRING): Label: "Traffic Source", Description: "The origin of the user's visit."
  * `uri` (STRING): Label: "URI", Description: "The specific resource or page accessed during the event."
* **Dimension Group**:
  * `created`: `type: time`, `timeframes: [raw, time, date, week, month, quarter, year]`, Description: "The timestamp when the event occurred."
* **Measures**:
  * `count`: `type: count`, Label: "Count of Events"
  * `unique_visitors`: `type: count_distinct`, `sql: ${user_id} ;;`, Label: "Unique Visitors"
  * `count_sessions`: `type: count_distinct`, `sql: ${session_id} ;;`, Label: "Count of Sessions"

---

## 7. Model Specification: `vibecode.model.lkml`

```lookml
connection: "looker_demo_data_2"

include: "/views/order_items.view.lkml"
include: "/views/orders.view.lkml"
include: "/views/products.view.lkml"
include: "/views/users.view.lkml"
include: "/views/inventory_items.view.lkml"
include: "/views/distribution_centers.view.lkml"
include: "/views/events.view.lkml"

# 1. Primary E-Commerce Sales Explore
explore: order_items {
  label: "Order Items & Sales Performance"
  description: "Primary sales explore combining line items with orders, products, inventory, users, and distribution centers."

  join: orders {
    type: left_outer
    relationship: many_to_one
    sql_on: ${order_items.order_id} = ${orders.order_id} ;;
  }

  join: users {
    type: left_outer
    relationship: many_to_one
    sql_on: ${order_items.user_id} = ${users.id} ;;
  }

  join: products {
    type: left_outer
    relationship: many_to_one
    sql_on: ${order_items.product_id} = ${products.id} ;;
  }

  join: inventory_items {
    type: left_outer
    relationship: one_to_one
    sql_on: ${order_items.inventory_item_id} = ${inventory_items.id} ;;
  }

  join: distribution_centers {
    type: left_outer
    relationship: many_to_one
    sql_on: ${products.distribution_center_id} = ${distribution_centers.id} ;;
  }
}

# 2. Orders & Customer Purchasing Behavior Explore
explore: orders {
  label: "Orders & Fulfillment"
  description: "Order-level tracking of checkout, shipping, fulfillment, and customer ordering patterns."

  join: users {
    type: left_outer
    relationship: many_to_one
    sql_on: ${orders.user_id} = ${users.id} ;;
  }
}

# 3. Web Events & Funnel Analytics Explore
explore: events {
  label: "Web Events & Funnels"
  description: "User clickstream tracking, session progression, and attribution."

  join: users {
    type: left_outer
    relationship: many_to_one
    sql_on: ${events.user_id} = ${users.id} ;;
  }
}

# 4. Inventory & Stock Explore
explore: inventory_items {
  label: "Inventory & Warehousing"
  description: "Stock levels, holding costs, and origin distribution facilities."

  join: products {
    type: left_outer
    relationship: many_to_one
    sql_on: ${inventory_items.product_id} = ${products.id} ;;
  }

  join: distribution_centers {
    type: left_outer
    relationship: many_to_one
    sql_on: ${products.distribution_center_id} = ${distribution_centers.id} ;;
  }
}
```

---

## 8. Implementation Steps & Validation Protocol

### Step 1: Initialize Project Directory Structure
1. Create `views/` and `models/` directories in the `vibecode` project.
2. Create or verify `manifest.lkml` with `project_name: "vibecode"`.

### Step 2: Author View Files
1. Create `views/distribution_centers.view.lkml`.
2. Create `views/products.view.lkml`.
3. Create `views/users.view.lkml`.
4. Create `views/inventory_items.view.lkml`.
5. Create `views/orders.view.lkml`.
6. Create `views/order_items.view.lkml` (including all business metrics from KC).
7. Create `views/events.view.lkml`.

### Step 3: Author Model File
1. Create `models/vibecode.model.lkml` referencing connection `looker_demo_data_2`.
2. Include granular view files.
3. Configure the 4 Explores (`order_items`, `orders`, `events`, `inventory_items`).

### Step 4: Verification & LookML Validation
1. Run `validate_project` via Looker MCP or LookML CLI to ensure zero syntax or reference errors.
2. Verify that every view has `primary_key: yes` on its designated primary key.
3. Verify that all measures reference dimensions (`${dimension_name}`) and not `${TABLE}.col`.
4. Test analytical queries using the Looker MCP `query` or `query_sql` tool to confirm generated BigQuery SQL matches expected results:
   * Query 1: Revenues and Gross Margin % by product category.
   * Query 2: Customer return rate and % of users with returns.
   * Query 3: Average delivery time by distribution center.
