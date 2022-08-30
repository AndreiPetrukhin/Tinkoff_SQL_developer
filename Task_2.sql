-- Решить 12 задачу

--Требуется написать SQL запросы для выборок:
--1.    Выбрать всех прогулявших занятия в июле 2022 года учеников
select 
	student_id 
from lessons_diary ld 
where is_absent = 0 -- filter studens who skiped
	and lesson_id in -- choose all completed lessons id July 2022
		(select -- select all completed lessons in July 2022
			id 
		from lessons l 
		where dt >= '2022-07-01' and dt <= '2022-07-31');

--2.    Вывести три наиболее загруженных уроками классных комнаты, кол-во занятий в каждой и % проведенных в 
--них занятий из числа всех проведенных занятий во всех комнатах
select 
	classroom_id ,
	count(1) as "кол-во занятий в каждой", -- count lessons in each class
	100*count(1)::float/ --numb lessons in each class dev by total quantity and super 100 to show %
		(select count(1) from lessons l2) --sub request to count total lessons in all classes
		as "% проведенных занятий из числа всех" --column name
from lessons l -- from completed lessons
group by classroom_id -- group by classes to use agr function count()
order by count(1) desc -- order by lessons quantity from highest to smallest 
limit 3; -- show 3 rows only

--3.    Вывести классы с ежемесячно проводимыми в них уроками рисования

--алгоритм показывает все ежемесячне занятие для классов
select 
	l.class_id ,
	date_trunc('month', l.dt)::date as "month",
	count(1)
from lessons l 
where lesson_type = 10
group by class_id , date_trunc('month', dt) ;

--4.    Для каждого месяца вывести учителей, которые провели от пяти до десяти уроков в ныне закрытой для 
--использования классной комнате
select 
	date_trunc('month', l.dt)::date as "month", --extract month from date
	teacher_id
from lessons l 
where classroom_id in --filter to choose closed classroom only
	(select id from classrooms c --subrequest to select classroom id that closed
	where is_temporary_closed = 1)
group by date_trunc('month', l.dt)::date, teacher_id --group by month, teachers id to count quantity of lessons per month
having count(1) > 4 and count(1) <10 --filtef to choose teachers with qty from 5 and less then 10
order by date_trunc('month', l.dt)::date, teacher_id; --optional order by


--5.    Вывести таблицу с полями teacher_name, grade_one_ratio, grade_two_ratio, grade_three_ratio, 
--grade_four_ratio, grade_five_ratio где
--teacher_name - полное имя учителя
--grade_one_ratio - % выставляемых учителем оценок "1"
--..
--grade_five_ratio - % выставляемых учителем оценок "5"
select 
	concat_ws(' ', t.first_name, t.last_name), --union of first name and surname
	100*(count(case when grade = 1 then grade end) -- count all 1 grades for teacher
	+ --sum grades qnty with grades_extra qnty
	count(case when grade_extra  = 1 then grade_extra end))::float -- count all 1 grades_extra for teacher
	/--dev numb of 1 grades to total numd of grades
	greatest (1, --choose greatest value to aviod zero value
	(count(case when grade is not null then grade end) --count total numb of grades
	+ count(case when grade_extra  is not null then grade_extra end))) as grade_one_ratio, --count total numb of grades_extra
	100*(count(case when grade = 2 then grade end) 
	+ count(case when grade_extra  = 2 then grade_extra end))::float
	/greatest (1,
	(count(case when grade is not null then grade end) 
	+ count(case when grade_extra  is not null then grade_extra end))) as grade_two_ratio,
	100*(count(case when grade = 3 then grade end) 
	+ count(case when grade_extra  = 3 then grade_extra end))::float
	/greatest (1,
	(count(case when grade is not null then grade end) 
	+ count(case when grade_extra  is not null then grade_extra end))) as grade_three_ratio,
	100*(count(case when grade = 4 then grade end) 
	+ count(case when grade_extra  = 4 then grade_extra end))::float
	/greatest (1,
	(count(case when grade is not null then grade end) 
	+ count(case when grade_extra  is not null then grade_extra end))) as grade_four_ratio,
	100*(count(case when grade = 5 then grade end) 
	+ count(case when grade_extra  = 5 then grade_extra end))::float
	/greatest (1,
	(count(case when grade is not null then grade end) 
	+ count(case when grade_extra  is not null then grade_extra end))) as grade_five_ratio
