create database olist_project;

use olist_project;


SELECT TOP 5 * FROM customers;
SELECT TOP 5 * FROM products;
SELECT TOP 5 * FROM orders;
SELECT TOP 5 * FROM order_items;
SELECT TOP 5 * FROM payments;



select o.customer_id from orders o 
left join customers c on o.customer_id = c.customer_id where c.customer_id is NULL;


alter table orders add constraint fk_customer_id foreign key (customer_id) references customers(customer_id);

select oi.order_id from order_items oi
left join orders o on oi.order_id = o.order_id where o.order_id is NULL;

alter table order_items add constraint fk_order_id foreign key (order_id) references orders(order_id);

select oi.product_id from order_items oi
left join products p on oi.product_id = p.product_id where p.product_id is NULL;

-- change prodcut id in order items to varchar(50)
alter table order_items alter column product_id varchar(50);

select product_id from order_items;

alter table order_items add constraint fk_product_id foreign key (product_id) references products(product_id);

select p.order_id from payments p
left join orders o on p.order_id = o.order_id where o.order_id is NULL;

alter table payments add constraint fk_payment_order_id foreign key (order_id) references orders(order_id);

GO

CREATE VIEW fact_sales AS 
select oi.order_id, oi.order_item_id, oi.price, (oi.price + oi.freight_value) as total_amount, oi.freight_value, o.order_purchase_timestamp,
o.order_status, pr.product_id, pr.product_category_name,c.customer_unique_id,c.customer_id, c.customer_city, c.customer_state
from order_items oi left join orders o on oi.order_id = o.order_id
left join products pr on oi.product_id = pr.product_id
left join customers c on o.customer_id = c.customer_id;
--add customer_unique_id to fact_sales


select * from fact_sales;

GO

CREATE VIEW dim_date AS
SELECT DISTINCT
    CAST(order_purchase_timestamp AS DATE) AS order_date,
    YEAR(order_purchase_timestamp) AS year,
    MONTH(order_purchase_timestamp) AS month,
    DATENAME(MONTH, order_purchase_timestamp) AS month_name,
    DATEPART(QUARTER, order_purchase_timestamp) AS quarter
FROM orders;

select * from dim_date order by order_date;

select * from fact_sales where customer_id like '1617b1357756262bfa56ab541c47bc16';

select * from fact_sales where price < 0 OR freight_value < 0;

GO

CREATE VIEW dim_customer_enriched AS
SELECT c.customer_unique_id,
MIN(o.order_purchase_timestamp) AS first_purchase_date,
COUNT(DISTINCT o.order_id) AS total_orders,
SUM(oi.price + oi.freight_value) AS lifetime_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_unique_id;

--sort by lifetime revenue
select * from dim_customer_enriched order by lifetime_revenue desc;


SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN total_orders = 1 THEN 1 ELSE 0 END) AS one_time_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) AS repeat_customers
FROM dim_customer_enriched;

GO

CREATE VIEW customer_value_segments AS
SELECT
    customer_unique_id,
    lifetime_revenue,
    NTILE(5) OVER (ORDER BY lifetime_revenue DESC) AS revenue_quintile
FROM dim_customer_enriched;
