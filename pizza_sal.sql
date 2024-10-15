create database pizza;

use pizza ;

create table orders(
order_id int not null,
order_date date not null,
order_time time not null,
primary key(order_id));

create table orders_details(
order_details_id int not null,
order_id int not null,
pizza_id text not null,
quantity int not null,
primary key(order_details_id));

select * from pizza.orders;

select * from pizza.orders_details;

select * from pizza.pizza_types;

select * from pizza.pizzas;

-- 1.Retrieve the total number of orders placed --

SELECT 
    COUNT(order_id) AS total_number
FROM
    orders;

-- 2.calculate the total revenue generated from pizza sales--

SELECT 
    ROUND(SUM(orders_details.quantity * pizzas.price),
            2) AS total_revenue
FROM
    orders_details
        JOIN
    pizzas ON orders_details.pizza_id = pizzas.pizza_id;

-- 3.identify the highest priced pizza--

SELECT 
    pizza_types.name, pizzas.price
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY price DESC
LIMIT 1;

-- 4.identify the most common pizza size ordered --

SELECT 
    pizzas.size, COUNT(orders_details.order_details_id) AS count
FROM
    pizzas
        JOIN
    orders_details ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizzas.size
ORDER BY count DESC
LIMIT 1;

-- 5.list the top 5 most ordered pizza types along with their quantities--

SELECT 
    pizza_types.name,
    SUM(orders_details.quantity) AS order_details
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY order_details DESC
LIMIT 5;


-- join the neccesary tables to find the total quantity of each pizza category orderd--

SELECT 
    pizza_types.category,
    SUM(orders_details.quantity) AS total_quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY category
ORDER BY total_quantity DESC;

-- Determine the distribution of orders by hours of the day--

SELECT 
    HOUR(order_time) AS hours, COUNT(order_id)
FROM
    orders
GROUP BY hours;

-- join relevant tables to find the category wise distribution of pizzas --

SELECT 
    category, COUNT(name)
FROM
    pizza_types
GROUP BY category;

-- group the orders by date and calucate the avg number of pizzas ordered per day --

SELECT 
    AVG(total)
FROM
    (SELECT 
        orders.order_date, SUM(orders_details.quantity) AS total
    FROM
        orders
    JOIN orders_details ON orders.order_id = orders_details.order_id
    GROUP BY order_date) AS quantity_order;
    
-- determine the top 3 most ordered pizza types based on revenue--

with pizza_cte as (
select pizza_types.name,sum(orders_details.quantity*pizzas.price) as revenue
from pizza_types
join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join orders_details
on orders_details.pizza_id=pizzas.pizza_id
group by pizza_types.name
)
select * from pizza_cte
order by revenue desc
limit 3;

-- calaculate the percentage contribution of each pizza type to total revenue --

SELECT 
    pizza_types.category,
    round((SUM(orders_details.quantity * pizzas.price) / (SELECT 
            ROUND(SUM(orders_details.quantity * pizzas.price),
                        2) AS total_revenue
        FROM
            orders_details
                JOIN
            pizzas ON orders_details.pizza_id = pizzas.pizza_id) * 100),2) as revenue
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY revenue DESC;

-- analyse the cummulative revenue generated over time--

select order_date,
sum(revenue) over (order by order_date) as cum_revenue
from
(select orders.order_date, sum(orders_details.quantity*pizzas.price) as revenue
from orders_details
join pizzas
on orders_details.pizza_id=pizzas.pizza_id
join orders
on orders.order_id=orders_details.order_id
group by orders.order_date) as sales;

-- determine the top 3 most ordered pizaa type based on revenue for each pizza category--

select name,revenue,category 
from(
select category,name,revenue,
rank()over(partition by category order by revenue desc ) as rn
from
(select pizza_types.category,pizza_types.name, sum(orders_details.quantity*pizzas.price) as revenue
from pizza_types
join pizzas
on pizza_types.pizza_type_id=pizzas.pizza_type_id
join orders_details
on orders_details.pizza_id=pizzas.pizza_id
group by  pizza_types.category,pizza_types.name
) as a)as b
where rn<=3;