from lessons_diary ld 
join lessons l on l.id = ld.lesson_id -- due to constraints may use join to have teachers id
join teachers t on t.id = l.teacher_id -- due to constraints may use join to have teachers name
group by concat_ws(' ', t.first_name, t.last_name);


--6.    Найти все занятия истории, проведенные в классах с проекторами без прогульщиков
--version 1 (optimal)
--explain analyze --cost=61.31..78.64
select 
	l.id -- output all history lessons id
from lessons l 
join -- get id with present student, history class and has projecter
	(select lesson_id from lessons_diary ld --choose lessons id wihtout absent students
	group by lesson_id --group by id to count lessons qnty and present student qnty 
	having count(lesson_id) = sum(is_absent)) --count lessons qnty and present student qnty (1=present)
	fl on fl.lesson_id = l.id --join by id
where lesson_type = --filter by history lessons id
					(select id from lesson_types lt --choose history lessons id
					where "name" = 'History') 
	and classroom_id in (select id from classrooms c  --filter class id with projecter
					where has_projector = 1);

--version 2 
--explain analyze --cost=86.33..86.36
select 
	ld.lesson_id
from lessons_diary ld 
join lessons l on l.id = ld.lesson_id 
join lesson_types lt on lt.id = l.lesson_type 
join classrooms c on c.id = l.classroom_id
where lt."name" = 'History' and c.has_projector = 1
group by ld.lesson_id 
having count(lesson_id) = sum(is_absent);


--7.    Найти учеников, сумевших получить оценку "2" на пяти подряд занятиях и для каждого вывести одним 
--полем список учителей, поставивших эту оценку, в порядке убывания их возраста

--для 
select
	*
from (
select
	count(ld.lesson_id) over(partition by l.class_id, ld.student_id, l.dt order by l.class_id, l.dt, l.id) as qnty,
	* 
from lessons_diary ld 
join lessons l on l.id = ld.lesson_id) fin ;


select 
	fin.student_id --ученики получившие 5 двое подряд
from (
	select 
		l.id ,
		l.dt ,
		ld.student_id,
		lag (l.id) over(order by ld.student_id, l.id) as prev_lid
	from lessons l 
	join lessons_diary ld on ld.lesson_id = l.id
	where ld.grade = 2 or ld.grade_extra = 2) fin
where fin.id - fin.prev_lid = 1
group by fin.student_id
having count(fin.id)=4;


with cte as (select 
	*,
	case 
		when fin.id - fin.prev_l_id = 1 and  then count(fin.id) over(partition by fin.student_id)
		else null
	end as numb_2_les
from (
	select 
		l.id ,
		lag (l.id) over(order by ld.student_id, l.id) as prev_l_id,
		lag (l.id, -1) over(order by ld.student_id, l.id) as next_l_id,
		l.dt ,
		ld.student_id,
		lag (ld.student_id) over(order by ld.student_id, l.id) as prev_student_id,
		lag (ld.student_id, -1) over(order by ld.student_id, l.id) as next_student_id,
		l.teacher_id
	from lessons l 
	join lessons_diary ld on ld.lesson_id = l.id
	where ld.grade = 2 or ld.grade_extra = 2) fin
where fin.id - fin.prev_l_id = 1)
select * from cte
where cte.numb_2_les = 4


select 
	id,
	concat_ws(' ', first_name, last_name) 
from teachers t 
order by birthdate;


select
	fin_2.id,
	fin_2.student_id,
	fin_2.teacher_id
from (
	select
		fin.id,
		fin.student_id,
		fin.teacher_id,
		count(fin.student_id) over(partition by fin.student_id, fin.dt) as numb
	from (
		select 
			l.id ,
			l.dt ,
			ld.student_id, 
			l.teacher_id ,
			lag (l.id, 1) over(order by ld.student_id, l.id) as prev_lid,
			lag (l.id, -1) over(order by ld.student_id, l.id) as next_lid
		from lessons l 
		join lessons_diary ld on ld.lesson_id = l.id
		where ld.grade = 2 or ld.grade_extra = 2) fin
	where fin.id - fin.prev_lid = 1 or fin.next_lid - fin.id = 1) fin_2
