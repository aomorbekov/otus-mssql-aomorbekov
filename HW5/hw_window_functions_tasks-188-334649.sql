/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

use WideWorldImporters
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

;with invoice_amounts as (
    select
        i.InvoiceID,
        i.CustomerID,
        i.InvoiceDate,
        datefromparts(year(i.InvoiceDate), month(i.InvoiceDate), 1) as month_start,
        sum(il.Quantity * il.UnitPrice) as sale_amount
    from Sales.Invoices as i
    inner join Sales.InvoiceLines as il
        on il.InvoiceID = i.InvoiceID
    where i.InvoiceDate >= '2015-01-01'
    group by
        i.InvoiceID,
        i.CustomerID,
        i.InvoiceDate
),
month_totals as (
    select
        ia.month_start,
        sum(ia.sale_amount) as month_amount
    from invoice_amounts as ia
    group by
        ia.month_start
)
select
    ia.InvoiceID,
    c.CustomerName,
    ia.InvoiceDate,
    ia.sale_amount,
    (
        select sum(mt.month_amount)
        from month_totals as mt
        where mt.month_start <= ia.month_start
    ) as running_total_by_month
from invoice_amounts as ia
inner join Sales.Customers as c
    on c.CustomerID = ia.CustomerID
order by
    ia.InvoiceDate,
    ia.InvoiceID;

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

set statistics time, io on;

-- вариант без оконной функции
;with invoice_amounts as (
    select
        i.InvoiceID,
        i.CustomerID,
        i.InvoiceDate,
        datefromparts(year(i.InvoiceDate), month(i.InvoiceDate), 1) as month_start,
        sum(il.Quantity * il.UnitPrice) as sale_amount
    from Sales.Invoices as i
    inner join Sales.InvoiceLines as il
        on il.InvoiceID = i.InvoiceID
    where i.InvoiceDate >= '2015-01-01'
    group by
        i.InvoiceID,
        i.CustomerID,
        i.InvoiceDate
),
month_totals as (
    select
        ia.month_start,
        sum(ia.sale_amount) as month_amount
    from invoice_amounts as ia
    group by
        ia.month_start
)
select
    ia.InvoiceID,
    c.CustomerName,
    ia.InvoiceDate,
    ia.sale_amount,
    (
        select sum(mt.month_amount)
        from month_totals as mt
        where mt.month_start <= ia.month_start
    ) as running_total_by_month
from invoice_amounts as ia
inner join Sales.Customers as c
    on c.CustomerID = ia.CustomerID
order by
    ia.InvoiceDate,
    ia.InvoiceID;

-- вариант с оконной функцией
;with invoice_amounts as (
    select
        i.InvoiceID,
        i.CustomerID,
        i.InvoiceDate,
        datefromparts(year(i.InvoiceDate), month(i.InvoiceDate), 1) as month_start,
        sum(il.Quantity * il.UnitPrice) as sale_amount
    from Sales.Invoices as i
    inner join Sales.InvoiceLines as il
        on il.InvoiceID = i.InvoiceID
    where i.InvoiceDate >= '2015-01-01'
    group by
        i.InvoiceID,
        i.CustomerID,
        i.InvoiceDate
),
month_totals as (
    select
        ia.month_start,
        sum(ia.sale_amount) as month_amount
    from invoice_amounts as ia
    group by
        ia.month_start
),
month_running as (
    select
        mt.month_start,
        sum(mt.month_amount) over (
            order by mt.month_start
            rows between unbounded preceding and current row
        ) as running_total_by_month
    from month_totals as mt
)
select
    ia.InvoiceID,
    c.CustomerName,
    ia.InvoiceDate,
    ia.sale_amount,
    mr.running_total_by_month
from invoice_amounts as ia
inner join month_running as mr
    on mr.month_start = ia.month_start
inner join Sales.Customers as c
    on c.CustomerID = ia.CustomerID
order by
    ia.InvoiceDate,
    ia.InvoiceID;

