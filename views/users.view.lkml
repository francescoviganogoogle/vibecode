view: users {
  sql_table_name: `lookerdemos.thelook_ecommerce_semgen.users` ;;

  dimension: id {
    type: number
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.id ;;
    description: "This column contains a unique identifier for each user."
  }

  dimension: first_name {
    type: string
    sql: ${TABLE}.first_name ;;
    description: "This column holds the first name of the user."
  }

  dimension: last_name {
    type: string
    sql: ${TABLE}.last_name ;;
    description: "This column holds the last name of the user."
  }

  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
    description: "This column stores the email address of the user."
  }

  dimension: age {
    type: number
    sql: ${TABLE}.age ;;
    description: "This column contains the age of the user."
  }

  dimension: age_tier {
    type: tier
    tiers: [0, 18, 30, 60]
    style: integer
    sql: ${age} ;;
    description: "The age of the user, grouped into tiers: Under 0, 0-17, 18-29, 30-59, 60+."
  }

  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
    description: "This column specifies the gender of the user."
  }

  dimension: state {
    type: string
    sql: ${TABLE}.state ;;
    map_layer_name: us_states
    description: "This column indicates the state where the user resides."
  }

  dimension: street_address {
    type: string
    sql: ${TABLE}.street_address ;;
    description: "This column contains the street address of the user."
  }

  dimension: postal_code {
    type: string
    sql: ${TABLE}.postal_code ;;
    description: "This column stores the postal code of the user's address."
  }

  dimension: city {
    type: string
    sql: ${TABLE}.city ;;
    description: "This column indicates the city where the user resides."
  }

  dimension: country {
    type: string
    sql: ${TABLE}.country ;;
    map_layer_name: countries
    description: "This column specifies the country where the user resides."
  }

  dimension: latitude {
    type: number
    sql: ${TABLE}.latitude ;;
    description: "This column holds the geographical latitude coordinate of the user's location."
  }

  dimension: longitude {
    type: number
    sql: ${TABLE}.longitude ;;
    description: "This column holds the geographical longitude coordinate of the user's location."
  }

  dimension: traffic_source {
    type: string
    sql: ${TABLE}.traffic_source ;;
    description: "This column indicates the source through which the user arrived."
  }

  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
    description: "This column stores the timestamp when the user record was created."
  }

  dimension: user_geom {
    type: string
    sql: ${TABLE}.user_geom ;;
    description: "This column contains the geographical point representation of the user's location."
  }

  # User Metrics
  measure: count {
    type: count
    description: "Count of users (count distinct)"
  }
}
