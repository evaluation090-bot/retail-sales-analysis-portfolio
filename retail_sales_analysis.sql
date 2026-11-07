-- PostgreSQL examples. Import the cleaned CSV into a table named cleaned_sales.

-- Monthly revenue, orders, units, average order value, and month-over-month growth
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS sales_month,
        SUM(sales_amount) AS total_revenue,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(quantity) AS units_sold,
        SUM(sales_amount) / NULLIF(COUNT(DISTINCT order_id), 0) AS average_order_value
    FROM cleaned_sales
    GROUP BY 1
),
revenue_growth AS (
    SELECT
        *,
        LAG(total_revenue) OVER (ORDER BY sales_month) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    sales_month,
    total_revenue,
    total_orders,
    units_sold,
    ROUND(average_order_value::numeric, 2) AS average_order_value,
    previous_month_revenue,
    ROUND(
        100.0 * (total_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0), 2
    ) AS revenue_growth_pct
FROM revenue_growth
ORDER BY sales_month;

-- Top 10 products by revenue
SELECT
    product,
    category,
    SUM(sales_amount) AS total_revenue,
    SUM(quantity) AS units_sold,
    RANK() OVER (ORDER BY SUM(sales_amount) DESC) AS revenue_rank
FROM cleaned_sales
GROUP BY product, category
ORDER BY total_revenue DESC
LIMIT 10;

-- Regional performance
SELECT
    region,
    SUM(sales_amount) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        (SUM(sales_amount) / NULLIF(COUNT(DISTINCT order_id), 0))::numeric, 2
    ) AS average_order_value
FROM cleaned_sales
GROUP BY region
ORDER BY total_revenue DESC;

-- Category performance
SELECT
    category,
    SUM(sales_amount) AS total_revenue,
    SUM(quantity) AS units_sold
FROM cleaned_sales
GROUP BY category
ORDER BY total_revenue DESC;
