/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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
set quoted_identifier on;

/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/


declare @columns nvarchar(max);
declare @columns_with_isnull nvarchar(max);
declare @sql nvarchar(max);

select @columns = stuff((
    select
        ',' + quotename(c.customername)
    from sales.customers as c
    order by c.customername
    for xml path(''), type
).value('.', 'nvarchar(max)'), 1, 1, '');

select @columns_with_isnull = stuff((
    select
        ',isnull(' + quotename(c.customername) + ', 0) as ' + quotename(c.customername)
    from sales.customers as c
    order by c.customername
    for xml path(''), type
).value('.', 'nvarchar(max)'), 1, 1, '');

set @sql = N'select convert(varchar(10), p.invoicemonth, 104) as invoicemonth, '
    + @columns_with_isnull
    + N' from (
        select
            dateadd(month, datediff(month, 0, i.invoicedate), 0) as invoicemonth,
            c.customername,
            count(*) as purchases_count
        from sales.invoices as i
        inner join sales.customers as c on c.customerid = i.customerid
        group by
            dateadd(month, datediff(month, 0, i.invoicedate), 0),
            c.customername
    ) as s
    pivot (
        sum(purchases_count)
        for customername in (' + @columns + N')
    ) as p
    order by p.invoicemonth;';

exec sp_executesql @sql;
