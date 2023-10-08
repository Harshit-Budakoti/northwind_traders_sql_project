/* Which are the most commonly ordered products? */
select a."productID",b."productName" as Item_name,count(a."productID") as purchases 
from order_details as a join products as b 
on a."productID" = b."productID"
group by a."productID",Item_name
order by purchases desc;
/* TOP 5 most commonly ordered products */
select a."productID",b."productName" as Item_name,count(a."productID") as purchases 
from order_details as a join products as b 
on a."productID" = b."productID"
group by a."productID",Item_name
order by purchases desc limit 5;
/* TOP 5 least commonly ordered products */
select a."productID",b."productName" as Item_name,count(a."productID") as purchases 
from order_details as a join products as b 
on a."productID" = b."productID"
group by a."productID",Item_name
order by purchases asc limit 5;

/* Key Customers*/
select b."customerID" as customer_id,count(c."orderID") as total_orders_placed,
a."companyName" as name, sum( (c."unitPrice"*c."quantity")) as revenue , 
sum(b."freight") as freight ,
(sum( (c."unitPrice"*c."quantity"))-sum(b."freight")) as net_revenue

from customers as a JOIN orders as b on a."customerID" = b."customerID"
JOIN order_details as c on b."orderID" = c."orderID"
group by customer_id,Name
order by net_revenue desc;

/* Are shipping costs consistent across providers*/
select a."shipperID",b."companyName",sum(a."freight") as total_shipment_cost,
count(a."orderID") as count_orders, 
sum(a."freight") / count(a."orderID") as avg_shipment_cost  from orders as a 
JOIN 
shippers as b on a."shipperID" = b."shipperID" 
group by a."shipperID", b."companyName"
order by total_shipment_cost desc;

/* Product categories distributions */
select b."categoryName", count(b."categoryName") as total_product_items
from products as a  JOIN categories as b on a."categoryID"= b."categoryID"
group by b."categoryName"
order by count(b."categoryName") desc;

/* Costliest items category wise - Both continued and discontinued */
with t1 as (select b."categoryName",a."productName",rank() over (partition by b."categoryName" order by a."unitPrice" desc) as rank,a."unitPrice"
from products as a  JOIN categories as b on a."categoryID"= b."categoryID"
		   )

select t1."categoryName",t1."productName",t1."unitPrice" from  t1 where rank = 1 
;



/* Most expensive items which are not discontinued */
with t1 as (select b."categoryName",a."productName",rank() over (partition by b."categoryName" order by a."unitPrice" desc) as rank,a."unitPrice"
from products as a  JOIN categories as b on a."categoryID"= b."categoryID"
		   where a."discontinued"=0)

select t1."categoryName",t1."productName",t1."unitPrice" from  t1 where rank = 1 
;

/* Costliest Discontinued items in each category */ 
with t2 as (select b."categoryName",a."productName",rank() over ( partition by b."categoryName" order by a."unitPrice" desc  ) as rank,a."unitPrice"
from products as a  JOIN categories as b on a."categoryID"= b."categoryID"
		   where a."discontinued"=1)
select t2."categoryName" ,t2."productName",t2."unitPrice" from t2 where rank = 1 order by t2."unitPrice" desc;


/* Item wise revenue */ 
select a."productID",b."productName" as Item_name,
sum( (a."unitPrice"*a."quantity")) as revenue
from order_details as a join products as b 
on a."productID" = b."productID" 
group by a."productID",Item_name
order by revenue desc;

/* Item-wise biggest purchasing clients with their respective net_purchase_value */ 
with t3 as (select c."customerID",b."productName" as Item_name,
rank() over (partition by b."productName" order by sum( (a."unitPrice"*a."quantity")) desc)
,d."companyName",sum( (a."unitPrice"*a."quantity")) as rev
from order_details as a join products as b 
on a."productID" = b."productID"
join orders as c on a."orderID" = c."orderID"
join customers as d on c."customerID" = d."customerID"
group by c."customerID",Item_name,d."companyName"
)

select Item_name,t3."companyName" as biggest_purchaser ,t3."rev" as net_purchase_value
from t3 where rank =1
order by net_purchase_value desc;


/* Item-wise biggest purchasing countries with their respective net_purchase_value */ 
with t4 as (select d."country",b."productName" as Item_name,
rank() over (partition by b."productName" order by sum( (a."unitPrice"*a."quantity")) desc)
,sum( (a."unitPrice"*a."quantity")) as rev
from order_details as a join products as b 
on a."productID" = b."productID"
join orders as c on a."orderID" = c."orderID"
join customers as d on c."customerID" = d."customerID"
group by d."country",Item_name
)

select t4."item_name",t4."country" as biggest_purchaser_country ,t4."rev" as net_purchase_value
from t4 where rank =1
order by net_purchase_value desc;

