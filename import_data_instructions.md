
# 📥 Інструкція з імпорту даних з Excel у SQL Server через SSMS


## 📁 Вхідні файли

- `installment_plan_table.xlsx` – таблиця контрактів
- `payment_table.xlsx` – таблиця оплат



## 🧩 Крок 1: Створіть таблиці в базі даних

### Таблиця `installment_plan`
```sql
CREATE TABLE installment_plan (
    contract_number INT NOT NULL,
    client_id INT NOT NULL,
    phone_id INT NOT NULL,
    color_id TINYINT NOT NULL,
    merchant_id TINYINT NOT NULL,
    price NUMERIC(10, 2) NULL,
    date_purch DATE NULL,
    qu_inst INT NOT NULL,
    inst INT NULL
);
```

### Таблиця `payments`
```sql
CREATE TABLE payments (
    merchant_id TINYINT NOT NULL,
    contract_number INT NOT NULL,
    date_payment DATE NULL,
    payment INT NULL
);
```

---

## 📥 Крок 2: Імпорт Excel-файлів у таблиці через SSMS

1. У SSMS натисніть **Object Explorer** → правою кнопкою на базі даних → **Tasks** → **Import Data...**
2. У майстрі виберіть джерело: **Microsoft Excel**
   - Вкажіть шлях до файлу `.xlsx`
   - Виберіть лист, де знаходяться дані
3. В якості місця призначення оберіть:
   - **SQL Server Native Client** або **Microsoft OLE DB Provider for SQL Server**
   - Введіть ім'я сервера, базу даних
4. Вкажіть таблицю призначення (наприклад, `installment_plan` або `payments`)
5. Натисніть **Finish**

> ⚠️ Перевірте відповідність типів даних!

---

## ✅ Перевірка імпорту

```sql
SELECT TOP 10 * FROM installment_plan;
SELECT TOP 10 * FROM payments;
```

---

Інструкція підготовлена для курсового проєкту "SQL для бізнес-аналізу"
