view: distribution_centers {
  sql_table_name: `lookerdemos.thelook_ecommerce_semgen.distribution_centers` ;;

  dimension: id {
    type: number
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.id ;;
    description: "A unique identifier for each location."
  }

  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
    description: "The designated name of the location."
  }

  dimension: latitude {
    type: number
    sql: ${TABLE}.latitude ;;
    description: "The geographical latitude coordinate of the location."
  }

  dimension: longitude {
    type: number
    sql: ${TABLE}.longitude ;;
    description: "The geographical longitude coordinate of the location."
  }

  dimension: distribution_center_geom {
    type: string
    sql: ${TABLE}.distribution_center_geom ;;
    description: "The geographical representation of the location."
  }
}
