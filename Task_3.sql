--Требуется описать таблицу для хранения расписания уроков (schedule) и встроить ее в существующую 
--структуру таблиц
-- расписание
drop table schedule;
create table schedule (
 id integer not null primary key,
 year_id integer not null,
 week_day varchar(9) not null check (week_day in ( 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday')),
 lesson_numb integer not null,
 lesson_id integer not null,
 constraint schdl_lesson_id_lessons_id_fkey FOREIGN KEY (lesson_id) REFERENCES lessons(id),
 constraint schdl_lesson_numb_lesson_time_lesson_numb_fkey FOREIGN KEY (lesson_numb) REFERENCES lesson_time(lesson_numb),
 constraint schdl_year_id_year_study_id_fkey FOREIGN KEY (year_id) REFERENCES year_study(id)
 );

--год обучения
create table year_study (
 id integer not null primary key,
 date_study_begin date not null check (extract ('month' from date_study_begin) = 9 and extract ('day' from date_study_begin) = 1),
 date_study_finish date not null check (extract ('month' from date_study_begin) = 8 and extract ('day' from date_study_begin) = 31)
 );

--время уроков
--drop table lesson_time;
create table lesson_time (
 lesson_numb integer not null primary key check (lesson_numb < 9),
 lesson_time_start time with time zone not null,
 lesson_time_end time with time zone not null
);




--Предоставить анализ описанной выше схемы БД, с примерами как можно было бы сделать оптимальнее в плане 
--хранения и обращения к таблицам, необходимых индексов и т.п.

-- ученики
create table students (
 id integer not null primary key, 
 first_name   varchar(50) not null, --имя
 last_name    varchar(50) not null, --фамилия
 birthdate    date    not null,--день рождения
 male         varchar(1) not null check (male in ('M','F'))--пол
);

-- специализации учителей
create table specialities (
 id  integer not null primary key,
 name varchar(50) not null--наименование специализации
);

insert into specialities (id, name)
values (1, 'Math');

-- виды уроков (математика, литература, химия etc)
create table lesson_types (
 id  integer not null primary key,
 name varchar(20) not null--наименование урока
);

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

-- учителя
create table teachers_personal (
 id           integer  not null primary key,
 first_name   varchar(50) not null,--имя
 last_name    varchar(50) not null,--фамилия
 birthdate    date    not null,--день рождения
 male         varchar(1) not null check(male in ('M','F'))--пол
 );

--insert into teachers_personal (id,first_name,last_name,birthdate,male)
--values (1, 'Lolik', 'Lolikov', '1990-01-01', 'M');

-- учителя
--drop table teachers;
create table teachers (
 id 		  integer  not null primary key,
 tp_id        integer  not null,
 start_date   date    not null,--дата, когда был нанят на работы
 end_date     date,--дата, когда был уволен с работы
 speciality_id integer  not null,--специализация
 constraint speciality_id_specialities_id_fkey FOREIGN KEY (speciality_id) REFERENCES specialities(id),
 constraint teachers_id_tp_id_fkey FOREIGN KEY (tp_id) REFERENCES teachers_personal(id)
);

--insert into teachers (id,tp_id,start_date,end_date,speciality_id)
--values (2, 1, '2005-09-01', null, 1);
--update teachers set end_date = '2022-08-31' where id = 2;
--select * from teachers_history ;

-- ученические классы
--drop table classes;
create table classes_info (
 id          integer not null primary key,
 letter      varchar(1) not null, --буква класса: А/Б/В etc
 "name"      varchar(20), --имя класса, выбранное по желанию учеников (напр, имена принято выбирать по названиям галактик: Андромеда, Млечный Путь, Скульптор etc)
 start_year  date not null,--год, когда класс был сформирован из первоклашек 
 end_year    date  --год окончания школы учениками класса
);

-- ученические классы
--drop table classes;
create table classes (
 id          integer not null primary key,
 ci_id		 integer not null,
 form_teacher integer not null, --классный руководитель
 head_student integer,  --староста
 main_class  integer, --основная классная комната 
 constraint form_teacher_teachers_id_fkey FOREIGN KEY (form_teacher) REFERENCES teachers(id),
 constraint head_student_students_id_fkey FOREIGN KEY (head_student) REFERENCES students(id),
 constraint main_class_classrooms_id_fkey FOREIGN KEY (main_class) REFERENCES classrooms(id),
 constraint ci_id_classes_info_id_fkey FOREIGN KEY (ci_id) REFERENCES classes_info(id)
);

-- связка классов и учеников
create table class_students_map (
 class_id  integer not null,
 student_id integer not null,--дата зачисления в класс
 start_date date  not null, --дата отчисления из класса
 end_date  date,
 CONSTRAINT class_id_student_id_pkey PRIMARY KEY (class_id, student_id),
 constraint class_id_classes_id_fkey FOREIGN KEY (class_id) REFERENCES classes(id),
 constraint student_id_students_id_fkey FOREIGN KEY (student_id) REFERENCES students(id)
);

-- связка специальностей учителей и видов уроков
create table speciality_lesson_types_map (
 speciality_id integer not null,
 lesson_type_id integer not null,
 CONSTRAINT speciality_id_lesson_type_id_pkey PRIMARY KEY (speciality_id, lesson_type_id),
 constraint speciality_id_specialities_id_fkey FOREIGN KEY (speciality_id) REFERENCES specialities(id),
 constraint lesson_type_id_lesson_types_id_fkey FOREIGN KEY (lesson_type_id) REFERENCES lesson_types(id)
);

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

-- дневник успеваемости и посещения
--drop table lessons_diary;
create table lessons_diary (
 lesson_id  integer not null ,
 student_id integer not null ,
 is_absent  integer not null check (is_absent in (1, 0)),--признак отсутствия на уроке
 grade      integer,--полученная на уроке оценка
 grade_extra integer,--полученная на уроке оценка (дополнительная)
 CONSTRAINT lesson_id_student_id_pkey PRIMARY KEY (lesson_id, student_id),
 constraint lesson_id_lessons_id_fkey FOREIGN KEY (lesson_id) REFERENCES lessons(id),
 constraint student_id_students_id_fkey FOREIGN KEY (student_id) REFERENCES students(id)
);


--Создание триггерной функции
--drop table employee_salary_history;
create table teachers_history (
	id           integer  not null primary key,
 	first_name   varchar(50) not null,--имя
 	last_name    varchar(50) not null,--фамилия
 	birthdate    date    not null,--день рождения
 	male         varchar(1) not null check(male in ('M','F')),
 	start_date   date    not null,--дата, когда был нанят на работы
 	end_date     date,--дата, когда был уволен с работы
 	speciality_name varchar(50) not null --наименование специальности
	);

create or replace function teacher_leave() returns trigger as $$ --создаем функция для триггера
declare tpid integer = (select tp.id from teachers_personal tp --объявляем переменную чтобы корректно удалить данные
						join teachers t on t.tp_id = tp.id
						where t.id = new.id);
begin
	IF new.end_date is not null --условие срабатывания вставки и удаления (при доавблении даты ухода)
		THEN insert into teachers_history(id, first_name, last_name, birthdate, male, start_date, end_date, speciality_name) --заполняем таблицу историчности
		(select t.id, tp.first_name, tp.last_name, tp.birthdate, tp.male, t.start_date, t.end_date, s."name" from teachers t --данными из текущих таблиц
		join teachers_personal tp on tp.id = t.tp_id 
		join specialities s on s.id = t.speciality_id   
		where t.id = new.id);
		delete from teachers where (select id from teachers t) = new.id; --удаляем данные из таблицы учителей
		delete from teachers_personal where (select id from teachers_personal tp) = tpid; --удаляем данные из таблицы персональной информации учителей
	end if;
return new;
end;
$$ language plpgsql;

--drop trigger teacher_leave on teachers;
create trigger teacher_leave -- создаем триггер
after insert or update of end_date on teachers --вставка в таблицу и oбновление колонки (можно указать несколько колонок)
for each row execute function teacher_leave(); --действие выполняется для каждой строки таблицы учителей
