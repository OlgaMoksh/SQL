 --1. В каких городах больше одного аэропорта?
/*Описание решения: с помощью подзапроса определить в таблице airports, какие города встречаются чаще 1 раза 
 (сгруппировав по названию и применив к результату группировки условие, что количество городов в ней больше 1), 
 поскольку это и будут те города, в которых больше 1 аэропорта (в данной таблице аэропорты уникальны, а города - нет). 
 Затем внешним запросом вывести города, сгруппировав их по названию.*/
select a.city 
from airports a
where a.city in (select a.city 
from airports a 
		group by a.city
		having count(a.city) > 1)
group by a.city;


--2.В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета? 
--В решении обязательно должен быть использован подзапрос.
/*Описание решения: учитывая, что у разных моделей самолетов может совпасть максимальная дальность перелета, 
используются два подзапроса: первый - для определения максимальной дальности перелета range, 
второй - для определения модели самолета aircraft_code, которому(ым) свойственно искомое значение максимальной дальности перелета. 
Затем с помощью внешнего запроса из таблицы flights выводятся аэропорты отправления, 
из которых выполняются рейсы найденными с помощью подзапросов самолетами.*/
select f.departure_airport as "Аэропорты"
from flights f 
where f.aircraft_code in (select a.aircraft_code
				from aircrafts a
				where a."range" in (select max(a."range") from aircrafts a)
)
group by 1;

--3.Вывести 10 рейсов с максимальным временем задержки вылета. 
--В решении обязательно должен быть использован оператор limit.
/*Описание решения: добавить в вывод из таблицы flights вычисляемый время задержки столбец 
 (разница между плановым и фактическим временем вылета (actual_departure- scheduled_departure)). 
 Поскольку в таблице flights время фактического вылета actual_departure может принимать null, 
 то необходимо исключить из рассмотрения такие строки (предусмотреть условия в where). 
 Затем отсортировать по убыванию значений из вычисляемого время задержки столбца.*/
select f.flight_no, f.scheduled_departure, f.actual_departure, (f.actual_departure-f.scheduled_departure) as "Время задержки"
from flights f 
where f.actual_departure is not null 
order by (f.actual_departure- f.scheduled_departure) desc 
limit 10;

--4.Были ли брони, по которым не были получены посадочные талоны? 
--В решении обязательно должен быть использован верный тип JOIN.
/*Описание решения: номера броней book_ref и соответствующие им билеты ticket_no отражены в таблице tickets, 
 при этом одной брони может соответствовать несколько билетов. 
Исходя из того, что если пассажир купил билет, то это вовсе не значит, что он обязательно зарегистрировался на рейс и имеет посадочный талон 
(т.е. билетов больше, чем посадочных талонов), 
необходимо соединить таблицу tickets с таблицей boarding_passes методом left join. 
Чтобы определить номера броней book_ref, по которым не были получены посадочные талоны, 
необходимо отфильтровать посадочные талоны со значением null 
(т.е. номеру билета соответствует null значение посадочного талона).*/
select t.book_ref 
from tickets t 
left join boarding_passes bp on bp.ticket_no = t.ticket_no
where bp.boarding_no is null;
 	
--5.Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете. 
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
--Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день. 
--В решении обязательно должны быть использованы: оконная функция и подзапросы или cte.

/*Описание решения: используя cte1, можно посчитать число мест, соответствующее каждой модели самолета (aircraft_code), применяя группировку. 
Поскольку информация о фактически занятых местах хранится в таблице boarding_passes, 
необходимо соединить с этой таблицей таблицу flights по уникальному ключу flight_id. Используя cte2 и оконную конструкцию с функцией count(), 
можно посчитать число занятых мест в группировке по рейсам.
Чтобы в основном запросе оставить по одной строке каждой группы, необходимо с помощью оконной функции row_number() дополнительно пронумеровать строки каждого окна. 
В основном запросе необходимо соединить cte2 и cte1 по уникальному ключу aircraft_code и вывести запрашиваемую информацию.
Для вывода округленных значений % свободных мест используется функция round() с предварительным приведением значений к типу данных numeric.
Для вывода накопительного итога по количеству улетевших человек в каждом аэропорту на каждый день 
используется оконная конструкция с функцией sum() с группировкой по аэропортам вылета и дате 
(т.е. отбрасывается время) и сортировкой по дате с учетом времени.*/
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
select cte2.flight_no, cte2.actual_departure, cte2.departure_airport, (cte1.all_s - cte2.fact_s) as "Свободно", 
	round(((cte1.all_s  - cte2.fact_s)::numeric  / cte1.all_s::numeric)*100, 2) as "% свободных мест",
	sum(cte2.fact_s) over (partition by cte2.departure_airport,cte2.actual_departure::date  order by cte2.actual_departure) as "Улетело, чел."
