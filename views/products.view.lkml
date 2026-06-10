view: products {
  sql_table_name: `lookerdemos.thelook_ecommerce_semgen.products` ;;

  dimension: id {
    type: number
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.id ;;
    description: "This column contains a unique numerical identifier for each product."
  }

  dimension: category {
    type: string
    sql: ${TABLE}.category ;;
    description: "This column holds the product category, for example, Intimates or Jeans."
    drill_fields: [brand]
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
    description: "This column contains the full name of the product, such as Wigwam Men's Husky Sock."
  }

  dimension: brand {
    type: string
    sql: ${TABLE}.brand ;;
    description: "This column contains the brand name of the product, such as Allegra K or Calvin Klein."
    drill_fields: [name]
  }

  dimension: retail_price {
    type: number
    sql: ${TABLE}.retail_price ;;
    description: "This column contains the retail price of the product."
  }

  dimension: department {
    type: string
    sql: ${TABLE}.department ;;
    description: "This column specifies the department the product belongs to, such as Women or Men."
    drill_fields: [category]
  }

  dimension: sku {
    type: string
    hidden: yes
    sql: ${TABLE}.sku ;;
    description: "This column contains the Stock Keeping Unit (SKU) for the product, which is a unique alphanumeric identifier."
  }

  dimension: distribution_center_id {
    type: number
    hidden: yes
    sql: ${TABLE}.distribution_center_id ;;
    description: "This column contains a numerical identifier for the distribution center where the product is located."
  }

  set: product_hierarchy_drill {
    fields: [department, category, brand, name]
  }
}
