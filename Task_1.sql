--Представление и описание БД 
--Содержит разделы для:
--учета кораблей: заведение новых кораблей в базу, списание кораблей в утиль, техобслуживание;
--учета персонала: управление карточками сотрудников, найм и увольнение, зарплаты;
--учета закупок: закупки кораблей и комплектующих;
--учета добычи рыбы: выходы в море, учет добытой рыбы;

-- DROP TABLE city;
CREATE TABLE city ( --справочник городов для указания адресов компании, дока и тп
	city_id int4 NOT NULL, --айди города
	city varchar(50) NOT NULL, -- название города
	CONSTRAINT city_pkey PRIMARY KEY (city_id)
);

insert into city (city_id, city)
values(2, 'Sochi'),
values(1, 'Astrkhan');

-- DROP TABLE emp_type;
CREATE TABLE emp_type ( --тип сотрудника штатный, проектный и тп
	emp_type_id int4 NOT NULL, --айди типа устройства сотрудника
	emp_type varchar(100) NOT NULL, --тип устройства сотрудника
	CONSTRAINT emp_type_pkey PRIMARY KEY (emp_type_id)
);

insert into emp_type (emp_type_id, emp_type)
values
(1, 'Permanent'),
(2, 'Project');

-- DROP TABLE grade_salary;
CREATE TABLE grade_salary ( 
	grade int4 NOT NULL, --градация зп сотрудников
	min_salary numeric(12, 2) NOT NULL, --минимальная зп для грейда
	max_salary numeric(12, 2) NOT NULL, --максимальная зп для грейда
	CONSTRAINT grade_salary_pkey PRIMARY KEY (grade)
);

insert into grade_salary (grade, min_salary, max_salary)
values
(1, 10000, 20000),
(2, 20000, 40000);

-- DROP TABLE person;
CREATE TABLE person ( --таблица с персональной информацией сотрудников
	person_id int4 NOT NULL, 
	first_name varchar(250) NOT NULL, 
	middle_name varchar(250) NULL, 
	last_name varchar(250) NOT NULL, 
	taxpayer_number varchar(40) NOT NULL, --номер налогоплательщика
	dob date NULL, --дата рождения
	CONSTRAINT person_pkey PRIMARY KEY (person_id)
);

insert into person (person_id, first_name, middle_name , last_name, taxpayer_number, dob)
values
(1, 'Alesha', null, 'Pipkov', 4440, '1990-10-01'),
(2, 'Misha', null, 'Kosolapov', 3330, '1995-08-23');

-- DROP TABLE address;
CREATE TABLE address ( --таблица с адресами локации рабочих позиций
	address_id int4 NOT NULL,
	full_address varchar(250) NOT NULL,
	city_id int4 NOT NULL,
	postal_code varchar(10) NULL, --почтовый индекс
	CONSTRAINT address_pkey PRIMARY KEY (address_id),
	CONSTRAINT address_city_id_fkey FOREIGN KEY (city_id) REFERENCES city(city_id) --ссылка на 
);

insert into address (address_id, full_address, city_id, postal_code)
values
(1, 'Astrkhan, Lenina 2, 45', 1, 111111),
(2, 'Sochi, lenina 5, 35', 2, 222222);

-- DROP TABLE "position";
CREATE TABLE "position" ( --содержит инфу о позициях в компании
	pos_id int4 NOT NULL, -- айди позиции
	pos_title varchar(250) NOT NULL, --наименование позиции
	pos_category varchar(100) NULL, --категория позиции (специалист, инженер, менеджер и тп)
	department varchar(100) not NULL, --отдел которому принадлежит позиция
	grade int4 NULL, --грейд соответствующий позции
	address_id int4 NULL, --адрес айди где лоцируется позиция
	manager_pos_id int4 NULL, --айди позиции прямого руководителя
	CONSTRAINT position_pkey PRIMARY KEY (pos_id), 
	CONSTRAINT position_address_id_fkey FOREIGN KEY (address_id) REFERENCES address(address_id), --внешнаяя ссылка на айди адресов справочника
	CONSTRAINT position_grade_fkey FOREIGN KEY (grade) REFERENCES grade_salary(grade)
);

insert into "position" (pos_id, pos_title, pos_category, department, grade, address_id, manager_pos_id)
values
(1, 'Fishman', 'Specialist', 'Fish catch', 1, 1, null),
(2, 'Serviceman', 'Engineer', 'Service dep', 2, 2, null);