join 
where fin_2.numb = 5


--8.    Вывести буквы классов и средний бал (GPA) по оценкам, полученным учениками находящимися в этих 
--классах, за 2021 год
select 
	 c.letter,
	 (sum(case when ld.grade is not null then ld.grade else 0 end) +
	 sum(case when ld.grade_extra is not null then ld.grade_extra else 0 end))::float/
	 greatest (1, (count(ld.grade) + count(ld.grade_extra))) as GPA
from lessons_diary ld 
join lessons l on l.id = ld.lesson_id 
join students s on s.id = ld.student_id 
join classes c on c.id = l.class_id 
where extract ('year' from l.dt) = '2021'
group by c.id, c.letter;


--9.    Найти учителей, которые проводили 4 и более различных дисциплин за 1 день в прошлом месяце
select 
	teacher_id
from (
	select 
		teacher_id, 
		dt, 
		lesson_type, 
		case 
			when count(1) > 0 then 1 -- show mark where teacher has at leat 1 lesson of certain type
		end as uniq_les
	from lessons l 
	where 
		case 
			when extract ('month' from now()) != 1 -- condition for January
				then (extract ('year' from now()) = extract ('year' from l.dt) --filter completed lessons by current year
				and extract ('month' from now()) - 1 = extract ('month' from l.dt)) --filter completed lessons by previous month
			else (extract ('year' from now()) - 1 = extract ('year' from l.dt)
				and 12 = extract ('month' from l.dt))
		end
	group by teacher_id, dt, lesson_type) fin -- group to count uniq lessons
group by teacher_id, dt -- group to count qnty of uniq lesson type per day for specific teacher
having sum(uniq_les) > 3; -- filter teachers with more then 3 uniq lessons per day
 

--10. Найти учеников, которые в 2021 году были переведены в другой класс и их средняя успеваемость (GPA) 
--улучшилась

-- * в случае двух или более переходов одного ученика в 2021 его Id выведется несколько раз соответственно
with cte as ( -- cte to pre process data
select
	fin.class_id,
	fin.student_id,
	fin.start_date, --start_date of studying
	fin.end_date,--end_date of studying
	fin.next_start_date, -- next_start_date of studying after transfer to another class
	fin.next_end_date, -- next_end_date of studying after transfer to another class
	row_number () over() as study_period --marker of studying periods
from (
	select 
		* ,
		lag(start_date, -1) over(order by student_id, start_date) as next_start_date,
		lag(end_date, -1) over(order by student_id, end_date) as next_end_date,
		count(student_id) over (partition by student_id) as transfer_numb -- count qnty of transfers for every student
	from class_students_map csm) fin
	where transfer_numb > 1 --filter students with more then one class transfer
		and extract ('year' from fin.end_date) = 2021 --check transfer year 2021
		and next_start_date is not null), --check not graduated students
mark_before as ( --cte to count GPA before transfer to another class
select 
	cte.student_id, 
	cte.study_period,
	(sum(case when ld.grade is not null then ld.grade else 0 end) +
	 sum(case when ld.grade_extra is not null then ld.grade_extra else 0 end))::float/
	 greatest (1, (count(ld.grade) + count(ld.grade_extra))) as GPA_before --count GPA see task 8
from lessons_diary ld -- to ahve grades and extra grades for every student
join lessons l on l.id =ld.lesson_id -- join to get dates of completed lessons
join cte on cte.student_id = ld.student_id 
			and l.dt >= cte.start_date --filter joining data to have grades within period of studying
			and l.dt <= cte.end_date
group by cte.student_id, cte.study_period), --group to count GPA for every student at every period of studying
mark_after as ( -- cte to count grades after transfer to another class
select 
	cte.student_id, 
	cte.study_period,
	(sum(case when ld.grade is not null then ld.grade else 0 end) +
	 sum(case when ld.grade_extra is not null then ld.grade_extra else 0 end))::float/
	 greatest (1, (count(ld.grade) + count(ld.grade_extra))) as GPA_after
from lessons_diary ld 
join lessons l on l.id =ld.lesson_id
join cte on cte.student_id = ld.student_id 
			and l.dt > cte.end_date  --join grades after studying period finish
			and case 
					when cte.next_end_date is not null then l.dt <= cte.next_end_date --condition if student changed class again, we choose period in this class
					else true --condition if student in process of study so next_end_date is null --> no additional filters required
				end
group by cte.student_id, cte.study_period)
select 
	ma.student_id 
