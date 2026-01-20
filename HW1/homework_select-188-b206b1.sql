/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select  
    StockItemID,
    StockItemName 
from 
    Warehouse.StockItems
where 
    StockItemName like '%urgent%' 
    OR StockItemName like '%Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select 
    s.SupplierID, 
    s.SupplierName
from 
    Purchasing.Suppliers as s
left join Purchasing.PurchaseOrders as po
    on s.SupplierID = po.SupplierID
where 
    po.PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/


select
    o.OrderID,
    FORMAT(o.OrderDate, 'dd.MM.yyyy') as OrderDate,
    DATENAME(month, o.OrderDate)      as OrderMonthName,
    DATEPART(QUARTER, o.OrderDate)    as OrderQuarter,
    (MONTH(o.OrderDate) - 1) / 4 + 1  as OrderThirdOfYear,
    c.CustomerName                    as Customer
from Sales.Orders o
join Sales.Customers c
    on o.CustomerID = c.CustomerID
where
    o.PickingCompletedWhen is not null
    and exists (
        select 1
        from Sales.OrderLines ol
        where ol.OrderID = o.OrderID
          and (ol.UnitPrice > 100 or ol.Quantity > 20)
    )
order by
    OrderQuarter,
    OrderThirdOfYear,
    o.OrderDate
offset 1000 rows
fetch next 100 rows only;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select 
    dm.DeliveryMethodName,
    po.ExpectedDeliveryDate,
    s.SupplierName,
        p.PreferredName
from Purchasing.PurchaseOrders as po
join Application.DeliveryMethods as dm
    on po.DeliveryMethodID = dm.DeliveryMethodID
join Application.People as p
    on p.PersonID = po.ContactPersonID
join Purchasing.Suppliers as s
    on s.SupplierID = po.SupplierID
where 
    po.ExpectedDeliveryDate >= '2013-01-01'
    and po.ExpectedDeliveryDate < '2013-02-01'
    and po.IsOrderFinalized = 1
    and (dm.DeliveryMethodName = 'Air Freight'
    or dm.DeliveryMethodName = 'Refrigerated Air Freight')

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10 
        i.InvoiceDate as SaleDate,
        c.CustomerName as Customer,
        p.FullName as Salesman
from Sales.Invoices as i
join Sales.Orders as o
    on i.OrderID = o.OrderID
join Sales.Customers as c
    on c.CustomerID = o.CustomerID
join Application.People as p
    on p.PersonID = o.SalespersonPersonID
order by 
    i.InvoiceDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select 
    c.CustomerId, 
    c.CustomerName, 
    c.PhoneNumber
from Sales.Customers as c
join Sales.Orders as o
    on c.CustomerID = o.CustomerID
join Sales.OrderLines as ol
    on o.OrderID = ol.OrderID
join Warehouse.StockItems as si
    on ol.StockItemID = si.StockItemID
where 
    StockItemName = 'Chocolate frogs 250g'