-- DROP TABLE employee;
CREATE TABLE employee (--инф-цию о сотрудниках компании
	emp_id int4 NOT NULL,
	emp_type_id int4 NOT NULL, --тип устройства сотрудника
	person_id int4 NOT NULL, --айди персонализации
	pos_id int4 NOT NULL, --айди позиции в компании
	rate numeric(12, 2) NOT NULL, --рабочая ставка (1 - полная, 0.5 полставки и тп)
	hire_date date NOT NULL, --дата устройства сотрудника
	CONSTRAINT employee_pkey PRIMARY KEY (emp_id),
	CONSTRAINT employee_emp_type_id_fkey FOREIGN KEY (emp_type_id) REFERENCES emp_type(emp_type_id), --внешная ссылка на тип стуройства
	CONSTRAINT employee_person_id_fkey FOREIGN KEY (person_id) REFERENCES person(person_id), --внешняя ссылка на персональную инфомрацию
	CONSTRAINT employee_pos_id_fkey FOREIGN KEY (pos_id) REFERENCES "position"(pos_id) --внешняя ссылка на справочник позиции в компании
);

insert into employee (emp_id, emp_type_id, person_id, pos_id, rate, hire_date)
values
(1, 1, 1, 1, 1, '2010-01-01'),
(2, 2, 2, 2, 1, '2011-02-02');

-- DROP TABLE employee_salary;
CREATE TABLE employee_salary ( --информация о зп сотрудников и ее изменении
	order_id int4 NOT NULL, --номер приказа о изменении зп
	emp_id int4 NOT NULL, --айди сотрудника
	salary numeric(12, 2) NOT NULL, --уровень зп
	effective_from date NOT NULL, --дата утверждения уровня зп
	CONSTRAINT employee_salary_pkey PRIMARY KEY (order_id),
	CONSTRAINT employee_salary_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES employee(emp_id) 
);

-- DROP TABLE vacancy;
CREATE TABLE vacancy ( --информация о вакансиях открытых в компании
	vac_id int4 NOT NULL, --айди вакансии
	vac_title varchar(250) NOT NULL, --наименование вакансии
	pos_id int4 NOT NULL, --айди позции
	create_date date NOT NULL, --дата открытия вакансии
	closure_date date NULL, --дата закрытия вакансии
	researcher_flag int4 NULL, --активна или не активна
	recruiter_id int4 NULL, --айди сотрудника отдела hr
	CONSTRAINT vacancy_pkey PRIMARY KEY (vac_id),
	CONSTRAINT vacancy_pos_id_fkey FOREIGN KEY (pos_id) REFERENCES "position"(pos_id), --внешняя ссылка на айди позиции
	CONSTRAINT vacancy_recruiter_id_fkey FOREIGN KEY (recruiter_id) REFERENCES employee(emp_id) --внешняя ссылка на сотрудников hr
);

-- DROP TABLE candidate;
CREATE TABLE candidate ( --информация о кандидатах на вакансию
	candidate_id int4 NOT NULL, 
	vac_id int4 NOT NULL, --айди вакансии для кандидата
	rec_source varchar(100) NULL, --источник найма (сайт, агентсво и тп)
	interviews int4 NOT NULL, --количество интревью
	status varchar(100) NOT NULL, -- статус кандидата
	CONSTRAINT candidate_pkey PRIMARY KEY (candidate_id),
	CONSTRAINT candidate_vac_id_fkey FOREIGN KEY (vac_id) REFERENCES vacancy(vac_id)
);

--drop table craft_info;
create table craft_info (
	id int4 NOT null primary key,
	model varchar(50) not null,
	manufacturer varchar(50) not null,
	tech_description text --заполняется опционально
);

insert into craft_info (id, model, manufacturer, tech_description) --for requests tests
values
(1, 'model 110', 'GidroPon', 'N/A');

--drop table crafts;
create table crafts (
	id int4 NOT null primary key,
	craft_info_id int4 NOT null,
	CONSTRAINT craft_info_id_craft_info_id_fkey FOREIGN KEY (craft_info_id) REFERENCES craft_info(id)
);

insert into crafts (id, craft_info_id)
values (1, 1);

--drop table component_info;
create table component_info (
	id int4 NOT null primary key,
	model varchar(50) not null,
	manufacturer varchar(50) not null,
	tech_description text
);