from mark_before mb
join mark_after ma on ma.student_id = mb.student_id and ma.study_period = mb.study_period
where mb.gpa_before < ma.gpa_after; -- filter to show only students with better results after transfer


--11. Найти самого молодого учителя преподававшего математику в школе, вывести фамилию, имя и количество лет 
--на момент старта преподавания дисциплины

--*рассчитывается количество полных лет
select 
	t.last_name ,
	t.first_name ,
	(t.start_date - t.birthdate)/(365) as years_old --count dates dif and calculate years
from teachers t 
join specialities s on s.id = t.speciality_id 
where s."name" = 'Math' --filter for math teachers
order by birthdate desc --order techers by birthdate to find the youngest one from high to low
limit 1;--to show only one teacher

--12. Вывести учеников за первое полугодие 2021 года, у которых средний бал (GPA) по оценкам меньше среднего 
--бала их класса, в формате фамилия, имя ученика, номер и буква класса
with GPA_student as (
select 
	ld.student_id,
	(sum(case when ld.grade is not null then ld.grade else 0 end) +
	 sum(case when ld.grade_extra is not null then ld.grade_extra else 0 end))::float/
	 greatest (1, (count(ld.grade) + count(ld.grade_extra))) as GPA_student	 
from lessons_diary ld 
join lessons l on l.id = ld.lesson_id 
where extract('quarter' from l.dt) in (1, 2) and extract('year' from l.dt) = 2022
group by ld.student_id),
GPA_class as (
select 
	l.class_id,
	(sum(case when ld.grade is not null then ld.grade else 0 end) +
	 sum(case when ld.grade_extra is not null then ld.grade_extra else 0 end))::float/
	 greatest (1, (count(ld.grade) + count(ld.grade_extra))) as GPA_class	 
from lessons_diary ld 
join lessons l on l.id = ld.lesson_id 
where extract('quarter' from l.dt) in (1, 2) and extract('year' from l.dt) = 2022
group by l.class_id)
select 
	st.first_name AS student_first_name,
    st.last_name AS student_last_name,
    case 
    	when (now()::date - cl.start_year) / 365 > 11 then 'graduated' 
    	else to_char((now()::date - cl.start_year) / 365, '19')
    end AS class_number,
    cl.letter AS class_letter 
from class_students_map csm 
join GPA_student gs on gs.student_id = csm.student_id 
join GPA_class gc on gc.class_id = csm.class_id
left join students st on csm.student_id = st.id
left join classes cl on csm.class_id = cl.id
where gs.GPA_student > gc.GPA_class;


--13. Вывести число, день недели, количество уроков для 5А класса за апрель 2021 года
select 
	l.dt as "date",
	case --condition to show days of the week
		WHEN extract ('dow' from l.dt) = 0 THEN 'Sunday'
        WHEN extract ('dow' from l.dt) = 1 THEN 'Monday'
        WHEN extract ('dow' from l.dt) = 2 THEN 'Tuesday'
        WHEN extract ('dow' from l.dt) = 3 THEN 'Wednesday'
        WHEN extract ('dow' from l.dt) = 4 THEN 'Thursday'
        WHEN extract ('dow' from l.dt) = 5 THEN 'Friday'
        WHEN extract ('dow' from l.dt) = 6 THEN 'Saturday'
	end as "week day",
	count(1) as "lessons qnty" --count lessons qnty
from lessons l 
join classes c on c.id = l.class_id --join classes to get info about class start_date and alpha
where extract ('year' from l.dt) = 2021 --filter all lessons in 2021
		and extract ('month' from l.dt) = 4 --filter all lessons in april
		and c.letter = 'A'--filter all A classes
		and (now()::date - c.start_year)/365 = 5 --choose classes which began the studying 5 years ago
group by l.class_id , l.dt ; --group by specific class and date to count qnty of lessons


