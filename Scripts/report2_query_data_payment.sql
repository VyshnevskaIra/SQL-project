--КРОК 3. РОЗРОБКА ЗВІТІВ (SQL-ЗАПИТІВ)

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