insert into component_info (id, model, manufacturer, tech_description)
values
(1, 'model 110', 'TopGear', 'Gear'),
(2, 'model 220', 'DownGaer', 'Gear');

--drop table component;
create table component (
	id int4 NOT null primary key,
	component_info_id int4 NOT null,
	CONSTRAINT component_info_id_component_info_id_fkey FOREIGN KEY (component_info_id) REFERENCES component_info(id)
);

insert into component (id, component_info_id)
values
(1, 1),
(2, 2),
(3, 2);

--drop table service_dock;
create table service_dock (
	id int4 NOT null primary key,
	"name" varchar(50) not null
);

insert into service_dock (id, "name")
values
(1, 'Sochi dock');

--drop table parking_dock;
create table parking_dock (
	id int4 NOT null primary key,
	"name" varchar(50) not null
);

--drop table craft_status;
create table craft_status (
	id int4 NOT null primary key,
	craft_id int4 NOT null,
	status varchar(12) not null check (status in ('buy', 'delivery', 'registration', 'parking', 'fishing', 'service', 'utilization')), --статус коробля может принимать ограниченное количество значений
	emp_id int4 NOT null,
	start_dt timestamp with time zone not null, --дата и время начала действия статуса
	end_dt timestamp with time zone , -- дата и время окончания дествия статуса, если null, то в процессе
	"comments" text, -- для комментириев при необходимости
	CONSTRAINT craft_id_crafts_id_fkey FOREIGN KEY (craft_id) REFERENCES crafts(id),
	CONSTRAINT craft_s_emp_id_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES employee(emp_id)
);

insert into craft_status (id, craft_id, status, emp_id, start_dt, end_dt)
values
(1, 1, 'buy', 1, '2010-01-02', '2010-01-12'),
(2, 1, 'delivery', 1, '2010-01-12', '2010-01-16'),
(3, 1, 'registration', 1, '2010-01-16', '2010-01-18'),
(4, 1, 'fishing', 1, '2010-01-19', '2010-01-19'),
(5, 1, 'service', 2, '2010-01-20', '2010-01-21'),
(6, 1, 'fishing', 1, '2010-01-22', '2010-01-22');

--drop table components_status;
create table components_status (
	id int4 NOT null primary key,
	component_id int4 NOT null,
	status varchar(12) not null check (status in ('buy', 'delivery', 'registration', 'wharehous', 'service', 'utilization')),--статус детали может принимать ограниченное количество значений
	emp_id int4 NOT null, --сотрудник выполняющий работу
	start_dt timestamp with time zone not null, --дата и время начала действия статуса
	end_dt timestamp with time zone ,-- дата и время окончания дествия статуса, если null, то в процессе
	"comments" text, -- для комментириев при необходимости
	CONSTRAINT component_id_component_id_fkey FOREIGN KEY (component_id) REFERENCES component(id),
	CONSTRAINT cs_emp_id_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES employee(emp_id)
);

insert into components_status (id, component_id, status, emp_id, start_dt, end_dt)
values
(1, 1, 'service', 2, '2010-01-20', '2010-01-21'),
(2, 2, 'service', 2, '2010-01-21', '2010-01-21'),
(3, 3, 'wharehous', 2, '2010-01-20', null);

--drop table parking_map;
create table parking_map (
	id int4 NOT null primary key,
	parking_dock_id int4 NOT null,
	craft_status_id int4 NOT null,
	CONSTRAINT parking_dock_id_parking_dock_id_fkey FOREIGN KEY (parking_dock_id) REFERENCES parking_dock(id),
	CONSTRAINT craft_status_id_craft_status_id_fkey FOREIGN KEY (craft_status_id) REFERENCES craft_status(id)
);

--drop table service_map;
create table service_map (
	id int4 NOT null primary key,
	service_dock_id int4 NOT null,
	craft_status_id int4 NOT null,
	components_status_id int4 null,
	issue_description text not null,
	CONSTRAINT sm_service_dock_id_service_dock_id_fkey FOREIGN KEY (service_dock_id) REFERENCES service_dock(id),
	CONSTRAINT sm_craft_status_id_craft_status_id_fkey FOREIGN KEY (craft_status_id) REFERENCES craft_status(id),
	CONSTRAINT sm_components_status_id_components_status_id_fkey FOREIGN KEY (components_status_id) REFERENCES components_status(id)
);