--14. Найти 3 самые легкие дисциплины (наивысшая средняя успеваемость учеников) за 2021 год, вывести в 
--порядке убывания успеваемости
with cte as (
select 
	l.lesson_type,
	(sum(case when ld.grade is not null then ld.grade else 0 end) +
	 sum(case when ld.grade_extra is not null then ld.grade_extra else 0 end))::float/
	 greatest (1, (count(ld.grade) + count(ld.grade_extra))) as GPA_subject
from lessons_diary ld 
join lessons l on l.id = ld.lesson_id 
where extract ('year' from l.dt) = 2021
group by l.lesson_type)
select 
	lt."name",
	cte.GPA_subject
from cte 
join lesson_types lt on lt.id = cte.lesson_type
order by cte.GPA_subject desc --не используем оконную функцию и dense_rank ()  так как говориться именно про три самых легких предмета
limit 3;

--15. Вывести классы (номер, буква) и количество отсутствовавших учеников 1 марта 2021 года и общее 
--количество отсутствовавших в школе за этот день (класс и букву оставить пустыми)
with cte as (
select 
	s.id as student_id,
	c.id as class_id,
	c.letter ,
	c.start_year as start_year
from lessons_diary ld 
join lessons l on l.id = ld.lesson_id 
join students s on s.id = ld.student_id 
join classes c on c.id = l.class_id
where l.dt = '2021-03-01'
		and ld.is_absent = 0
		and (c.end_year > '2021-03-01' or c.end_year is null))-- to avoid graduated classes
select 
	(now()::date - cte.start_year)/365 as numb_calss,
	letter,
	count(student_id)
from cte
group by cte.class_id, cte.start_year, cte.letter
union
select
	null,
	null,
	count(cte.student_id)
from cte;


--Описание базы данных
-- ученики
create table students (
 id integer not null primary key, 
 first_name   varchar(50) not null, --имя
 last_name    varchar(50) not null, --фамилия
 birthdate    date    not null,--день рождения
 male         varchar(1) not null check (male in ('M','F')),--пол
 start_date   date    not null, --дата, когда был зачислен в школу
 end_date     date--дата, когда был отчислен из школы (в т ч закончил школу)
);

--заполним учеников
insert into students (id, first_name, last_name, birthdate, male, start_date, end_date)
values
(1, 'Andrei', 'Ivanov', '2000-10-11', 'M', '2007-09-01', '2016-07-01'),--graduated
(2, 'Nikita', 'Petrov', '2005-07-03', 'M', '2012-09-01', null),--studying
(3, 'Alina', 'Mashina', '2006-08-01', 'F', '2013-09-01', null),--studying
(4, 'Anna', 'Salugina', '2006-08-01', 'F', '2013-09-01', '2022-06-01'),--banned
(5, 'Egor', 'Pupkin', '2013-09-28', 'M', '2020-09-01', null), --studying
(6, 'Andrei', 'Logov', '2007-10-11', 'M', '2014-09-01', null),
(7, 'Alex', 'Pilov', '2009-12-12', 'M', '2016-09-01', null),
(8, 'Harry', 'Potter', '2007-11-11', 'M', '2013-09-01', null),
(9, 'Ron', 'Wesley', '2006-12-11', 'M', '2013-09-01', null)


--test check constraint
insert into students (id, first_name, last_name, birthdate, male, start_date, end_date)
values
(6, 'Andrei', 'Ivanov', '2000-10-11', 'L', '2007-09-01', '2018-07-01'); --ok
--test PK constraint
insert into students (id, first_name, last_name, birthdate, male, start_date, end_date)
values
(5, 'Andrei', 'Ivanov', '2000-10-11', 'M', '2007-09-01', '2018-07-01'); --ok


-- специализации учителей
create table specialities (
 id  integer not null primary key,
 name varchar(50) not null--наименование специализации
);

--зполняем специализации учителей
insert into specialities  (id, "name")
values
(1, 'Math'),
(2, 'English'),
(3, 'Russina'),
(5, 'Informatics'),
(6, 'Geomethry'),
(7, 'History'),
(8, 'Literature'),
(9, 'Biology'),
(10, 'Chemistry'),
(11, 'Рисование');


-- виды уроков (математика, литература, химия etc)
create table lesson_types (
 id  integer not null primary key,
 name varchar(20) not null--наименование урока
);

