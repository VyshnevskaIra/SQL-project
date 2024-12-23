--КРОК 1. СТВОРЕННЯ ТАБЛИЦЬ В БАЗІ ДАНИИХ

CREATE TABLE installment_plan
(
contract_number int NOT NULL,
client_id int NOT NULL,
phone_id int NOT NULL,
color_id tinyint NOT NULL,
merchant_id tinyint NOT NULL,
price numeric(10, 2) NULL,
date_purch date NULL,
qu_inst int NOT NULL,
inst int NULL
)

CREATE TABLE payments
(
merchant_id tinyint NOT NULL,
contract_number int NOT NULL,
date_payment date NULL,
payment int NULL
)
alter table installment_plan
add constraint contract_number_M_PK primary key (contract_number,merchant_id)

alter table installment_plan add constraint FKclient_Id foreign key (client_id)
	references clients (client_id)
alter table installment_plan add constraint FKphone_id foreign key (phone_id)
	references phones (phone_id)
alter table installment_plan add constraint FKcolor_id foreign key (color_id)
	references colors (color_id)
alter table installment_plan add constraint FKmerchant_id foreign key (merchant_id)
	references merchants (merchant_id)

alter table payments add constraint contract_number_M_FK foreign key (contract_number,merchant_id)
references installment_plan (contract_number,merchant_id)
alter table payments add constraint FKpmerchant_id foreign key (merchant_id)
	references merchants (merchant_id)

--КРОК 2. ІМПОРТ ДАНИХ
--перевірка
select * from installment_plan

select * from payments

--КРОК 3. РОЗРОБКА ЗВІТІВ (SQL-ЗАПИТІВ)
--I.1. SQL-ЗАПИТ - вибір даних про контракти розстрочки

select i.merchant_id as 'Інд. продавця', i.contract_number as 'Номер контракта розстрочки'
, m.merchant_name as 'Назва продавця', c.client_name as 'ПІБ клієнта'
,b.Brand_name as 'Назва бренда',p.phone_name as 'Назва телефона',co.color_name as 'Колір телефона'
,i.qu_inst as 'Кількість місяців за умовами договору розсточки'
,i.inst as 'Рзмір одного щомісячного взноса'
, i.date_purch as 'Дата покупки та оплати першого взноса по розсточці'
,case 
when datediff(mm,i.date_purch,'2020-04-30')+1>=i.qu_inst then i.qu_inst
when datediff(mm,i.date_purch,'2020-04-30')+1<i.qu_inst then datediff(mm,i.date_purch,'2020-04-30')+1
end as 'Кількість щомісячних взносів, що повинні бути сплачені на останній день звітного місяця'
,(case 
when datediff(mm,i.date_purch,'2020-04-30')+1>=i.qu_inst then i.qu_inst
when datediff(mm,i.date_purch,'2020-04-30')+1<i.qu_inst then datediff(mm,i.date_purch,'2020-04-30')+1
end)*i.inst as 'Сума щомісячних взносів (грн), що повинні бути сплачені на останній день звітного місяця'
from installment_plan i
left join merchants m on m.merchant_id=i.merchant_id
left join clients c on c.client_id=i.client_id
left join phones p on p.phone_id=i.phone_id
left join brands b on b.brand_id=p.brand_id
left join colors co on co.color_id=i.color_id
where i.merchant_id=44 and i.contract_number=1229

--I.2. SQL-запрос - вибір даних про платежі контракту розстрочки
create function my_period(@begin_date date,@end_date date) returns @month_period table(p_year smallint,p_month tinyint)
begin
declare @cur_date date
set @cur_date=@begin_date
while datediff(mm,@cur_date,@end_date)>=0
begin
insert into @month_period(p_year,p_month) values(year(@cur_date),month(@cur_date))
set @cur_date=dateadd(mm,1,@cur_date)
end
return
end

