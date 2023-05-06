--data files loaded to SSMS: rebrickable.com/downloads
	-- data is updated daily



-- create main view to pull analytics queries from
create view analytics_main as 
select s.set_num, s.name as set_name, s.year, s.theme_id, cast(s.num_parts as numeric) num_parts, t.name as theme_name, t.parent_id, p.name as parent_theme_name
from sets s
left join themes t on s.theme_id = t.id
left join themes p on t.parent_id = p.id;



-- return the main view data
select * from analytics_main;



-- 1) return the number of parts by theme. Only include those that have a parent theme
select theme_name, sum(num_parts) as total_num_parts
from analytics_main
where parent_theme_name is not null
group by theme_name
order by 2 desc;



-- 2) return the number of parts by year. Only include those that have a parent theme
select year, sum(num_parts) as total_num_parts
from analytics_main
where parent_theme_name is not null
group by year
order by 2 desc;



-- 3) return the number of sets created by century. Only include those that have a parent theme
	--need to add Century column to the main view
ALTER view [dbo].[analytics_main] as 
select s.set_num, s.name as set_name, s.year, s.theme_id, cast(s.num_parts as numeric) num_parts, t.name as theme_name, t.parent_id, p.name as parent_theme_name,
case
	when s.year between 1901 and 2000 then '20th_Century'
	when s.year between 2001 and 2100 then '21st_Century'
end
as Century
from sets s
left join themes t on s.theme_id = t.id
left join themes p on t.parent_id = p.id
GO



-- 4) return the number of sets created by century. Only include those that have a parent theme
select Century, count(set_num) as total_set_num
from analytics_main
where parent_theme_name is not null
group by Century;



-- 5) of all sets released in the 21st century, what % of them had the trains theme?
	-- common table expression, window function, subquery, wildcard, aggregate function, decimal formatting

--create a column for the total number of sets across *all* themes for each century
;with cte as
(
	select Century, theme_name, count(set_num) total_set_num
	from analytics_main
	where Century = '21st_Century'
	group by Century, theme_name
)

--calculate %
select sum(total_set_num) train_set_num, sum(percentage) trains_theme_percentage
from(
	select Century, theme_name, total_set_num, sum(total_set_num) OVER() as total, cast(1.00 * total_set_num / sum(total_set_num) OVER() as decimal(5,4)) * 100 Percentage
	from cte
	)m
where theme_name like '%train%'  -- we want to count "train" and "trains" as the same theme, so we used "like"  



-- 6) return the most popular theme (in terms of sets released) by year in the 21st century
select year, theme_name, total_set_num
from (
	select year, theme_name, count(set_num) total_set_num, row_number() over(partition by year order by count(set_num) desc) rn
	from analytics_main
	where Century = '21st_Century'
		--and parent_theme_name is not null
	group by year, theme_name
)m
where rn = 1
order by year desc