--заполняем виды уроков
insert into lesson_types  (id, "name")
values
(1, 'Math'),
(2, 'English'),
(3, 'Russina'),
(5, 'Informatics'),
(6, 'Geomethry'),
(7, 'History'),
(8, 'Literature'),
(9, 'Biology'),
(10, 'Chemistry'),
(11, 'Рисование');


-- классные комнаты
create table classrooms (
 id                          integer not null primary key,
 floor                       integer not null, --номер этажа
 num                         integer not null,--номер класса
 capacity                    integer,--вместительность учеников
 has_projector               integer not null check (has_projector in (1, 0)),--признак наличия в помещении проектора 
 has_interactive_school_board integer not null check (has_interactive_school_board in (1, 0)),--признак наличия в помещении интерактивной доски
 is_temporary_closed         integer not null check (is_temporary_closed in (1, 0))--признак недоступности помещения (ремонт, etc)
);

--заполняем классные комнаты
insert into classrooms (id, floor, num, capacity , has_projector , has_interactive_school_board , is_temporary_closed  )
values
(1, 1, 101, 30, 0, 0, 0),
(2, 1, 102, 25, 1, 0, 0),
(3, 2, 201, 30, 1, 1, 1),
(4, 2, 202, 35, 1, 1, 1),
(5, 3, 301, 20, 1, 0, 1),
(6, 3, 302, 25, 0, 0, 1),
(7, 3, 303, 26, 1, 0, 1);


-- учителя
create table teachers (
 id           integer  not null primary key,
 first_name   varchar(50) not null,--имя
 last_name    varchar(50) not null,--фамилия
 birthdate    date    not null,--день рождения
 male         varchar(1) not null check(male in ('M','F')),--пол
 start_date   date    not null,--дата, когда был нанят на работы
 end_date     date,--дата, когда был уволен с работы
 speciality_id integer  not null,--специализация
 constraint speciality_id_specialities_id_fkey FOREIGN KEY (speciality_id) REFERENCES specialities(id)
);

--fulfill teachers
insert into teachers (id, first_name, last_name, birthdate, male, start_date, end_date, speciality_id)
values
(1, 'Andrei', 'MIvanov', '1990-10-11', 'M', '2007-09-01', '2018-07-01', 1),--ended
(2, 'Nikita', 'IPetrov', '1991-07-03', 'M', '2012-09-01', null, 2),--teaching
(3, 'Alina', 'IMashina', '1992-08-01', 'F', '2013-09-01', null, 3),--teaching
(4, 'Anna', 'ISalugina', '1993-08-01', 'F', '2013-09-01', '2022-06-01', 5),--ended
(5, 'Egor', 'IPupkin', '1994-09-28', 'M', '2020-09-01', null, 6), --teaching
(6, 'Ron', 'Pupkov', '1994-10-11', 'M', '2007-09-01', null, 1); 


-- ученические классы
create table classes (
 id          integer not null primary key,
 letter      varchar(1) not null, --буква класса: А/Б/В etc
 "name"      varchar(20), --имя класса, выбранное по желанию учеников (напр, имена принято выбирать по названиям галактик: Андромеда, Млечный Путь, Скульптор etc)
 start_year  date not null,--год, когда класс был сформирован из первоклашек 
 end_year    date,  --год окончания школы учениками класса
 form_teacher integer not null, --классный руководитель
 head_student integer,  --староста
 main_class  integer, --основная классная комната 
 constraint form_teacher_teachers_id_fkey FOREIGN KEY (form_teacher) REFERENCES teachers(id),
 constraint head_student_students_id_fkey FOREIGN KEY (head_student) REFERENCES students(id),
 constraint main_class_classrooms_id_fkey FOREIGN KEY (main_class) REFERENCES classrooms(id)
);

-- fulfill ученические классы
insert into classes (id, letter, "name", start_year, end_year, form_teacher, head_student, main_class)
values
(1, 'A', 'class1', '2005-09-01', '2016-07-01', 1, 1, 1),
(2, 'B', 'class2', '2012-09-01', null, 2, 2, 2),
(3, 'C', 'class3', '2013-09-01', null, 3, 3, 3),
(4, 'D', 'class4', '2008-09-01', '2019-07-01', 4, 4, 4),
(5, 'I', 'class5', '2009-09-01', '2020-07-01', 5, 5, 5),
(6, 'F', 'class6', '2015-09-01', '2026-07-01', 1, 1, 6),
(7, 'G', 'class7', '2016-09-01', '2027-07-01', 2, 2, 7),
(8, 'A', 'class1', '2016-09-01', '2027-07-01', 1, null, null),
(9, 'B', 'class2', '2017-09-01', '2028-07-01', 2, null, 2),
(10, 'A', 'class10', '2017-09-01', '2016-07-01', 5, null, null);


