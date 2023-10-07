----CUSTOMER ANALYSIS----

----Loyal Customer Segmentation----

with  TB1 AS 
(
    select  c.company_name as company_name,
            c.country as country,
            count(distinct o.order_id) as order_count,
            round(sum(od.quantity*od.unit_price)::numeric,2) as total_sales
    from customers as c
    left join orders as o on c.customer_id = o.customer_id
    left join order_details as od on o.order_id = od.order_id
    where od.quantity is not null
    group by 1,2
    order by 2 desc
), customer_seg as  
(

    select  company_name,
            case WHEN total_sales >= 0 AND total_sales < 5000  THEN 1
                 WHEN total_sales >= 5000 AND total_sales < 10000  THEN 2
                 WHEN total_sales >= 10000 AND total_sales < 25000  THEN 3
                 WHEN total_sales >= 25000 AND total_sales < 35000  THEN 4
                 WHEN total_sales >= 35000  THEN 5 END AS m_point,

            case WHEN order_count >= 0 AND order_count < 5  THEN 1
                 WHEN order_count >= 5 AND order_count < 10  THEN 2
                 WHEN order_count >= 10 AND order_count < 15  THEN 3
                 WHEN order_count >= 15 AND order_count < 20  THEN 4
                 WHEN order_count >= 20  THEN 5 END AS f_point
            
    from TB1
)

select  t.company_name,
            t.order_count,
            t.total_sales,
            t.country,
            m.f_point,
            m.m_point     
from TB1 as t
left join customer_seg as m on t.company_name = m.company_name
order by 2 desc

----Repeating Customers----

select     customer_id,
        count(distinct order_id),
        case when (count(distinct order_id)) >1 then 'r' else 'n' end as repeated
from orders
group by customer_id
order by 2 desc

----SALES ANALYSIS----

----Top Selling Categories----

select    c.category_name,
        sum(od.quantity) as quantity
from orders as o
inner join order_details as od on o.order_id = od.order_id
inner join products as p on od.product_id = p.product_id
inner join categories as c on p.category_id = c.category_id
group by 1

----Top Selling Products----

select     p.product_name,
        sum(od.quantity) as units_sold
from orders as o
inner join order_details as od on o.order_id = od.order_id
inner join products as p on od.product_id = p.product_id
inner join categories as c on p.category_id = c.category_id
group by 1
order by 2 desc

----Top Revenue Generating Products----

select     p.product_name,
        round((sum(od.quantity * od.unit_price))::numeric,2) as total_sales
from orders as o
inner join order_details as od on o.order_id = od.order_id
inner join products as p on od.product_id = p.product_id
inner join categories as c on p.category_id = c.category_id
group by 1
order by 2 desc

----Top Selling Countries----

select    o.ship_country,
        sum(od.quantity) as quantity
from orders as o
inner join order_details as od on o.order_id = od.order_id
inner join products as p on od.product_id = p.product_id
inner join categories as c on p.category_id = c.category_id
group by 1
order by 2 desc

----COUNTRY (MARKET) BASED ANALYSIS----

select    c.country,
        count (distinct o.order_id) as order_count,
        sum(od.quantity ) as product_count,
        round((sum(od.quantity*od.unit_price))::numeric, 2) as total_sales,
        count(distinct c.customer_id) as customer_count,
        round((round((sum(od.quantity*od.unit_price))::numeric, 2)/(sum(od.quantity)))::numeric,2) as sales_per_product
from orders as o 
inner join customers as c on o.customer_id = c.customer_id
inner join order_details as od on o.order_id = od.order_id
inner join products as p on p.product_id = od. product_id
group by 1
order by 4 desc

----SUPPLIER ANALYSIS----

----Top Supplier Companies----
--(Based on the revenue they generated)--

select    s.company_name,
        count (distinct p.product_name) as product_count,
        round((sum(od.quantity*od.unit_price))::numeric,2) as total_sales
from suppliers as s 
inner join products as p on s.supplier_id = p.supplier_id
inner join categories as c on p.category_id = c.category_id
inner join order_details as od on od.product_id = p.product_id
inner join orders as o on od.order_id = o.order_id
group by 1 
order by 3 desc

----Supplier Counts by Countries----

select    s.country,
        count (distinct s.supplier_id) as supplier_count
from suppliers as s 
inner join products as p on s.supplier_id = p.supplier_id
inner join categories as c on p.category_id = c.category_id
inner join order_details as od on od.product_id = p.product_id
inner join orders as o on od.order_id = o.order_id
group by 1 order by 1 desc

----Supplier and Product Counts by Market (Country)----