select 
e.merchant_id as 'Інд. продавця'
,e.contract_number as 'Номер контракта розстрочки'
,case when e.inst1>0 then e.p_year else null end as 'Рік, коли повинен бути сплачений кожен взнос за умовами контракта розстрочки'
,case when e.inst1>0 then e.p_month else null end as 'Місяць, коли повинен бути сплачений кожен взнос за умовами контракта розстрочки'
,e.inst1 as 'Розмір одного щомісячного взноса в гривнях'
,case when e.payment1>0 then e.date_payment else null end as 'Дата платежа клїєнта'
,e.payment1 as 'Оплачена клієнтом сума'
from
(
select d.dataa,d.date_pay_purch
,d.contract_number
,d.merchant_id
,d.data_pay_1
,d.data_pay
,d.date_purch
,d.date_end
,d.qu_inst
,d.inst
,d.p_year
,d.p_month
,d.date_payment
,case when row_number() over (partition by d.contract_number,d.merchant_id,d.date_pay_purch order by d.contract_number,d.merchant_id)>1
then 0
when d.data_pay>d.date_end then 0
else d.inst end as inst1
,case when d.data_pay_1 is null then 0 else d.payment end as payment1
,row_number() over (partition by d.contract_number,d.merchant_id,d.date_pay_purch order by d.contract_number,d.merchant_id) as rn_date
,case when d.data_pay_1 is null and row_number() over (partition by d.contract_number,d.merchant_id,d.date_pay_purch order by d.contract_number,d.merchant_id)>1
then null 
else d.date_pay_purch end as data_pay_2
from (
select b.dataa
,b.contract_number
,b.merchant_id
,b.date_payment
,b.data_pay
,b.data_pay_1
,b.p_year
,b.p_month
,b.payment
,c.date_purch
,c.data_purch
,c.date_end
,c.qu_inst
,c.inst
,max(b.data_pay_1) over (partition by b.contract_number,b.merchant_id) as max_data_pay
,count(b.data_pay_1) over (partition by b.contract_number,b.merchant_id,b.dataa) as count_data_pay
,case when b.dataa=b.data_pay_1 then b.dataa
when b.dataa>max(b.data_pay_1) over (partition by b.contract_number,b.merchant_id) 
or b.dataa>c.date_end then null
when b.data_pay_1 is null and count(b.data_pay_1) over (partition by b.contract_number,b.merchant_id,b.dataa)>0 then null
when b.dataa=FORMAT(dateadd(mm,1,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,2,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,3,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,4,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,5,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,6,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,7,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,8,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,9,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,10,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,11,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa=FORMAT(dateadd(mm,12,b.date_payment),'yyyy-MM') then b.dataa
when b.dataa>b.data_pay then b.dataa
when b.dataa<b.data_pay then null
else '0' end as date_pay_purch
from (
select FORMAT(DATEFROMPARTS(a.p_year,a.p_month,'01'),'yyyy-MM') as dataa
,a.p_year
,a.p_month
,p.*
,FORMAT(p.date_payment,'yyyy-MM') as data_pay
,case when FORMAT(DATEFROMPARTS(a.p_year,a.p_month,'01'),'yyyy-MM')=FORMAT(p.date_payment,'yyyy-MM')
then FORMAT(p.date_payment,'yyyy-MM')
else null end as data_pay_1
from dbo.my_period('01.01.2018','05.01.2020') a, payments p
where p.merchant_id=67 and p.contract_number=227 
) b
left join (select i.*
,FORMAT(i.date_purch,'yyyy-MM') as data_purch
,FORMAT(dateadd(mm,i.qu_inst-1,i.date_purch),'yyyy-MM') as date_end
from installment_plan i
) c on c.merchant_id=b.merchant_id and c.contract_number=b.contract_number
) d
where d.date_pay_purch is not null
) e
where e.data_pay_2 is not null
order by e.dataa,e.data_pay,e.data_pay_1

--I.3. SQL-запит - вибір підсумкових даних про платежі контракту розстрочки
with payment_3 as (
select 
	merchant_id
	,contract_number
	,sum(payment) as sum_payment
from payments
group by merchant_id
	,contract_number)
select i.merchant_id as 'Инд. продавця'
	,i.contract_number as 'Номер контракта розстрочки'
,(case 
when datediff(mm,i.date_purch,'2020-04-30')+1>=i.qu_inst then i.qu_inst
when datediff(mm,i.date_purch,'2020-04-30')+1<i.qu_inst then datediff(mm,i.date_purch,'2020-04-30')+1
end)*i.inst as 'Сума щомісячних взносів (грн), що повинна бути оплачена на останній день звітного місяця'
,p3.sum_payment as 'Оплаченая клієнтом сума'
,i.inst*i.qu_inst-p3.sum_payment as 'Залишок по контракту розстрочки всього'
,(case 
when datediff(mm,i.date_purch,'2020-04-30')+1>=i.qu_inst then i.qu_inst
when datediff(mm,i.date_purch,'2020-04-30')+1<i.qu_inst then datediff(mm,i.date_purch,'2020-04-30')+1
end)*i.inst-p3.sum_payment as 'Залишок по контракту розстрочки, в тому числі заборгованність через недоплати щомісячних взносів'
from installment_plan i
left join payment_3 p3 on p3.merchant_id=i.merchant_id and p3.contract_number=i.contract_number
where i.merchant_id=84 and i.contract_number=228


--II. SQL-запит - вивід підсумкових данних для звіту про заборгованість по всім контрактам 
--розстрочки. Звітний місяць – квітень 2020 р. (Станом на 30.04.2020)

select 
	i2.pr as 'Період розстрочки'
	,c.nalich_zadolj as 'Наявність заборгованості'
	,sum(c.inst_dog) as 'Cума розстрочки'
	,sum(i2.opl) as 'Сума, що повинна бути сплачена на останній день звітного місяця'
	,sum(c.pay_all) as 'Сума, що сплачена на останній день звітного місяця'
	,count(i2.contract_number) as 'Кількість клієнтів'
	,sum(c.zadolj_all) as 'Заборгованість'
	,sum(i2.oz) as 'Залишок по розстрочці без врахування заборгованості'
	,count(c.z_0) as 'Кількість клієнтів без прострочених платежів'
	,count(c.z_1) as 'Кількість клієнтів з простроченим платежем 1 місяць'
	,count(c.z_2) as 'Кількість клієнтів з простроченими платежами 2 місяці'
	,count(c.z_3) as 'Кількість клієнтів з простроченими платежами 3 місяці'
	,count(c.z_4_plus) as 'Кількість клієнтів з простроченими платежами 4 місяці і більше'
	,sum(c.zd_0) as 'Сума заборгованості клієнтів без прострочки платежів'
	,sum(c.zd_1) as 'Сума заборгованості клієнтів з прострочкою 1 місяць'
	,sum(c.zd_2) as 'Сума заборгованості клієнтів з прострочкою 2 месяці'
	,sum(c.zd_3) as 'Сума заборгованості клієнтів з прострочкою 3 месяці'
	,sum(c.zd_4_plus) as 'Сума заборгованості клієнтів з прострочкою 4 місяці і більше'
from
	(
	select *
	,case 
		when datediff(mm,i.date_purch,'2020-04-30')>=i.qu_inst then 'Завершений'
		else 'Не завершений'	end as pr --'Період розстрочки'
	,datediff(mm,i.date_purch,'2020-04-30') as dd
	,case 
		when datediff(mm,i.date_purch,'2020-04-30')<i.qu_inst then i.inst*datediff(mm,i.date_purch,'2020-04-30')
		else i.inst*i.qu_inst end as opl --'Сума, що повинна бути сплачена на останній день звітного місяця'
	,case
		when datediff(mm,i.date_purch,'2020-04-30')>=i.qu_inst then 0
		else -datediff(mm,dateadd(mm,i.qu_inst-1,i.date_purch),'2020-04-30')*i.inst end as oz
	from installment_plan i
	) as i2
left join (select p.merchant_id,p.contract_number
			,sum(p.payment) as payment --'Сума, що сплачена на останній день звітного місяця'
			from payments p
			group by p.merchant_id,p.contract_number
			) p2 
			on p2.merchant_id=i2.merchant_id and p2.contract_number=i2.contract_number
left join (select 
b.merchant_id
,b.contract_number
,b.month_zadolj
,case when b.zadolj_all=0 then 'Немає заборгованості' else 'Є заборгованість' end as nalich_zadolj
,case when b.month_zadolj=0 then 1 else null end as z_0
,case when b.month_zadolj=1 then 1 else null end as z_1
,case when b.month_zadolj=2 then 1 else null end as z_2
,case when b.month_zadolj=3 then 1 else null end as z_3
,case when b.month_zadolj>=4 then 1 else null end as z_4_plus
,case when b.month_zadolj=0 then b.zadolj_all else null end as zd_0
,case when b.month_zadolj=1 then b.zadolj_all else null end as zd_1
,case when b.month_zadolj=2 then b.zadolj_all else null end as zd_2
,case when b.month_zadolj=3 then b.zadolj_all else null end as zd_3
,case when b.month_zadolj>=4 then b.zadolj_all else null end as zd_4_plus
,b.zadolj_all
,b.inst_dog
,b.pay_all
from(
select
a.merchant_id
,a.contract_number
,a.qu_inst
,a.date_payment
,a.zadolj_all
,a.inst_dog
,a.pay_all
,sum(a.opl_dog) over (partition by a.merchant_id,a.contract_number) as count_opl_dog
,a.qu_inst-sum(a.opl_dog) over (partition by a.merchant_id,a.contract_number) as month_zadolj
,ROW_NUMBER() over (partition by a.merchant_id,a.contract_number order by a.merchant_id,a.contract_number,a.date_payment) as rn_1_str
from (
select 
i.merchant_id
,i.contract_number
,i.qu_inst
,i.inst*i.qu_inst as inst_dog
,sum(p.payment) over (partition by i.merchant_id,i.contract_number) as pay_all
,i.inst*i.qu_inst - sum(p.payment) over (partition by i.merchant_id,i.contract_number) as zadolj_all
,p.payment
,p.date_payment
,ROW_NUMBER() over (partition by i.merchant_id,i.contract_number,format(p.date_payment,'yyyy-MM') order by format(p.date_payment,'yyyy-MM')) as rn_povtor_opl
,case when format(p.date_payment,'yyyy-MM')>format(dateadd(mm,i.qu_inst-1,i.date_purch),'yyyy-MM') then 0 
when ROW_NUMBER() over (partition by i.merchant_id,i.contract_number,format(p.date_payment,'yyyy-MM') order by format(p.date_payment,'yyyy-MM'))>1
then 0
else 1 end as opl_dog
from payments p
left join installment_plan i on i.merchant_id=p.merchant_id and i.contract_number=p.contract_number
--order by i.merchant_id,i.contract_number,p.date_payment
--where p.merchant_id=44 and p.contract_number=1229
) a
) b
where b.rn_1_str=1
) c
			on c.merchant_id=i2.merchant_id and c.contract_number=i2.contract_number

group by i2.pr,c.nalich_zadolj

