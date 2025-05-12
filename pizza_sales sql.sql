CREATE TABLE pizzas
(
pizza_id VARCHAR(20) PRIMARY KEY,
pizza_type_id VARCHAR(20),
size VARCHAR(5),
price FLOAT
);

DROP TABLE IF EXISTS pizza_type;

CREATE TABLE pizza_type (
    pizza_type_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50),	
    category VARCHAR(15),	
    ingredients VARCHAR(150)
);


DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
 order_id INT Primary key,
 date DATE,
 time TIME
 );


DROP TABLE IF EXISTS orders_details;
 CREATE TABLE orders_details
 (
 order_details_id INT PRIMARY KEY,
 order_id INT,
 pizza_id VARCHAR(50),
 quantity INT,
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
  );
  
SELECT * FROM pizzas;
SELECT * FROM pizza_type;
SELECT * FROM orders;

SELECT * FROM orders_details;

-- Data Anlysis
1. Retrieve the total number of orders placed.
SELECT 
COUNT(order_id) as number_of_orders 
FROM orders;

2.Calculate the total revenue generated from pizza sales.

SELECT 
ROUND(SUM(p.price *o.quantity)::NUMERIC,2) As total_sales
from pizzas AS p 
JOIN orders_details as o
ON o.pizza_id = p.pizza_id

3. Identify the highest-priced pizza.

SELECT 
pizza_id,
MAX(price) AS higest_price
FROM pizzas
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

4.Identify the most common pizza size ordered.
  SELECT 
  p.size,
  count(o.order_details_id)
  FROM pizzas AS p
  JOIN orders_details AS o
  ON p.pizza_id = o.pizza_id
  GROUP BY 1
  ORDER BY 2 DESC;

 5. List the top 5 most ordered pizza types along with their quantities.
SELECT 
pz.name,
SUM(o.quantity)
FROM pizza_type As pz
JOIN pizzas As p
ON p.pizza_type_id = pz.pizza_type_id
JOIN orders_details As o
ON o.pizza_id = p.pizza_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

6. Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT 
pt.category,
SUM(quantity) AS total_quantity
FROM pizza_type as pt
JOIN pizzas as p
ON p.pizza_type_id = pt.pizza_type_id
JOIN orders_details as o
ON o.pizza_id = p.pizza_id
GROUP BY
category
ORDER BY total_quantity DESC;


7.Determine the distribution of orders by hour of the day.
SELECT 
COUNT(DISTINCT o.order_id) AS total_orders,
EXTRACT(hour from o.time) AS orders_hour
FROM orders as o
JOIN orders_details As od
ON od.order_id = o.order_id
GROUP BY 2
ORDER BY 1 DESC;


8. Join relevant tables to find the category-wise distribution of pizzas.
SELECT
category,
COUNT(DISTINCT pizza_type_id ) AS distribution_of_pizzas
FROM pizza_type
GROUP BY 1
ORDER BY 2 DESC;

9. Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT 
	ROUND(AVG(number_of_pizzas),0) AS avg_pizzas_per_day
from 
    (SELECT 
     SUM(od.quantity) AS number_of_pizzas,
      o.date
FROM 
	orders as o
JOIN 
	orders_details As od
ON
	od.order_id = o.order_id
GROUP BY 2) as order_quantity;


10. Determine the top 3 most ordered pizza types based on revenue.
SELECT
pt.name,
SUM(p.price * od. quantity) As revnue
FROM 
orders_details AS od
JOIN pizzas as p 
ON p.pizza_id = od.pizza_id
JOIN pizza_type as pt
ON pt.pizza_type_id = p.pizza_type_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

11. Calculate the percentage contribution of each pizza type to total revenue.

SELECT 
  pt.category AS pizza_category,
  SUM(p.price * od.quantity) AS revenue,
  ROUND(
    (SUM(p.price * od.quantity) * 100.0 / 
     SUM(SUM(p.price * od.quantity)) OVER ())::NUMERIC, 
    2
  ) AS percentage_contribution
FROM orders_details AS od
JOIN pizzas AS p
  ON od.pizza_id = p.pizza_id
JOIN pizza_type AS pt
  ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY revenue DESC;

12.-- Analyze the cumulative revenue generated over time.
SELECT 
  date,
  pizza_name,
  daily_revenue,
  SUM(daily_revenue) OVER (
    PARTITION BY pizza_name
    ORDER BY date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_revenue
FROM (
  SELECT
    o.date,
    pt.name AS pizza_name,
    SUM(p.price * od.quantity) AS daily_revenue
  FROM orders_details AS od
  JOIN pizzas AS p 
    ON p.pizza_id = od.pizza_id
  JOIN pizza_type AS pt
    ON pt.pizza_type_id = p.pizza_type_id
  JOIN orders AS o
    ON o.order_id = od.order_id
  GROUP BY o.date, pt.name
) AS daily_data
ORDER BY pizza_name, date;


13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.

WITH ranked_pizzas AS (
  SELECT
    pt.name AS pizza_name,
    pt.category,
    SUM(p.price * od.quantity) AS revenue,
    RANK() OVER (
      PARTITION BY pt.category 
      ORDER BY SUM(p.price * od.quantity) DESC
    ) AS rank
  FROM orders_details AS od
  JOIN pizzas AS p 
    ON p.pizza_id = od.pizza_id
  JOIN pizza_type AS pt
    ON pt.pizza_type_id = p.pizza_type_id
  GROUP BY pt.name, pt.category
)

SELECT *
FROM ranked_pizzas
WHERE rank <= 3
ORDER BY category, rank DESC;
