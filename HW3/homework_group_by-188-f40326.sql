/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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

USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
    YEAR(si.InvoiceDate) as Sales_Year,
    MONTH(si.InvoiceDate) as Sales_Month,
    AVG(sil.UnitPrice) as AvgPriceMonth,
    SUM(sil.Quantity * sil.UnitPrice) as SumSalesMonth
from Sales.Invoices as si
join Sales.InvoiceLines as sil
on si.InvoiceID = sil.InvoiceID
group by YEAR(si.InvoiceDate), MONTH(si.InvoiceDate)
order by Sales_Year, Sales_Month

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
select 
    YEAR(si.InvoiceDate) as Sales_Year,
    MONTH(si.InvoiceDate) as Sales_Month,
    SUM(sil.Quantity * sil.UnitPrice) as SumSalesMonth
from Sales.Invoices as si
join Sales.InvoiceLines as sil
on si.InvoiceID = sil.InvoiceID
group by YEAR(si.InvoiceDate), MONTH(si.InvoiceDate)
having SUM(sil.UnitPrice * sil.Quantity) > 4600000
order by Sales_Year, Sales_Month

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select 
    YEAR(si.InvoiceDate) AS Sales_Year,
    MONTH(si.InvoiceDate) AS Sales_Month,
    wsi.StockItemName,
    SUM(sil.Quantity * sil.UnitPrice) AS SumSales,
    MIN(si.InvoiceDate) AS FirstSaleDate,
    SUM(sil.Quantity) AS TotalQuantity
from Sales.Invoices AS si
join Sales.InvoiceLines AS sil
    on si.InvoiceID = sil.InvoiceID
join Warehouse.StockItems AS wsi
    on sil.StockItemID = wsi.StockItemID
group by YEAR(si.InvoiceDate), MONTH(si.InvoiceDate), wsi.StockItemName
having SUM(sil.Quantity) < 50
order by Sales_Year, Sales_Month, wsi.StockItemName;

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
