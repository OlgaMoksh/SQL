 --1. � ����� ������� ������ ������ ���������?
/*�������� �������: � ������� ���������� ���������� � ������� airports, ����� ������ ����������� ���� 1 ���� 
 (������������ �� �������� � �������� � ���������� ����������� �������, ��� ���������� ������� � ��� ������ 1), 
 ��������� ��� � ����� �� ������, � ������� ������ 1 ��������� (� ������ ������� ��������� ���������, � ������ - ���). 
 ����� ������� �������� ������� ������, ������������ �� �� ��������.*/
select a.city 
from airports a
where a.city in (select a.city 
from airports a 
		group by a.city
		having count(a.city) > 1)
group by a.city;


--2.� ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������? 
--� ������� ����������� ������ ���� ����������� ���������.
/*�������� �������: ��������, ��� � ������ ������� ��������� ����� �������� ������������ ��������� ��������, 
������������ ��� ����������: ������ - ��� ����������� ������������ ��������� �������� range, 
������ - ��� ����������� ������ �������� aircraft_code, ��������(��) ����������� ������� �������� ������������ ��������� ��������. 
����� � ������� �������� ������� �� ������� flights ��������� ��������� �����������, 
�� ������� ����������� ����� ���������� � ������� ����������� ����������.*/
select f.departure_airport as "���������"
from flights f 
where f.aircraft_code in (select a.aircraft_code
				from aircrafts a
				where a."range" in (select max(a."range") from aircrafts a)
)
group by 1;

--3.������� 10 ������ � ������������ �������� �������� ������. 
--� ������� ����������� ������ ���� ����������� �������� limit.
/*�������� �������: �������� � ����� �� ������� flights ����������� ����� �������� ������� 
 (������� ����� �������� � ����������� �������� ������ (actual_departure- scheduled_departure)). 
 ��������� � ������� flights ����� ������������ ������ actual_departure ����� ��������� null, 
 �� ���������� ��������� �� ������������ ����� ������ (������������� ������� � where). 
 ����� ������������� �� �������� �������� �� ������������ ����� �������� �������.*/
select f.flight_no, f.scheduled_departure, f.actual_departure, (f.actual_departure-f.scheduled_departure) as "����� ��������"
from flights f 
where f.actual_departure is not null 
order by (f.actual_departure- f.scheduled_departure) desc 
limit 10;

--4.���� �� �����, �� ������� �� ���� �������� ���������� ������? 
--� ������� ����������� ������ ���� ����������� ������ ��� JOIN.
/*�������� �������: ������ ������ book_ref � ��������������� �� ������ ticket_no �������� � ������� tickets, 
 ��� ���� ����� ����� ����� ��������������� ��������� �������. 
������ �� ����, ��� ���� �������� ����� �����, �� ��� ����� �� ������, ��� �� ����������� ����������������� �� ���� � ����� ���������� ����� 
(�.�. ������� ������, ��� ���������� �������), 
���������� ��������� ������� tickets � �������� boarding_passes ������� left join. 
����� ���������� ������ ������ book_ref, �� ������� �� ���� �������� ���������� ������, 
���������� ������������� ���������� ������ �� ��������� null 
(�.�. ������ ������ ������������� null �������� ����������� ������).*/
select t.book_ref 
from tickets t 
left join boarding_passes bp on bp.ticket_no = t.ticket_no
where bp.boarding_no is null;
 	
--5.������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������. 
--�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
--�.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ �� ����. 
--� ������� ����������� ������ ���� ������������: ������� ������� � ���������� ��� cte.

