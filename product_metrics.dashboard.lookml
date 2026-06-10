- dashboard: product_metrics_analysis
  title: "Product Performance & Metrics"
  description: "Executive summary and deep-dive product analysis of key metrics, margins, returns, and hierarchical product drilling."
  preferred_viewer: dashboards-next
  layout: newspaper
  query_timezone: user_timezone
  crossfilter_enabled: true

  # Dashboard Tabs
  tabs:
    - name: overview
      label: "Executive Summary"
    - name: product_analysis
      label: "Product Hierarchy Analysis"

  # Dashboard Filters
  filters:
    - name: date_filter
      title: "Date Range"
      type: field_filter
      model: vibecode
      explore: order_items
      field: order_items.created_date
      default_value: "last 90 days"
      ui_config:
        type: relative_timeframes
        display: inline

    - name: department_filter
      title: "Department"
      type: field_filter
      model: vibecode
      explore: order_items
      field: products.department
      ui_config:
        type: button_toggles
        display: inline

    - name: category_filter
      title: "Category"
      type: field_filter
      model: vibecode
      explore: order_items
      field: products.category
      listens_to_filters: [department_filter]
      ui_config:
        type: tag_list
        display: popover

    - name: brand_filter
      title: "Brand"
      type: field_filter
      model: vibecode
      explore: order_items
      field: products.brand
      listens_to_filters: [department_filter, category_filter]
      ui_config:
        type: tag_list
        display: popover

    - name: gender_filter
      title: "Gender"
      type: field_filter
      model: vibecode
      explore: order_items
      field: users.gender
      ui_config:
        type: button_group
        display: inline

  elements:
    # ----------------------------------------------------
    # OVERVIEW TAB
    # ----------------------------------------------------

    # Header & Nav Tile
    - name: overview_header
      type: text
      tab_name: overview
      title_text: "<font color='#1A73E8' size='5' weight='bold'>Ecommerce Business Pulse :</font> <font color='#5F6368' size='5'>Overview</font>"
      body_text: |
        <div style="background-color: #f8f9fa; padding: 15px; border-left: 5px solid #1A73E8; border-radius: 4px; margin-bottom: 10px;">
          <p style="margin: 0; font-size: 14px; color: #3c4043; line-height: 1.5;">
            Welcome to the <strong>Product Metrics Dashboard</strong>. This dashboard highlights our executive metrics including total sales, order volume, return rates, and margins. 
            Use the <strong>Product Hierarchy Analysis</strong> tab to deep-dive into performance and drill down from <strong>Department → Category → Brand</strong>.
          </p>
        </div>
      row: 0
      col: 0
      width: 24
      height: 3

    # KPI 1: Gross Revenue
    - title: "Total Revenue"
      name: total_revenue_kpi
      model: vibecode
      explore: order_items
      type: single_value
      fields: [order_items.created_month, order_items.total_gross_revenue]
      fill_fields: [order_items.created_month]
      sorts: [order_items.created_month desc]
      limit: 2
      dynamic_fields:
        - table_calculation: vs_prior_month
          label: "vs Prior Month"
          expression: "${order_items.total_gross_revenue} / offset(${order_items.total_gross_revenue}, 1) - 1"
          value_format_name: percent_1
      show_comparison: true
      comparison_type: change
      comparison_label: "vs Prior Month"
      value_format_name: usd
      tab_name: overview
      row: 3
      col: 0
      width: 6
      height: 4
      listen:
        date_filter: order_items.created_date
        department_filter: products.department
        category_filter: products.category
        brand_filter: products.brand
        gender_filter: users.gender

    # KPI 2: Order Volume
    - title: "Order Volume"
      name: order_volume_kpi
      model: vibecode
      explore: order_items
      type: single_value
      fields: [order_items.created_month, order_items.count]
      fill_fields: [order_items.created_month]
      sorts: [order_items.created_month desc]
      limit: 2
      dynamic_fields:
        - table_calculation: vs_prior_month
          label: "vs Prior Month"
          expression: "${order_items.count} / offset(${order_items.count}, 1) - 1"
          value_format_name: percent_1
      show_comparison: true
      comparison_type: change
      comparison_label: "vs Prior Month"
      value_format_name: decimal_0
      tab_name: overview
      row: 3
      col: 6
      width: 6
      height: 4
      listen:
        date_filter: order_items.created_date
        department_filter: products.department
        category_filter: products.category
        brand_filter: products.brand
        gender_filter: users.gender

    # KPI 3: Gross Margin %
    - title: "Gross Margin %"
      name: gross_margin_kpi
      model: vibecode
      explore: order_items
      type: single_value
      fields: [order_items.gross_margin_percentage]
      value_format_name: percent_2
      tab_name: overview
      row: 3
      col: 12
      width: 6
      height: 4
      listen:
        date_filter: order_items.created_date
        department_filter: products.department
        category_filter: products.category
        brand_filter: products.brand
        gender_filter: users.gender

    # KPI 4: Return Rate
    - title: "Item Return Rate"
      name: return_rate_kpi
      model: vibecode
      explore: order_items
      type: single_value
      fields: [order_items.item_return_rate]
      value_format_name: percent_2
      comparison_reverse_colors: true
      tab_name: overview
      row: 3
      col: 18
      width: 6
      height: 4
      listen:
        date_filter: order_items.created_date
        department_filter: products.department
        category_filter: products.category
        brand_filter: products.brand
        gender_filter: users.gender

    # Chart 1: Revenue vs Order Volume Trend
    - title: "Revenue & Orders Trend"
      name: revenue_orders_trend
      model: vibecode
      explore: order_items
      type: looker_line
      fields: [order_items.created_date, order_items.total_gross_revenue, order_items.count]
      fill_fields: [order_items.created_date]
      sorts: [order_items.created_date]
      interpolation: monotone
      point_style: none
      show_view_names: false
      series_types:
        order_items.count: column
      series_colors:
        order_items.total_gross_revenue: "#1A73E8"
        order_items.count: "#81C995"
      series_labels:
        order_items.total_gross_revenue: "Gross Revenue"
        order_items.count: "Orders Count"
      y_axes:
        - label: "Total Revenue ($)"
          orientation: left
          series:
            - id: order_items.total_gross_revenue
              name: "Gross Revenue"
          value_format: "$#,##0"
        - label: "Orders Count"
          orientation: right
          series:
            - id: order_items.count
              name: "Orders Count"
          value_format: "#,##0"
      tab_name: overview
      row: 7
      col: 0
      width: 16
      height: 9
      listen:
        date_filter: order_items.created_date
        department_filter: products.department
        category_filter: products.category
        brand_filter: products.brand
        gender_filter: users.gender

    # Chart 2: Revenue Composition by Department
    - title: "Revenue Share by Department"
      name: revenue_dept_share
      model: vibecode
      explore: order_items
      type: looker_pie
      fields: [products.department, order_items.total_gross_revenue]
      sorts: [order_items.total_gross_revenue desc]
      inner_radius: 55
      show_view_names: false
      series_colors:
        Men: "#1A73E8"
        Women: "#F43F5E"
      tab_name: overview
      row: 7
      col: 16
      width: 8
      height: 9
      listen:
        date_filter: order_items.created_date
        department_filter: products.department
        category_filter: products.category
        brand_filter: products.brand
        gender_filter: users.gender


    # ----------------------------------------------------
    # PRODUCT HIERARCHY ANALYSIS TAB
    # ----------------------------------------------------

    # Header Tile for Product Analysis
    - name: product_header
      type: text
      tab_name: product_analysis
      title_text: "<font color='#1A73E8' size='5' weight='bold'>Product Performance :</font> <font color='#5F6368' size='5'>Hierarchy Breakdown</font>"
      body_text: |
        <div style="background-color: #f8f9fa; padding: 15px; border-left: 5px solid #1A73E8; border-radius: 4px; margin-bottom: 10px;">
          <p style="margin: 0; font-size: 14px; color: #3c4043; line-height: 1.5;">
            <strong>Drillable Hierarchy:</strong> The grid below lists our performance metrics grouped by 
            <strong>Department</strong>, <strong>Category</strong>, and <strong>Brand</strong>. 
            Clicking on any value in these columns allows you to drill down step-by-step or view specific products.
            Similarly, clicking on any measure value launches a detailed breakdown along the hierarchy.
          </p>
        </div>
      row: 0
      col: 0
      width: 24
      height: 3

    # Main Grid: Product Hierarchy Performance Grid
    - title: "Product Hierarchy Metrics"
      name: product_hierarchy_grid
      model: vibecode
      explore: order_items
      type: looker_grid
      fields: [
        products.department,
        products.category,
        products.brand,
        order_items.total_gross_revenue,
        order_items.count,
        order_items.gross_margin_percentage,
        order_items.item_return_rate
      ]
      sorts: [order_items.total_gross_revenue desc]
      show_totals: true
      show_view_names: false
      series_cell_visualizations:
        order_items.total_gross_revenue:
          is_active: true
          palette:
            palette_id: blue_gradient
            collection_id: google
        order_items.count:
          is_active: true
          palette:
            palette_id: green_gradient
            collection_id: google
      series_labels:
        order_items.total_gross_revenue: "Gross Revenue"
        order_items.count: "Orders Count"
        order_items.gross_margin_percentage: "Margin %"
        order_items.item_return_rate: "Return Rate"
      filters:
        products.department: "-NULL"
        products.category: "-NULL"
        products.brand: "-NULL"
      tab_name: product_analysis
      row: 3
      col: 0
      width: 24
      height: 11
      listen:
        date_filter: order_items.created_date
        department_filter: products.department
        category_filter: products.category
        brand_filter: products.brand
        gender_filter: users.gender

    # Chart 3: Top Categories
    - title: "Top 10 Categories by Revenue"
      name: top_categories_bar
      model: vibecode
      explore: order_items
      type: looker_bar
      fields: [products.category, order_items.total_gross_revenue]
      sorts: [order_items.total_gross_revenue desc]
      limit_displayed_rows: true
      limit_displayed_rows_values:
        show_hide: show
        first_last: first
        num_rows: 10
      show_view_names: false
      series_colors:
        order_items.total_gross_revenue: "#1A73E8"
      y_axes:
        - label: "Total Revenue ($)"
          orientation: bottom
          value_format: "$#,##0"
      filters:
        products.category: "-NULL"
      tab_name: product_analysis
      row: 14
      col: 0
      width: 12
      height: 8
      listen:
        date_filter: order_items.created_date
        department_filter: products.department
        category_filter: products.category
        brand_filter: products.brand
        gender_filter: users.gender

    # Chart 4: Top Brands
    - title: "Top 10 Brands by Revenue"
      name: top_brands_bar
      model: vibecode
      explore: order_items
      type: looker_bar
      fields: [products.brand, order_items.total_gross_revenue]
      sorts: [order_items.total_gross_revenue desc]
      limit_displayed_rows: true
      limit_displayed_rows_values:
        show_hide: show
        first_last: first
        num_rows: 10
      show_view_names: false
      series_colors:
        order_items.total_gross_revenue: "#34A853"
      y_axes:
        - label: "Total Revenue ($)"
          orientation: bottom
          value_format: "$#,##0"
      filters:
        products.brand: "-NULL"
      tab_name: product_analysis
      row: 14
      col: 12
      width: 12
      height: 8
      listen:
        date_filter: order_items.created_date
        department_filter: products.department
        category_filter: products.category
        brand_filter: products.brand
        gender_filter: users.gender