insert into service_map (id, service_dock_id, craft_status_id, components_status_id, issue_description)
values
(1, 1, 5, 1, 'N/A'),
(2, 1, 5, 2, 'N/A');

--drop table craft_cost_map;
create table craft_cost_map (
	id int4 NOT null primary key,
	craft_status_id int4 NOT null,
	price double precision not null,
	CONSTRAINT ccm_craft_status_id_craft_status_id_fkey FOREIGN KEY (craft_status_id) REFERENCES craft_status(id)
);

insert into craft_cost_map (id, craft_status_id, price)
values
(1, 1, 10000000),
(2, 2, 20000);

--drop table component_cost_map;
create table component_cost_map (
	id int4 NOT null primary key,
	component_status_id int4 NOT null,
	price double precision not null,
	CONSTRAINT ccm_components_status_id_components_status_id_fkey FOREIGN KEY (component_status_id) REFERENCES components_status(id)
);

insert into component_cost_map (id, component_status_id, price)
values
(1, 1, 10000),
(2, 2, 5000);

drop table fish_amount;
create table fish_amount (
	craft_status_id int4 NOT null primary key,
	amount double precision not null,
	CONSTRAINT fm_craft_status_id_craft_status_id_fkey FOREIGN KEY (craft_status_id) REFERENCES craft_status(id)
);

insert into fish_amount (craft_status_id, amount)
values
(4, 100),
(6, 80);

--drop table salary_payments;
create table salary_payments (
	order_id int4 NOT null,
	payment_date date not null,
	CONSTRAINT sp_craft_order_id_fkey FOREIGN KEY (order_id) REFERENCES employee_salary(order_id)
);



--Требуется написать SQL запросы для различного рода отчетности:
--1) агрегированный отчет по доходу и расходам компании в разрезе каждого судна
select 
	cs.craft_id as "id корабля",
	sum(ccm.price) + sum(ccm2.price) as "суммарные расходы",
	sum(fa.amount) * 50 as "суммарные доходы" --50 стоимость кг рыбы
from craft_status cs  
left join craft_cost_map ccm on cs.id = ccm.craft_status_id --сопоставление затрат с кораблями
left join fish_amount fa on fa.craft_status_id = cs.id --сопоставление кораблей, затрат с прибылью
left join service_map sm on sm.craft_status_id = cs.id 
left join component_cost_map ccm2 on ccm2.component_status_id = sm.components_status_id 
group by cs.craft_id ; --группировка по кораблям для расчета суммарных расходов и даходов

--2) детализированный отчет по ежемесячным выплатам зарплаты сотрудникам
select 
	date_trunc('month', sp.payment_date) as "год, месяц выплаты", --усечение даты выплат зп до месяца
	es.emp_id as "id сотрудника", 
	sum (es.salary) as "суммарное количество выплат сотдрунику за месяц" --рассчет зп за месяц для каждого сотрудника
from salary_payments sp 
join employee_salary es on es.order_id = sp.order_id --сопоставление уровня зп сотрудников с датой выплат
group by date_trunc('month', sp.payment_date), es.emp_id  ; --группировка по месяцам и далее по сотрудникам для рассчета зп за месяц каждого сотрудника

--3) отчет по ежедневному улову компании
select 
	cs.end_dt::date as "дата",
	sum(fa.amount) as "ежедневный улов компании" --рассчет суммы улова в кг за один день компанией
from craft_status cs
join fish_amount fa on cs.id = fa.craft_status_id --присоединяем таблицу для сопоставления улова и дат заершения рыбалки
group by cs.end_dt::date; --группировка по дню возвращения с рыбалки для рассчета улова

--4) агрегированный отчет по еженедельному кол-ву выходов в море, пойманному улову, задействованных рыбаков
select
	cs.emp_id as "id сотрудника",
	extract ('week' from cs.end_dt) as "номер недели", --извлекаем номер недели из даты заершения рыбалки
	count(cs.id) as "кол-во выходов в море", --подсчитываем количество выходов в море за неделю
	sum(fa.amount) as "пойманный улов, кг" --рассчитываекм сумму пойманного улова в кг
from craft_status cs 
left join fish_amount fa on fa.craft_status_id = cs.id
where cs.status = 'fishing'
group by cs.emp_id, extract ('week' from cs.end_dt); --группировка по сотрудникам, а затем по неделям для агрегирующих функции