/* Year wise Employees who bring in the most revenue  */
with t5 as (select date_part('year',b."orderDate") as year,a."employeeID",a."employeeName",a."title" as title,
sum( c."quantity"*c."unitPrice") as total_selling_value,
rank() over (partition by date_part('year',b."orderDate") order by 
			sum( c."quantity"*c."unitPrice") desc) as rnk
from employees as a JOIN orders as b on a."employeeID" = b."employeeID"
JOIN order_details as c on b."orderID" = c."orderID"
group by date_part('year',b."orderDate"),a."employeeID",a."employeeName"
order by total_selling_value desc)
select t5."year" as YEAR ,t5."employeeName" as emp_name,t5."title",
t5."total_selling_value" as annual_revenue from t5 where t5."rnk" = 1
order by YEAR;

/* Quarter wise Employees who bring in the most revenue  */
with tq as (select date_part('year',b."orderDate") as year, 
			date_part('quarter',b."orderDate") as quarter,
			a."employeeID",a."employeeName",a."title" as title,
sum( c."quantity"*c."unitPrice") as total_selling_value,
rank() over (partition by (date_part('year',b."orderDate"),date_part('quarter',b."orderDate"))
			 order by sum( c."quantity"*c."unitPrice") desc) as rnk
from employees as a JOIN orders as b on a."employeeID" = b."employeeID"
JOIN order_details as c on b."orderID" = c."orderID"
group by date_part('year',b."orderDate"),date_part('quarter',b."orderDate"),a."employeeID",a."employeeName"
order by total_selling_value desc)
select tq."year" as YEAR ,tq."quarter" as Quarter ,tq."employeeName" as emp_name,tq."title",
tq."total_selling_value" as annual_revenue from tq where tq."rnk" = 1
order by YEAR,Quarter;
/* City wise revenue generated Vs Top_grossing_client_city of employees by revenue */
select d."employeeID" as id,d."employeeName" as name,b."city" as city,sum( c."quantity"*c."unitPrice") as city_rev
,first_value(b."city") over (partition by d."employeeID" order by sum( c."quantity"*c."unitPrice") desc ) as top_city
from orders as a join customers as b on a."customerID"=b."customerID"
join order_details as c on a."orderID" = c."orderID" join employees as d on 
a."employeeID" = d."employeeID"
group by d."employeeID",d."employeeName",b."city"
order by city_rev desc

/* Top grossing city for each employee */
with emp_city as (select distinct d."employeeName" as name, b."city" as client_city,d."city" as employee_city,sum( c."quantity"*c."unitPrice") as city_rev,
				  b."country" as client_country
,rank() over (partition by d."employeeName" order by sum( c."quantity"*c."unitPrice") desc ) as rnk
from orders as a join customers as b on a."customerID"=b."customerID"
join order_details as c on a."orderID" = c."orderID" join employees as d on 
a."employeeID" = d."employeeID"
group by d."employeeName",b."city",d."city",b."country"
order by city_rev desc)
select name , employee_city, client_city,client_country,city_rev from emp_city where rnk =1
/* PIVOT TABLE: QUARTER WISE REVENUE */
with qt as (select date_part('year',a."orderDate")
					   as Year,date_part('quarter',a."orderDate") as Quarter,
					   sum( (b."unitPrice"*b."quantity"))as rev
					   from orders as a JOIN order_details as b on a."orderID" = b."orderID" 
					  group by Year,Quarter 
					  order by Year,Quarter)
				   
CREATE EXTENSION IF NOT EXISTS tablefunc;


select * from order_details;

/* created a temp table and populated it with qt data and inserted additional values */
insert into quarterly_trends
values (2013, 2,0.0),
(2013, 1,0.0),
(2015 ,3,0.0),
(2015,4,0.0)
RETURNING *;
insert into quarter_rev_pivot (
	select * from crosstab('select quarterly_trends."Year" , quarterly_trends."Quarter", quarterly_trends."rev" from quarterly_trends order by quarterly_trends."Year",quarterly_trends."Quarter"')
	as(year int, Q1 numeric,Q2 numeric, Q3 numeric, Q4 numeric )
	);

/* Quarterly data: Items generating most revenue with performance parameters */
with qt2 as(select date_part('year',c."orderDate")
					   as Year,date_part('quarter',c."orderDate") as quarter,b."productName" as product
			           ,sum( (a."unitPrice"*a."quantity")) as rev,
					   rank() over(partition by (date_part('year',c."orderDate"),date_part('quarter',c."orderDate"))order by sum( (a."unitPrice"*a."quantity")) desc ) as rnk,
			avg(c."requiredDate"-c."orderDate") as exp_lead_time ,avg(c."shippedDate"-c."orderDate") as act_lead_time,avg(freight) as avg_shipper_fees
					   from order_details as a join products as b on a."productID" = b."productID"
			           join orders as c on a."orderID" = c."orderID"
					  group by Year,quarter,b."productName"
					  order by Year,quarter
					  ),
	qt3 as (select date_part('year',c."orderDate")
					   as Year,date_part('quarter',c."orderDate") as quarter
			           ,sum( (a."unitPrice"*a."quantity")) as t_rev
		  from order_details as a join orders as c on a."orderID" = c."orderID" 
		  group by Year,quarter
		  order by Year,quarter)
					  
