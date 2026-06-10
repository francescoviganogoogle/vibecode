view: events {
  sql_table_name: `lookerdemos.thelook_ecommerce_semgen.events` ;;

  dimension: id {
    type: number
    primary_key: yes
    hidden: yes
    sql: ${TABLE}.id ;;
    description: "A unique identifier for each recorded event."
  }

  dimension: user_id {
    type: number
    hidden: yes
    sql: ${TABLE}.user_id ;;
    description: "An identifier for the user performing the event."
  }

  dimension: sequence_number {
    type: number
    sql: ${TABLE}.sequence_number ;;
    description: "The order of events within a user's session."
  }

  dimension: session_id {
    type: string
    hidden: yes
    sql: ${TABLE}.session_id ;;
    description: "A unique identifier for a user's continuous interaction period."
  }

  dimension_group: created {
    type: time
    timeframes: [raw, time, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
    description: "The timestamp when the event occurred."
  }

  dimension: ip_address {
    type: string
    sql: ${TABLE}.ip_address ;;
    description: "The IP address from which the event originated."
  }

  dimension: city {
    type: string
    sql: ${TABLE}.city ;;
    description: "The city where the event took place."
  }

  dimension: state {
    type: string
    sql: ${TABLE}.state ;;
    map_layer_name: us_states
    description: "The state where the event took place."
  }

  dimension: postal_code {
    type: string
    sql: ${TABLE}.postal_code ;;
    description: "The postal code associated with the event's location."
  }

  dimension: browser {
    type: string
    sql: ${TABLE}.browser ;;
    description: "The web browser used by the user."
  }

  dimension: traffic_source {
    type: string
    sql: ${TABLE}.traffic_source ;;
    description: "The origin of the user's visit."
  }

  dimension: uri {
    type: string
    sql: ${TABLE}.uri ;;
    description: "The specific resource or page accessed during the event."
  }

  dimension: event_type {
    type: string
    sql: ${TABLE}.event_type ;;
    description: "The classification or nature of the user's action."
  }
}