/*�������� �������: ��������� cte1, ����� ��������� ����� ����, ��������������� ������ ������ �������� (aircraft_code), �������� �����������. 
��������� ���������� � ���������� ������� ������ �������� � ������� boarding_passes, 
���������� ��������� � ���� �������� ������� flights �� ����������� ����� flight_id. ��������� cte2 � ������� ����������� � �������� count(), 
����� ��������� ����� ������� ���� � ����������� �� ������.
����� � �������� ������� �������� �� ����� ������ ������ ������, ���������� � ������� ������� ������� row_number() ������������� ������������� ������ ������� ����. 
� �������� ������� ���������� ��������� cte2 � cte1 �� ����������� ����� aircraft_code � ������� ������������� ����������.
��� ������ ����������� �������� % ��������� ���� ������������ ������� round() � ��������������� ����������� �������� � ���� ������ numeric.
��� ������ �������������� ����� �� ���������� ��������� ������� � ������ ��������� �� ������ ���� 
������������ ������� ����������� � �������� sum() � ������������ �� ���������� ������ � ���� 
(�.�. ������������� �����) � ����������� �� ���� � ������ �������.*/
with cte1 as 
	(select aircraft_code, count(s.seat_no) all_s
	from seats s 
	group by aircraft_code),
cte2 as 
	(select f.flight_id, f.flight_no, f.actual_departure, f.departure_airport,  f.aircraft_code, 
	count(bp.seat_no) over (partition by f.flight_id) fact_s,
	row_number() over (partition by f.flight_id) r_n
	from flights f 
	join boarding_passes bp on bp.flight_id = f.flight_id)
select cte2.flight_no, cte2.actual_departure, cte2.departure_airport, (cte1.all_s - cte2.fact_s) as "��������", 
	round(((cte1.all_s  - cte2.fact_s)::numeric  / cte1.all_s::numeric)*100, 2) as "% ��������� ����",
	sum(cte2.fact_s) over (partition by cte2.departure_airport,cte2.actual_departure::date  order by cte2.actual_departure) as "�������, ���."
from cte2
join cte1 on cte1.aircraft_code = cte2.aircraft_code 
where cte2.r_n = 1
order by cte2.departure_airport;


--6.������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������. 
--� ������� ����������� ������ ���� ������������: ��������� � �������� ROUND
/*�������� �������: � ���������� � ������� ������� ����������� � �������� count() ��������� ����� ���������� ������ � ���������� ������ �� ����� ���������. 
��� ������� ����������� ����������� ��������� �� ����� ��������� �� ������ ���������� �� ������� ������� 
������������ ���������� ������� ������� �� ���������� ��� ���� ������ ������������.*/
select t.aircraft_code, round(t.c_fa::numeric /t.c::numeric*100 , 2) as "% ��������� ���������"
from (select aircraft_code, 
			count(flight_id) over(partition by aircraft_code) c_fa, 
			count(flight_id) over () c
	from flights f) t 
group by t.aircraft_code, t.c_fa, t.c;

--7.���� �� ������, � ������� ����� ��������� ������ - ������� �������, ��� ������-������� � ������ ��������? 
--� ������� ����������� ������ ���� ������������ CTE.
/*�������� �������: � cte c ������� ��������� ��������� case ��������� ����������� ���� ������ ��� ������-������ 
 � ������������ ���� ������ ��� ������-������ ��� ������� ������ �������� � ������ ������. 
 ��� ����� ������� ticket_flights � ������� ��������� ������ � ������� ������� ������������ ���������� ��������� 
 ������� �� ������� flights � ������� join �� �������������� ������, ����� ����� ��������� �� �������� ������ �������� �� ������� airports.  
 ����� ���� � �������� ������� ��������� �� ������, ��� ������� �����������, 
 ��� ����������� ���� ������ ������-������ ���� ������������ ���� ������ ������-������.*/

with cte as 
	(select  f.flight_no, a.city arrival_city, 
			min(case when fare_conditions = 'Business' then amount else null end) as business, 
			max(case when fare_conditions = 'Economy' then amount else null end) as economy
	from ticket_flights tf 
	join flights f on f.flight_id = tf.flight_id 
	join airports a on a.airport_code = f.arrival_airport
	group by f.flight_no, a.city)
