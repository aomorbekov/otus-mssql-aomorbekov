/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

use WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select
    p.PersonID,
    p.FullName
from Application.People as p
where p.IsSalesperson = 1
    and p.PersonID not in (
        select i.SalespersonPersonID
        from Sales.Invoices as i
        where i.InvoiceDate = '2015-07-04'
    )
order by
    p.PersonID;

;with sales_on_date as (
    select distinct
        i.SalespersonPersonID
    from Sales.Invoices as i
    where i.InvoiceDate = '2015-07-04'
)
select
    p.PersonID,
    p.FullName
from Application.People as p
left join sales_on_date as s
    on s.SalespersonPersonID = p.PersonID
where p.IsSalesperson = 1
    and s.SalespersonPersonID is null
order by
    p.PersonID;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

select
    si.StockItemID,
    si.StockItemName,
    si.UnitPrice
from Warehouse.StockItems as si
where si.UnitPrice = (
    select min(UnitPrice)
    from Warehouse.StockItems
)
order by
    si.StockItemID;

select
    si.StockItemID,
    si.StockItemName,
    si.UnitPrice
from Warehouse.StockItems as si
inner join (
    select min(UnitPrice) as MinUnitPrice
    from Warehouse.StockItems
) as m
    on si.UnitPrice = m.MinUnitPrice
order by
    si.StockItemID;

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

select distinct
    c.CustomerID,
    c.CustomerName,
    ct.TransactionAmount,
    ct.TransactionDate
from Sales.Customers as c
inner join Sales.CustomerTransactions as ct
    on ct.CustomerID = c.CustomerID
where ct.TransactionAmount in (
    select top (5)
        TransactionAmount
    from Sales.CustomerTransactions
    order by
        TransactionAmount desc
)
order by
    ct.TransactionAmount desc,
    c.CustomerID;

select
    c.CustomerID,
    c.CustomerName,
    t.TransactionAmount,
    t.TransactionDate
from Sales.Customers as c
inner join (
    select top (5)
        CustomerID,
        TransactionAmount,
        TransactionDate
    from Sales.CustomerTransactions
    order by
        TransactionAmount desc
) as t
    on t.CustomerID = c.CustomerID
order by
    t.TransactionAmount desc,
    c.CustomerID;

;with top_payments as (
    select top (5)
        ct.CustomerID,
        ct.TransactionAmount,
        ct.TransactionDate
    from Sales.CustomerTransactions as ct
    order by
        ct.TransactionAmount desc
)
select
    c.CustomerID,
    c.CustomerName,
    tp.TransactionAmount,
    tp.TransactionDate
from top_payments as tp
inner join Sales.Customers as c
    on c.CustomerID = tp.CustomerID
order by
    tp.TransactionAmount desc,
    c.CustomerID;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

select distinct
    city.CityID,
    city.CityName,
    p.FullName as PackedByPerson
from Sales.Invoices as i
inner join Sales.InvoiceLines as il
    on il.InvoiceID = i.InvoiceID
inner join Sales.Customers as c
    on c.CustomerID = i.CustomerID
inner join Application.Cities as city
    on city.CityID = c.DeliveryCityID
left join Application.People as p
    on p.PersonID = i.PackedByPersonID
where il.StockItemID in (
    select top (3)
        si.StockItemID
    from Warehouse.StockItems as si
    order by
        si.UnitPrice desc
)
order by
    city.CityID,
    p.FullName;

;with top_items as (
    select top (3)
        si.StockItemID
    from Warehouse.StockItems as si
    order by
        si.UnitPrice desc
)
select distinct
    city.CityID,
    city.CityName,
    p.FullName as PackedByPerson
from top_items as ti
inner join Sales.InvoiceLines as il
    on il.StockItemID = ti.StockItemID
inner join Sales.Invoices as i
    on i.InvoiceID = il.InvoiceID
inner join Sales.Customers as c
    on c.CustomerID = i.CustomerID
inner join Application.Cities as city
    on city.CityID = c.DeliveryCityID
left join Application.People as p
    on p.PersonID = i.PackedByPersonID
order by
    city.CityID,
    p.FullName;

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

/*
этот запрос показывает счета, дату, продавца, сумму по счету и сумму по собранному заказу.

я упростил его так:
* вместо подзапроса для продавца сделал join
* вместо подзапроса для заказа тоже сделал join
* суммы сначала посчитал в отдельных подзапросах

так запрос проще читать и удобнее сравнивать по statistics io, time
*/

set statistics io, time on;

select
    i.InvoiceID,
    i.InvoiceDate,
    p.FullName as SalesPersonName,
    it.TotalSumm as TotalSummByInvoice,
    ot.TotalSummForPickedItems
from Sales.Invoices as i
inner join (
    select
        il.InvoiceID,
        sum(il.Quantity * il.UnitPrice) as TotalSumm
    from Sales.InvoiceLines as il
    group by
        il.InvoiceID
    having sum(il.Quantity * il.UnitPrice) > 27000
) as it
    on it.InvoiceID = i.InvoiceID
left join Application.People as p
    on p.PersonID = i.SalespersonPersonID
left join Sales.Orders as o
    on o.OrderID = i.OrderID
    and o.PickingCompletedWhen is not null
left join (
    select
        ol.OrderID,
        sum(ol.PickedQuantity * ol.UnitPrice) as TotalSummForPickedItems
    from Sales.OrderLines as ol
    group by
        ol.OrderID
) as ot
    on ot.OrderID = o.OrderID
order by
    it.TotalSumm desc;

set statistics io, time off;
