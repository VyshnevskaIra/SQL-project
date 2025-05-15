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
