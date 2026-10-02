--Get a feel for the data
Select * from characters
limit 20;

--# of entries
select count(*)
from characters;

--Q1. How popular is each class to start with?
select rank() over(order by count(class_starting) desc) as class_rank,
	class_starting, count(class_starting) as number_of_players

from characters

group by class_starting
order by class_rank;

--Q2. What are the top 3 subclasses for each class?
with subclass_counts as (
	select class_starting, subclass_starting, count(class_starting) as total_players,
		row_number() over(partition by class_starting order by count(class_starting) desc) as class_rank
	from characters
	where subclass_starting is not Null
	group by class_starting, subclass_starting
)
select * from subclass_counts
where class_rank < 4;

--Q3. What is the median health for each level?
with ranked as (
	select total_level, base_hp, row_number() over (partition by total_level order by base_hp) as r,
	count(base_hp) over(partition by total_level) as c
from characters
)
select total_level as "Level", base_hp as "HP"
from ranked
where r in (floor((c+1)/2), ceiling((c+1)/2));

--Q4. Which stats are the most common to 'dump' or give the least value to?
select 
	round(100.0 * sum(case when least(strength, dexterity, constitution, intelligence, wisdom, charisma) = strength
	then 1 else 0 end)/count(*),2) as "Times Strength Dumped",
	round(100.0 * sum(case when least(strength, dexterity, constitution, intelligence, wisdom, charisma) = dexterity
	then 1 else 0 end)/count(*),2) as "Times Dexterity Dumped",
	round(100.0 * sum(case when least(strength, dexterity, constitution, intelligence, wisdom, charisma) = constitution
	then 1 else 0 end)/count(*),2) as "Times Constitution Dumped",
	round(100.0 * sum(case when least(strength, dexterity, constitution, intelligence, wisdom, charisma) = intelligence
	then 1 else 0 end)/count(*),2) as "Times Intelligence Dumped",
	round(100.0 * sum(case when least(strength, dexterity, constitution, intelligence, wisdom, charisma) = wisdom
	then 1 else 0 end)/count(*),2) as "Times Wisdom Dumped",
	round(100.0 * sum(case when least(strength, dexterity, constitution, intelligence, wisdom, charisma) = charisma
	then 1 else 0 end)/count(*),2) as "Times Charisma Dumped"
from characters

where not (strength = dexterity and strength = constitution and strength = intelligence and strength = wisdom
	and strength = charisma);

--Q5. Which stats are most highly valued?
select 
	round(100.0 * sum(case when greatest(strength, dexterity, constitution, intelligence, wisdom, charisma) = strength
	then 1 else 0 end)/count(*),2) as "Times Strength Prioritized",
	round(100.0 * sum(case when greatest(strength, dexterity, constitution, intelligence, wisdom, charisma) = dexterity
	then 1 else 0 end)/count(*),2) as "Times Dexterity Prioritized",
	round(100.0 * sum(case when greatest(strength, dexterity, constitution, intelligence, wisdom, charisma) = constitution
	then 1 else 0 end)/count(*),2) as "Times Constitution Prioritized",
	round(100.0 * sum(case when greatest(strength, dexterity, constitution, intelligence, wisdom, charisma) = intelligence
	then 1 else 0 end)/count(*),2) as "Times Intelligence Prioritized",
	round(100.0 * sum(case when greatest(strength, dexterity, constitution, intelligence, wisdom, charisma) = wisdom
	then 1 else 0 end)/count(*),2) as "Times Wisdom Prioritized",
	round(100.0 * sum(case when greatest(strength, dexterity, constitution, intelligence, wisdom, charisma) = charisma
	then 1 else 0 end)/count(*),2) as "Times Charisma Prioritized"
from characters

where not (strength = dexterity and strength = constitution and strength = intelligence and strength = wisdom
	and strength = charisma);

--Check to see how many stats were unaltered from 10's across the board. For peace of mind.
select
	round(100.0 * sum(case when strength = dexterity and strength = constitution and strength = intelligence
	and strength = wisdom and strength = charisma then 1 else 0 end)/ count(*), 2)
from characters;

--Q6. What are the most popular races?
select rank() over(order by count(race) desc) as race_rank,
	race, count(race) as number_of_players

from characters

group by race
order by race_rank;

--Q7. How often are players multiclassing?
select sum(case when class_other is not null then 1 else 0 end) as "# of Multiclasses",
	round(100.0 * sum(case when class_other is not null then 1 else 0 end)/ count(*), 2) as "% of Multiclasses"

from characters;

--Q8. How often are players multiclassing with more than two classes?
select sum(case when class_other is not null and class_other like '%/%' then 1 else 0 end) as "# more than 2 classes",
	round(100.0 * sum(case when class_other is not null and class_other like '%/%' 
		then 1 else 0 end)/ count(*), 2) as "% more than 2 classes"

from characters;

--Q9. Assuming characters have 'died' at the point that they stop being updated, what levels do different classes make it to?
select class_starting, round(avg(total_level), 2)

from characters
group by class_starting;

--Q10. When was DnD Beyond being used most based on this data?
select EXTRACT(HOUR FROM date_modified::TIMESTAMPTZ) as hourly_bucket,
	count(*) as total
from characters
where to_char(date_modified::timestamptz, 'YYYY-MM-DD') = '2018-06-29'
group by hourly_bucket
order by hourly_bucket;

--Noting that there seems to be one specific hour seeming to be when the vast majority of sheets were modified
--Let's check by the seconds to see how close they are
select to_char(date_modified::timestamptz, 'YYYY-MM-DD-HH-MM-SS') as "Day Modified",
	count(*) as modifications

from characters
group by "Day Modified"
having count(*) > 100
order by "Day Modified";

--The data collection in that field needs to be validated, and the times and dates of that dates will be ignored