select cte.flight_no, cte.arrival_city
from cte
where cte.business < cte.economy;

--8.����� ������ �������� ��� ������ ������? 
--� ������� ����������� ������ ���� ������������: ��������� ������������ � ����������� FROM, �������������� ��������� �������������, �������� EXCEPT.
/*�������� �������: ��������� ����������������� ������������� connecting flights, � ������� ����� ��������� �������� �������, 
 * ����� �������� ��� ������. ��� ����� �� ��������� ������������ ��� ������� �� ������������������ ������������� routes, 
 * ��������� � ������� ��������� ������������ cross join (� �������� ���������� ��� � ����������� ���������� �������), 
 * ����������� �������������� ���� ���������� (�.�. ��������� ������� �������) �� ������������������ ������������� routes.*/
create materialized view connecting_flights as 
select r.departure_city departure_city, r2.arrival_city arrival_city
from routes r 
cross join routes r2 
where r.departure_city != r2.arrival_city 
group by r.departure_city, r2.arrival_city
except 
select r3.departure_city, r3.arrival_city 
from routes r3; 

select *
from connecting_flights;
 	
--9. ��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ���������� ��������� � ���������, ������������� ��� �����. 
-- � ������� ����������� ������ ���� ������������: �������� RADIANS ��� ������������� sind/cosd � CASE. 

/*�������� �������: ��� ������� ���������� ������������ ������� �� ����������� ������� ���������: 
d = arccos {sin(latitude_a)�sin(latitude_b) + cos(latitude_a)�cos(latitude_b)�cos(longitude_a - longitude_b)}, 
��� latitude_a � latitude_b � ������, longitude_a, longitude_b � ������� ������ �������, 
d � ���������� ����� �������� ���������� � �������� ������ ���� �������� ����� ������� ����.
���������� ����� ��������, ���������� � ����������, ������������ �� �������:
L = d�R, ��� R = 6371 �� � ������� ������ ������� ����.

� ������� join �� ������� flights � ����������, ��������� ������� �������, ����������� ���������� �� ������� airports 
(���������� ������������ �� �������������� ���������, ������� ��� ���������� ������� ��������� ������, ����� - ��� ��������� ����������).
����� � ������� join ����������� ������������ ��������� ��������� ���������, ������������� ��������������� �����, �� ������� aircrafts 
(���������� ������������ �� �������������� ������ ��������).
��������� ����������� ���� ������� �� ����������� ������� ��������� � �������� ������� cosd() � sind() ��� ��������� � ��������, 
�������������� ���������� ����� �����������. ��������� ���������� ����� ����������� ����������������� � ��������� case. 
�� ��������� ������������ ��������� ���������� � ���� ���������� ��� ���������� ������������ ������� f.departure_airport > f.arrival_airport.*/
select f.departure_airport, f.arrival_airport, 
a2."range" as "Range r", 
round(6371*acos(sind(a.latitude)*sind(a1.latitude) + cosd(a.latitude)*cosd(a1.latitude)*cosd(a.longitude - a1.longitude))::numeric,0) as "���������� l",
case when (6371*acos(sind(a.latitude)*sind(a1.latitude) + cosd(a.latitude)*cosd(a1.latitude)*cosd(a.longitude - a1.longitude))) > a2."range" 
then '���������' else '�� ���������' end as "��������� l � r"
from flights f 
join airports a on a.airport_code = f.departure_airport 
join airports a1 on a1.airport_code = f.arrival_airport 
join aircrafts a2 on a2.aircraft_code = f.aircraft_code 
where f.departure_airport > f.arrival_airport 
group by a.airport_code, a1.airport_code, a2."range", f.departure_airport,f.arrival_airport 
order by round(6371*acos(sind(a.latitude)*sind(a1.latitude) + cosd(a.latitude)*cosd(a1.latitude)*cosd(a.longitude - a1.longitude))::numeric,0) DESC; 

