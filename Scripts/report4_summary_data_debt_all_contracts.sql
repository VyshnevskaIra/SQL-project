--КРОК 3. РОЗРОБКА ЗВІТІВ (SQL-ЗАПИТІВ)

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

