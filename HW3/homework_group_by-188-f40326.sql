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

use WideWorldImporters

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
    YEAR(si.InvoiceDate) as SalesYear,
    MONTH(si.InvoiceDate) as SalesMonth,
    AVG(sil.UnitPrice) as AvgPricePerMonth,
    SUM(sil.Quantity * sil.UnitPrice) as TotalSalesPerMonth
from Sales.Invoices as si
inner join Sales.InvoiceLines as sil
    on sil.InvoiceID = si.InvoiceID
group by
    YEAR(si.InvoiceDate),
    MONTH(si.InvoiceDate)
order by
    SalesYear,
    SalesMonth;

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
    YEAR(si.InvoiceDate) as SalesYear,
    MONTH(si.InvoiceDate) as SalesMonth,
    SUM(sil.Quantity * sil.UnitPrice) as TotalSalesPerMonth
from Sales.Invoices as si
inner join Sales.InvoiceLines as sil
    on sil.InvoiceID = si.InvoiceID
group by
    YEAR(si.InvoiceDate),
    MONTH(si.InvoiceDate)
having SUM(sil.Quantity * sil.UnitPrice) > 4600000
order by
    SalesYear,
    SalesMonth;

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
    YEAR(si.InvoiceDate) as SalesYear,
    MONTH(si.InvoiceDate) as SalesMonth,
    wsi.StockItemName,
    SUM(sil.Quantity * sil.UnitPrice) as TotalSales,
    MIN(si.InvoiceDate) as FirstSaleDate,
    SUM(sil.Quantity) as TotalQuantity
from Sales.Invoices as si
inner join Sales.InvoiceLines as sil
    on sil.InvoiceID = si.InvoiceID
inner join Warehouse.StockItems as wsi
    on wsi.StockItemID = sil.StockItemID
group by
    YEAR(si.InvoiceDate),
    MONTH(si.InvoiceDate),
    wsi.StockItemName
having SUM(sil.Quantity) < 50
order by
    SalesYear,
    SalesMonth,
    wsi.StockItemName;

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.

*/
;with Months as (
    select
        DATEFROMPARTS(YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)), 1) as MinMonthStart,
        DATEFROMPARTS(YEAR(MAX(InvoiceDate)), MONTH(MAX(InvoiceDate)), 1) as MaxMonthStart
    from Sales.Invoices
    union all
    select DATEADD(MONTH, 1, MinMonthStart), MaxMonthStart
    from Months
    where MinMonthStart < MaxMonthStart
),
MonthlySales as (
    select
        DATEFROMPARTS(YEAR(si.InvoiceDate), MONTH(si.InvoiceDate), 1) as MonthStart,
        SUM(sil.Quantity * sil.UnitPrice) as TotalSalesPerMonth
    from Sales.Invoices as si
    inner join Sales.InvoiceLines as sil
        on sil.InvoiceID = si.InvoiceID
    group by DATEFROMPARTS(YEAR(si.InvoiceDate), MONTH(si.InvoiceDate), 1)
)
select
    YEAR(m.MinMonthStart) as SalesYear,
    MONTH(m.MinMonthStart) as SalesMonth,
    ISNULL(ms.TotalSalesPerMonth, 0) as TotalSalesPerMonth
from Months as m
left join MonthlySales as ms
    on ms.MonthStart = m.MinMonthStart
order by
    SalesYear,
    SalesMonth
option (maxrecursion 0);

;with Months as (
    select
        DATEFROMPARTS(YEAR(MIN(InvoiceDate)), MONTH(MIN(InvoiceDate)), 1) as MinMonthStart,
        DATEFROMPARTS(YEAR(MAX(InvoiceDate)), MONTH(MAX(InvoiceDate)), 1) as MaxMonthStart
    from Sales.Invoices
    union all
    select DATEADD(MONTH, 1, MinMonthStart), MaxMonthStart
    from Months
    where MinMonthStart < MaxMonthStart
),
ItemMonthlySales as (
    select
        DATEFROMPARTS(YEAR(si.InvoiceDate), MONTH(si.InvoiceDate), 1) as MonthStart,
        wsi.StockItemName,
        SUM(sil.Quantity * sil.UnitPrice) as TotalSales,
        MIN(si.InvoiceDate) as FirstSaleDate,
        SUM(sil.Quantity) as TotalQuantity
    from Sales.Invoices as si
    inner join Sales.InvoiceLines as sil
        on sil.InvoiceID = si.InvoiceID
    inner join Warehouse.StockItems as wsi
        on wsi.StockItemID = sil.StockItemID
    group by
        DATEFROMPARTS(YEAR(si.InvoiceDate), MONTH(si.InvoiceDate), 1),
        wsi.StockItemName
    having SUM(sil.Quantity) < 50
)
select
    YEAR(m.MinMonthStart) as SalesYear,
    MONTH(m.MinMonthStart) as SalesMonth,
    ims.StockItemName,
    ISNULL(ims.TotalSales, 0) as TotalSales,
    ims.FirstSaleDate,
    ISNULL(ims.TotalQuantity, 0) as TotalQuantity
from Months as m
left join ItemMonthlySales as ims
    on ims.MonthStart = m.MinMonthStart
order by
    SalesYear,
    SalesMonth,
    ims.StockItemName
option (maxrecursion 0);
