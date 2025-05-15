--КРОК 3. РОЗРОБКА ЗВІТІВ (SQL-ЗАПИТІВ)
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