-- связка классов и учеников
create table class_students_map (
 class_id  integer not null,
 student_id integer not null,--дата зачисления в класс
 start_date date  not null, --дата отчисления из класса
 end_date  date,
 constraint class_id_classes_id_fkey FOREIGN KEY (class_id) REFERENCES classes(id),
 constraint student_id_students_id_fkey FOREIGN KEY (student_id) REFERENCES students(id)
);

-- fulfill связка классов и учеников
insert into class_students_map (class_id, student_id, start_date, end_date)
values
(1, 1, '2007-09-01', '2016-07-01'),
(2, 2, '2012-09-01', null),
(3, 3, '2013-09-01', null),
(4, 4, '2008-09-01', '2019-07-01'),
(5, 5, '2009-09-01', '2020-07-01'),
(2, 6, '2012-09-01', null),
(3, 7, '2013-09-01', null),
(6, 8, '2015-09-01', '2021-07-01'),
(7, 8, '2021-07-01', null),
(6, 9, '2015-09-01', '2021-01-01'),
(7, 9, '2021-01-01', '2021-06-30'),
(8, 9, '2021-06-30', null);


-- связка специальностей учителей и видов уроков
create table speciality_lesson_types_map (
 speciality_id integer not null,
 lesson_type_id integer not null,
 constraint speciality_id_specialities_id_fkey FOREIGN KEY (speciality_id) REFERENCES specialities(id),
 constraint lesson_type_id_lesson_types_id_fkey FOREIGN KEY (lesson_type_id) REFERENCES lesson_types(id)
);

-- fulfill связка специальностей учителей и видов уроков
insert into speciality_lesson_types_map (speciality_id, lesson_type_id)
values
(1, 1),
(2, 2),
(3, 3),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);


-- проведеные уроки
create table lessons (
 id          integer not null primary key,
 dt          date  not null,--дата проведения урока
 lesson_type integer not null ,--вид проводимого урока (математика, литература, химия etc)
 teacher_id  integer not null ,--учитель, проводивший урок 
 class_id    integer not null ,--класс, присутствующий на занятии
 classroom_id integer not null ,--классная комната, где проводился урок
 constraint lesson_type_lesson_types_id_fkey FOREIGN KEY (lesson_type) REFERENCES lesson_types(id),
 constraint teacher_id_teachers_id_fkey FOREIGN KEY (teacher_id) REFERENCES teachers(id),
 CONSTRAINT class_id_class_id_fkey FOREIGN KEY (class_id) REFERENCES classes(id),
 constraint classroom_id_classrooms_id_fkey FOREIGN KEY (classroom_id) REFERENCES classrooms(id)
);