with tb1 as 
(
select    s.country,
        s.company_name,
        count (distinct p.product_name) as product_count
from suppliers as s 
inner join products as p on s.supplier_id = p.supplier_id
inner join categories as c on p.category_id = c.category_id
inner join order_details as od on od.product_id = p.product_id
inner join orders as o on od.order_id = o.order_id
group by 1,2
), tb2 as 
(
select     s.country,
         count (distinct s.supplier_id) as supplier_count
from suppliers as s 
inner join products as p on s.supplier_id = p.supplier_id
inner join categories as c on p.category_id = c.category_id
inner join order_details as od on od.product_id = p.product_id
inner join orders as o on od.order_id = o.order_id
group by 1 order by 1 desc
) , tb3 as 
(
select  tt.country,
        tt.supplier_count,
        t.product_count
from tb1 as t inner join tb2 as tt on t.country=tt.country 
    )
select tb3.country,
    CASE
        WHEN country IN ('Australia', 'New Zealand') THEN 'Oceania'
        WHEN country IN ('Brazil', 'Argentina') THEN 'South America'
        WHEN country IN ('Canada', 'USA') THEN 'North America'
        WHEN country IN ('Denmark', 'Sweden', 'Norway', 'Finland', 'France', 'Spain', 'Italy', 'Germany', 'UK', 'Netherlands') THEN 'Europe'
        WHEN country IN ('Japan', 'Singapore') THEN 'Asia'
    END AS Region,
    count(tb3.supplier_count) as supplier_count,
    sum(tb3.product_count) as product_count
from tb3
group by 1

----SHIPPER ANALYSIS----

----Performance of Shippers to the Same Countries/Regions----

select CASE
        WHEN ship_country IN ('Australia', 'New Zealand') THEN 'Oceania'
        WHEN ship_country IN ('Brazil', 'Argentina','Mexico','Venezuela') THEN 'South America'
        WHEN ship_country IN ('Canada', 'USA') THEN 'North America'
        WHEN ship_country IN ('Denmark', 'Sweden', 'Norway', 'Austria','Poland','Portugal','Switzerland','Belgium','Ireland', 'Finland', 'France', 'Spain', 'Italy', 'Germany', 'UK', 'Netherlands') THEN 'Europe'
        WHEN ship_country IN ('Japan', 'Singapore') THEN 'Asia' end as Region,
        o.ship_country,
        s.company_name,
        count(distinct order_id) as order_count,
        round(avg(extract(day from (shipped_date - order_date) * interval '1 DAY'))::numeric,2) AS average_days_between_order_shipping
from orders as o 
inner join shippers as s on o.ship_via = s.shipper_id
group by 2,3

----Freight Costs by Companies to the Same Countries/Regions----

select CASE
        WHEN ship_country IN ('Australia', 'New Zealand') THEN 'Oceania'
        WHEN ship_country IN ('Brazil', 'Argentina','Mexico','Venezuela') THEN 'South America'
        WHEN ship_country IN ('Canada', 'USA') THEN 'North America'
        WHEN ship_country IN ('Denmark', 'Sweden', 'Norway', 'Austria','Poland','Portugal','Switzerland','Belgium','Ireland', 'Finland', 'France', 'Spain', 'Italy', 'Germany', 'UK', 'Netherlands') THEN 'Europe'
        WHEN ship_country IN ('Japan', 'Singapore') THEN 'Asia' end as Region,
        o.ship_country,
        s.company_name,
        round((avg(freight))::numeric,2) as freight
from orders as o 
inner join shippers as s on o.ship_via = s.shipper_id
group by 1,2,3
order by 1,2

----EMPLOYEE PERFORMANCE ANALYSIS----

----All-time Sales Performance----

select      concat(e.first_name, ' ', e.last_name) AS employee_full_name,
            e.hire_date,
            round((sum(od.quantity*od.unit_price))::numeric, 1) as total_sales
from employees as e 
left join orders as o on o.employee_id = e.employee_id
left join order_details as od on o.order_id = od.order_id
group by 1,2
order by 3 desc 
;

----Highest Single Sale by Employees----

with sales as 
(
select    concat(e.first_name, ' ', e.last_name) AS employee_full_name,
          o.order_id,
          round((sum(od.quantity*od.unit_price))::numeric, 1) as total_sales
from employees as e 
left join orders as o on o.employee_id = e.employee_id
left join order_details as od on o.order_id = od.order_id
group by 1,2
order by 3 desc 
)

select    employee_full_name,
          sales.total_sales
from sales
order by 2 desc
;
