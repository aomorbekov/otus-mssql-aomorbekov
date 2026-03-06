/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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

use wideworldimporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select
    convert(varchar(10), invoicemonth, 104) as invoicemonth,
    isnull([Peeples Valley, AZ], 0) as [Peeples Valley, AZ],
    isnull([Medicine Lodge, KS], 0) as [Medicine Lodge, KS],
    isnull([Gasport, NY], 0) as [Gasport, NY],
    isnull([Sylvanite, MT], 0) as [Sylvanite, MT],
    isnull([Jessie, ND], 0) as [Jessie, ND]
from (
    select
        dateadd(month, datediff(month, 0, i.invoiceDate), 0) as invoicemonth,
        substring(c.customername, charindex('(', c.customername) + 1, charindex(')', c.customername) - charindex('(', c.customername) - 1) as customername,
        count(*) as orders_count
    from sales.invoices as i
    join sales.customers as c on c.customerid = i.customerid
    where c.customerid between 2 and 6
    group by dateadd(month, datediff(month, 0, i.invoiceDate), 0), c.customername
) as s
pivot (
    sum(orders_count) for customername in (
        [Peeples Valley, AZ],
        [Medicine Lodge, KS],
        [Gasport, NY],
        [Sylvanite, MT],
        [Jessie, ND]
    )
) as p
order by p.invoicemonth

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select
    c.customername,
    a.addressline
from sales.customers as c
cross apply (
    values
        (c.deliveryaddressline1),
        (c.deliveryaddressline2),
        (c.postaladdressline1),
        (c.postaladdressline2)
) as a(addressline)
where lower(c.customername) like '%tailspin toys%'
  and a.addressline is not null
  and ltrim(rtrim(a.addressline)) <> ''
order by c.customername, a.addressline

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select
    c.countryid,
    c.countryname,
    a.code
from application.countries as c
cross apply (
    values
        (c.isoalpha3code),
        (cast(c.isonumericcode as varchar(10)))
) as a(code)
where a.code is not null
order by c.countryid, a.code

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;
with t as (
    select
        c.customerid,
        c.customername,
        il.stockitemid,
        il.unitprice,
        i.invoicedate,
        row_number() over (partition by c.customerid order by il.unitprice desc, i.invoicedate desc) as rn
    from sales.invoices as i
    join sales.invoicelines as il on il.invoiceid = i.invoiceid
    join sales.customers as c on c.customerid = i.customerid
)
select
    customerid,
    customername,
    stockitemid,
    unitprice,
    invoicedate
from t
where rn <= 2
order by customerid, rn