from cte2
join cte1 on cte1.aircraft_code = cte2.aircraft_code 
where cte2.r_n = 1
order by cte2.departure_airport;


--6.Найдите процентное соотношение перелетов по типам самолетов от общего количества. 
--В решении обязательно должны быть использованы: подзапрос и оператор ROUND
/*Описание решения: в подзапросе с помощью оконных конструкций с функцией count() выводятся общее количество рейсов и количество рейсов по типам самолетов. 
Для расчета процентного соотношения перелетов по типам самолетов от общего количества во внешнем запросе 
используются результаты оконных функций из подзапроса при этом данные группируются.*/
select t.aircraft_code, round(t.c_fa::numeric /t.c::numeric*100 , 2) as "% отношение перелетов"
from (select aircraft_code, 
			count(flight_id) over(partition by aircraft_code) c_fa, 
			count(flight_id) over () c
	from flights f) t 
group by t.aircraft_code, t.c_fa, t.c;

--7.Были ли города, в которые можно добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета? 
--В решении обязательно должно быть использовано CTE.
/*Описание решения: в cte c помощью условного оператора case определим минимальную цену билета для бизнес-класса 
 и максимальную цену билета для эконом-класса для каждого города прибытия в рамках рейсов. 
 Для этого таблицу ticket_flights с данными стоимости билета в разрезе классов обслуживания необходимо обогатить 
 данными из таблицы flights с помощью join по идентификатору рейсов, чтобы затем добраться до названия города прибытия из таблицы airports.  
 После чего в основном запросе выводятся те города, для которых справедливо, 
 что минимальная цена билета бизнес-класса ниже максимальной цены билета эконом-класса.*/

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

--8.Между какими городами нет прямых рейсов? 
--В решении обязательно должны быть использованы: декартово произведение в предложении FROM, самостоятельно созданные представления, оператор EXCEPT.
/*Описание решения: создается материализованное представление connecting flights, в котором будут храниться названия городов, 
 * между которыми нет рейсов. Для этого из множества всевозможных пар городов из материализованного представления routes, 
 * собранных с помощью декартова произведения cross join (с условием исключения пар с одинаковыми названиями городов), 
 * исключаются действительные пары аэропортов (т.е. связанных прямыми рейсами) из материализованного представления routes.*/
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
 	
--9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов в самолетах, обслуживающих эти рейсы. 
-- В решении обязательно должны быть использованы: оператор RADIANS или использование sind/cosd и CASE. 

/*Описание решения: для расчета расстояния используется формула из сферической теоремы косинусов: 
d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}, 
где latitude_a и latitude_b — широты, longitude_a, longitude_b — долготы данных пунктов, 
d — расстояние между пунктами измеряется в радианах длиной дуги большого круга земного шара.
Расстояние между пунктами, измеряемое в километрах, определяется по формуле:
L = d·R, где R = 6371 км — средний радиус земного шара.

С помощью join из таблицы flights к аэропортам, связанным прямыми рейсами, добавляются координаты из таблицы airports 
(соединение производится по идентификатору аэропорта, сначала для обогащения данными аэропорта вылета, затем - для аэропорта назначения).
Также с помощью join добавляется максимальная дальность перелетов самолетов, обслуживающих рассматриваемые рейсы, из таблицы aircrafts 
(соединение производится по идентификатору модели самолета).
Используя приведенную выше формулу из сферической теоремы косинусов и применяя функции cosd() и sind() для координат в градусах, 
рассчитывается расстояние между аэропортами. Сравнение расстояния между аэропортами предусматривается в операторе case. 
Во избежание дублирования выводимой информации в виде зеркальных пар аэропортов используется условие f.departure_airport > f.arrival_airport.*/
select f.departure_airport, f.arrival_airport, 
a2."range" as "Range r", 
round(6371*acos(sind(a.latitude)*sind(a1.latitude) + cosd(a.latitude)*cosd(a1.latitude)*cosd(a.longitude - a1.longitude))::numeric,0) as "Расстояние l",
case when (6371*acos(sind(a.latitude)*sind(a1.latitude) + cosd(a.latitude)*cosd(a1.latitude)*cosd(a.longitude - a1.longitude))) > a2."range" 
then 'Превышает' else 'Не превышает' end as "Сравнение l и r"
from flights f 
join airports a on a.airport_code = f.departure_airport 
join airports a1 on a1.airport_code = f.arrival_airport 
join aircrafts a2 on a2.aircraft_code = f.aircraft_code 
where f.departure_airport > f.arrival_airport 
group by a.airport_code, a1.airport_code, a2."range", f.departure_airport,f.arrival_airport 
order by round(6371*acos(sind(a.latitude)*sind(a1.latitude) + cosd(a.latitude)*cosd(a1.latitude)*cosd(a.longitude - a1.longitude))::numeric,0) DESC; 