-- fulfill проведеные уроки
insert into lessons (id, dt, lesson_type, teacher_id, class_id, classroom_id)
values
(1, '2007-10-01', 1, 1, 1, 3),
(2, '2012-10-01', 2, 2, 2, 4),
(3, '2013-10-01', 3, 3, 3, 5),
(4, '2012-10-01', 5, 4, 4, 6),
(5, '2013-10-01', 6, 5, 5, 7),
(6, '2022-07-05', 1, 1, 1, 3),
(7, '2022-06-01', 10, 1, 1, 3),
(8, '2022-05-01', 10, 1, 1, 3),
(9, '2022-04-01', 10, 1, 1, 3),
(10, '2022-03-01', 10, 1, 1, 3),
(11, '2022-02-01', 10, 1, 1, 3),
(12, '2022-03-01', 10, 2, 2, 4),
(13, '2022-01-01', 10, 2, 3, 4),
(14, '2022-04-01', 1, 1, 1, 3),
(15, '2022-04-05', 1, 1, 1, 3),
(16, '2022-04-10', 1, 1, 1, 3),
(17, '2022-04-15', 1, 1, 1, 3),
(18, '2022-04-18', 1, 1, 1, 3),
(19, '2007-10-01', 7, 3, 3, 3),
(20, '2007-10-01', 7, 3, 2, 6),
(21, '2007-10-10', 7, 3, 2, 6),
(22, '2007-10-10', 7, 3, 3, 6),
(23, '2022-02-01', 1, 2, 4, 1),
(24, '2022-02-01', 2, 2, 4, 2),
(25, '2022-02-01', 2, 3, 4, 3),
(26, '2022-02-01', 3, 3, 4, 4),
(27, '2022-02-01', 5, 4, 4, 5),
(28, '2022-07-05', 2, 2, 4, 5),
(29, '2022-07-05', 5, 5, 4, 5),
(30, '2022-07-05', 2, 2, 4, 5),
(31, '2022-07-05', 3, 3, 4, 5),
(32, '2022-07-05', 1, 2, 4, 5),
(33, '2015-10-01', 1, 1, 1, 3),
(34, '2021-02-01', 1, 1, 1, 3),
(35, '2021-04-01', 1, 1, 10, 3),
(36, '2021-04-15', 2, 2, 10, 3),
(37, '2021-03-01', 1, 1, 1, 3),
(38, '2021-03-01', 1, 1, 10, 3),
(39, '2021-03-01', 1, 1, 3, 3),
(45, '2022-07-01', 1, 2, 1, 3),
(46, '2022-07-11', 2, 2, 1, 3),
(47, '2022-07-11', 3, 2, 1, 3),
(48, '2022-07-11', 6, 2, 1, 3),
(49, '2022-07-11', 5, 2, 1, 3)
;

insert into lessons (id, dt, lesson_type, teacher_id, class_id, classroom_id)
values
(50, '2021-03-01', 1, 1, 3, 3)
;


-- дневник успеваемости и посещения
create table lessons_diary (
 lesson_id  integer not null ,
 student_id integer not null ,
 is_absent  integer not null check (is_absent in (1, 0)),--признак отсутствия на уроке
 grade      integer,--полученная на уроке оценка
 grade_extra integer,--полученная на уроке оценка (дополнительная)
 constraint lesson_id_lessons_id_fkey FOREIGN KEY (lesson_id) REFERENCES lessons(id),
 constraint student_id_students_id_fkey FOREIGN KEY (student_id) REFERENCES students(id)
);

-- fulfill дневник успеваемости и посещения
insert into lessons_diary (lesson_id, student_id, is_absent, grade, grade_extra)
values
(1, 1, 1, 4, 3),
(2, 2, 0, null, null),
(3, 3, 1, 3, 5),
(4, 4, 0, null, null),
(5, 5, 1, 5, null),
(6, 2, 1, 3, 5),
(6, 3, 0, null, null),
(6, 5, 1, 4, null),
(19, 1, 1, 2, null),
(19, 2, 1, null, null),
(20, 1, 1, 4, null),
(20, 2, 0, null, null),
(21, 1, 1, 4, 3),
(21, 3, 1, 4, 3),
(22, 1, 1, 4, 3),
(22, 4, 1, 4, 3),
(23, 5, 1, 2, null),
(24, 5, 1, 2, null),
(25, 5, 1, 2, null),
(26, 5, 1, 2, null),
(27, 5, 1, 2, null),
(23, 4, 1, 2, null),
(24, 4, 1, 2, null),
(25, 4, 1, 2, null),
(26, 4, 1, 5, null),
(27, 4, 1, 2, null),
(23, 3, 1, 2, null),
(24, 3, 1, 2, null),
(25, 3, 1, 2, null),
(26, 3, 1, 2, null),
(11, 3, 1, 2, null),
(11, 5, 1, 2, null),
(5, 8, 1, 4, 3),
(10, 8, 1, 5, 5),
(33, 8, 1, 4, 3),
(33, 9, 1, 4, 3),
(34, 9, 1, 4, 5),
(32, 8, 1, 5, 5),
(32, 9, 1, 5, 5),
(37, 1, 0, null, null),
(38, 9, 0, null, null),
(38, 8, 0, null, null),
(39, 7, 0, null, null),
(36, 8, 1, 2, 3),
(39, 8, 0, null, null)
;
