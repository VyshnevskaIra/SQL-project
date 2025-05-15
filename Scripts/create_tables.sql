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