select  a.Year,concat('Quarter ',cast(a.quarter as text)) as Quarter,a.product,a.rev,round(a.exp_lead_time,2) as exp_lead_time, 
round(a.act_lead_time,2)as act_lead_time,round(a.avg_shipper_fees,2) as avg_shipper_fees ,concat(cast(round((100*a.rev)/b.t_rev,2)as text),'%') as share_of_Quarterly_revenue from qt2 as a join qt3 as b on (a.Year,a.quarter) = (b.Year,b.quarter)
 where a.rnk = 1 order by a.Year,a.quarter;
 
 
 
 /* Quarterly data: Items generating bottom 15% revenue with performance parameters */
with qt2 as(select date_part('year',c."orderDate")
					   as Year,date_part('quarter',c."orderDate") as quarter,b."productName" as product
			           ,sum( (a."unitPrice"*a."quantity")) as rev,
					   cume_dist() over(partition by (date_part('year',c."orderDate"),date_part('quarter',c."orderDate"))order by sum( (a."unitPrice"*a."quantity")) asc ) as cum_dist,
			avg(c."requiredDate"-c."orderDate") as exp_lead_time ,avg(c."shippedDate"-c."orderDate") as act_lead_time,avg(freight) as avg_shipper_fees
					   from order_details as a join products as b on a."productID" = b."productID"
			           join orders as c on a."orderID" = c."orderID"
					  group by Year,quarter,b."productName"
					  order by Year,quarter
					  ),
	qt3 as (select date_part('year',c."orderDate")
					   as Year,date_part('quarter',c."orderDate") as quarter
			           ,sum( (a."unitPrice"*a."quantity")) as t_rev
		  from order_details as a join orders as c on a."orderID" = c."orderID" 
		  group by Year,quarter
		  order by Year,quarter)
					  
select  a.Year,concat('Quarter ',cast(a.quarter as text)) as Quarter,a.product,a.rev,round(a.exp_lead_time,2) as exp_lead_time, 
round(a.act_lead_time,2)as act_lead_time,round(a.avg_shipper_fees,2) as avg_shipper_fees ,concat(cast(round((100*a.rev)/b.t_rev,2)as text),'%') as share_of_Quarterly_revenue,round(100*cast(a."cum_dist" as numeric),2)as quarterly_rev_percentile from qt2 as a join qt3 as b on (a.Year,a.quarter) = (b.Year,b.quarter)
 where round(100*cast(a."cum_dist" as numeric),2) <= 15 order by a.Year,a.quarter,a.cum_dist;
 
 /* Quarter-Year wrt Client-cities Top Shippers and total freight details*/ 
with q_c_shipment as (select concat(cast(date_part('year',a."orderDate") as text),' Quarter-',
			  cast(date_part('quarter',a."orderDate") as text)) as YY_MM
			  , b.city as Client_city, d."companyName" as Shippers,
			  sum( (c."unitPrice"*c."quantity")) as total_freight
			  ,rank() over (partition by (concat(cast(date_part('year',a."orderDate") as text),' Quarter-',
			  cast(date_part('quarter',a."orderDate") as text)),b.city) order by sum( (c."unitPrice"*c."quantity")) desc) as rank
			  
			  
			  from orders as a join customers as b on a."customerID" = b."customerID" join order_details as c
on a."orderID" = c."orderID" join shippers as d on d."shipperID" = a."shipperID"
group by YY_MM,Client_city,Shippers
order by YY_MM)
select YY_MM,Client_city,shippers,total_freight from q_c_shipment where rank =1

/* Quarter-Year wrt Client-countries Top Shippers and total freight details*/ 
with q_cntry_shipment as (select concat(cast(date_part('year',a."orderDate") as text),' Quarter-',
			  cast(date_part('quarter',a."orderDate") as text)) as YY_MM
			  , b.country as Client_country, d."companyName" as Shippers,
			  sum( (c."unitPrice"*c."quantity")) as total_freight,
						  d."shipperID" as shipper_code
			  ,rank() over (partition by (concat(cast(date_part('year',a."orderDate") as text),' Quarter-',
			  cast(date_part('quarter',a."orderDate") as text)),b.country) order by sum( (c."unitPrice"*c."quantity")) desc) as rank
			  
			  
			  from orders as a join customers as b on a."customerID" = b."customerID" join order_details as c
on a."orderID" = c."orderID" join shippers as d on d."shipperID" = a."shipperID"
group by YY_MM,Client_country,Shippers,shipper_code
order by YY_MM)
select YY_MM,Client_country,Shippers,shipper_code,total_freight from q_cntry_shipment where rank =1