set statistics time, io off;

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;with month_item_sales as (
    select
        datefromparts(year(i.InvoiceDate), month(i.InvoiceDate), 1) as month_start,
        il.StockItemID,
        sum(il.Quantity) as sold_quantity
    from Sales.Invoices as i
    inner join Sales.InvoiceLines as il
        on il.InvoiceID = i.InvoiceID
    where i.InvoiceDate >= '2016-01-01'
        and i.InvoiceDate < '2017-01-01'
    group by
        datefromparts(year(i.InvoiceDate), month(i.InvoiceDate), 1),
        il.StockItemID
),
ranked_items as (
    select
        mis.month_start,
        mis.StockItemID,
        mis.sold_quantity,
        row_number() over (
            partition by mis.month_start
            order by mis.sold_quantity desc, mis.StockItemID
        ) as rn
    from month_item_sales as mis
)
select
    ri.month_start,
    ri.StockItemID,
    si.StockItemName,
    ri.sold_quantity
from ranked_items as ri
inner join Warehouse.StockItems as si
    on si.StockItemID = ri.StockItemID
where ri.rn <= 2
order by
    ri.month_start,
    ri.rn;

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select
    si.StockItemID,
    si.StockItemName,
    si.Brand,
    si.UnitPrice,
    row_number() over (
        partition by left(si.StockItemName, 1)
        order by si.StockItemName, si.StockItemID
    ) as row_num_by_first_letter,
    count(*) over () as total_items_count,
    count(*) over (partition by left(si.StockItemName, 1)) as items_count_by_first_letter,
    lead(si.StockItemID) over (
        order by si.StockItemName, si.StockItemID
    ) as next_stockitem_id,
    lag(si.StockItemID) over (
        order by si.StockItemName, si.StockItemID
    ) as prev_stockitem_id,
    lag(si.StockItemName, 2, 'No items') over (
        order by si.StockItemName, si.StockItemID
    ) as stockitem_name_2_rows_back,
    ntile(30) over (order by si.TypicalWeightPerUnit) as weight_group_30
from Warehouse.StockItems as si
order by
    si.StockItemName,
    si.StockItemID;

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

;with invoice_amounts as (
    select
        i.InvoiceID,
        i.SalespersonPersonID,
        i.CustomerID,
        i.InvoiceDate,
        sum(il.Quantity * il.UnitPrice) as sale_amount
    from Sales.Invoices as i
    inner join Sales.InvoiceLines as il
        on il.InvoiceID = i.InvoiceID
    where i.SalespersonPersonID is not null
    group by
        i.InvoiceID,
        i.SalespersonPersonID,
        i.CustomerID,
        i.InvoiceDate
),
ranked_sales as (
    select
        ia.*,
        row_number() over (
            partition by ia.SalespersonPersonID
            order by ia.InvoiceDate desc, ia.InvoiceID desc
        ) as rn
    from invoice_amounts as ia
)
select
    p.PersonID as employee_id,
    case
        when charindex(' ', reverse(p.FullName)) = 0 then p.FullName
        else right(p.FullName, charindex(' ', reverse(p.FullName)) - 1)
    end as employee_last_name,
    c.CustomerID,
    c.CustomerName,
    rs.InvoiceDate,
    rs.sale_amount
from ranked_sales as rs
inner join Application.People as p
    on p.PersonID = rs.SalespersonPersonID
inner join Sales.Customers as c
    on c.CustomerID = rs.CustomerID
where rs.rn = 1
order by
    p.PersonID;

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;with customer_item_purchases as (
    select
        i.CustomerID,
        il.StockItemID,
        il.UnitPrice,
        i.InvoiceDate,
        row_number() over (
            partition by i.CustomerID, il.StockItemID
            order by il.UnitPrice desc, i.InvoiceDate desc, i.InvoiceID desc
        ) as rn_item
    from Sales.Invoices as i
    inner join Sales.InvoiceLines as il
        on il.InvoiceID = i.InvoiceID
),
best_price_per_item as (
    select
        cip.CustomerID,
        cip.StockItemID,
        cip.UnitPrice,
        cip.InvoiceDate
    from customer_item_purchases as cip
    where cip.rn_item = 1
),
ranked_items as (
    select
        bpi.*,
        row_number() over (
            partition by bpi.CustomerID
            order by bpi.UnitPrice desc, bpi.StockItemID
        ) as rn_customer
    from best_price_per_item as bpi
)
select
    c.CustomerID,
    c.CustomerName,
    ri.StockItemID,
    ri.UnitPrice,
    ri.InvoiceDate
from ranked_items as ri
inner join Sales.Customers as c
    on c.CustomerID = ri.CustomerID
where ri.rn_customer <= 2
order by
    c.CustomerID,
    ri.rn_customer;

-- Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность.
