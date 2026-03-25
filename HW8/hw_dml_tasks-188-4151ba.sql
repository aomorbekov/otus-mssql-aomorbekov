/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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

delete from sales.customers
where customername in
(
    'hw8 customer 1',
    'hw8 customer 2',
    'hw8 customer 2 updated',
    'hw8 customer 3',
    'hw8 customer 4',
    'hw8 customer 5'
);

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

insert into sales.customers
(
    customerid,
    customername,
    billtocustomerid,
    customercategoryid,
    buyinggroupid,
    primarycontactpersonid,
    alternatecontactpersonid,
    deliverymethodid,
    deliverycityid,
    postalcityid,
    creditlimit,
    accountopeneddate,
    standarddiscountpercentage,
    isstatementsent,
    isoncredithold,
    paymentdays,
    phonenumber,
    faxnumber,
    deliveryrun,
    runposition,
    websiteurl,
    deliveryaddressline1,
    deliveryaddressline2,
    deliverypostalcode,
    postaladdressline1,
    postaladdressline2,
    postalpostalcode,
    lasteditedby
)
select
    next value for sequences.customerid,
    v.customername,
    c.billtocustomerid,
    c.customercategoryid,
    c.buyinggroupid,
    c.primarycontactpersonid,
    c.alternatecontactpersonid,
    c.deliverymethodid,
    c.deliverycityid,
    c.postalcityid,
    c.creditlimit,
    cast(getdate() as date),
    c.standarddiscountpercentage,
    c.isstatementsent,
    c.isoncredithold,
    c.paymentdays,
    v.phonenumber,
    v.faxnumber,
    c.deliveryrun,
    c.runposition,
    v.websiteurl,
    c.deliveryaddressline1,
    c.deliveryaddressline2,
    c.deliverypostalcode,
    c.postaladdressline1,
    c.postaladdressline2,
    c.postalpostalcode,
    c.lasteditedby
from sales.customers as c
cross join
(
    values
        ('hw8 customer 1', '+7 (700) 000-00-01', '+7 (700) 000-00-11', 'http://hw8-customer-1'),
        ('hw8 customer 2', '+7 (700) 000-00-02', '+7 (700) 000-00-12', 'http://hw8-customer-2'),
        ('hw8 customer 3', '+7 (700) 000-00-03', '+7 (700) 000-00-13', 'http://hw8-customer-3'),
        ('hw8 customer 4', '+7 (700) 000-00-04', '+7 (700) 000-00-14', 'http://hw8-customer-4'),
        ('hw8 customer 5', '+7 (700) 000-00-05', '+7 (700) 000-00-15', 'http://hw8-customer-5')
) as v(customername, phonenumber, faxnumber, websiteurl)
where c.customerid = 1;

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete from sales.customers
where customername = 'hw8 customer 1';


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update sales.customers
set
    customername = 'hw8 customer 2 updated',
    phonenumber = '+7 (700) 111-11-11',
    faxnumber = '+7 (700) 111-11-22',
    websiteurl = 'http://hw8-customer-2-updated'
where customername = 'hw8 customer 2';

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

merge sales.customers as target
using
(
    select
        'hw8 merge customer' as customername,
        c.billtocustomerid,
        c.customercategoryid,
        c.buyinggroupid,
        c.primarycontactpersonid,
        c.alternatecontactpersonid,
        c.deliverymethodid,
        c.deliverycityid,
        c.postalcityid,
        c.creditlimit,
        cast(getdate() as date) as accountopeneddate,
        c.standarddiscountpercentage,
        c.isstatementsent,
        c.isoncredithold,
        c.paymentdays,
        '+7 (700) 222-22-22' as phonenumber,
        '+7 (700) 222-22-33' as faxnumber,
        c.deliveryrun,
        c.runposition,
        'http://hw8-merge-customer' as websiteurl,
        c.deliveryaddressline1,
        c.deliveryaddressline2,
        c.deliverypostalcode,
        c.postaladdressline1,
        c.postaladdressline2,
        c.postalpostalcode,
        c.lasteditedby
    from sales.customers as c
    where c.customerid = 1
) as source
on target.customername = source.customername
when matched then
    update
    set
        target.customername = source.customername,
        target.phonenumber = '+7 (700) 333-33-33',
        target.faxnumber = '+7 (700) 333-33-44',
        target.websiteurl = 'http://hw8-merge-customer-updated',
        target.lasteditedby = source.lasteditedby
when not matched then
    insert
    (
        customername,
        billtocustomerid,
        customercategoryid,
        buyinggroupid,
        primarycontactpersonid,
        alternatecontactpersonid,
        deliverymethodid,
        deliverycityid,
        postalcityid,
        creditlimit,
        accountopeneddate,
        standarddiscountpercentage,
        isstatementsent,
        isoncredithold,
        paymentdays,
        phonenumber,
        faxnumber,
        deliveryrun,
        runposition,
        websiteurl,
        deliveryaddressline1,
        deliveryaddressline2,
        deliverypostalcode,
        postaladdressline1,
        postaladdressline2,
        postalpostalcode,
        lasteditedby
    )
    values
    (
        source.customername,
        source.billtocustomerid,
        source.customercategoryid,
        source.buyinggroupid,
        source.primarycontactpersonid,
        source.alternatecontactpersonid,
        source.deliverymethodid,
        source.deliverycityid,
        source.postalcityid,
        source.creditlimit,
        source.accountopeneddate,
        source.standarddiscountpercentage,
        source.isstatementsent,
        source.isoncredithold,
        source.paymentdays,
        source.phonenumber,
        source.faxnumber,
        source.deliveryrun,
        source.runposition,
        source.websiteurl,
        source.deliveryaddressline1,
        source.deliveryaddressline2,
        source.deliverypostalcode,
        source.postaladdressline1,
        source.postaladdressline2,
        source.postalpostalcode,
        source.lasteditedby
    );

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

exec sp_configure 'show advanced options', 1;
reconfigure;
exec sp_configure 'xp_cmdshell', 1;
reconfigure;

exec master..xp_cmdshell 'if not exist "c:\temp" mkdir "c:\temp"', no_output;

drop table if exists dbo.hw8_invoice_lines;

select top (0)
    invoiceid,
    stockitemid,
    description
into dbo.hw8_invoice_lines
from sales.invoicelines;

exec master..xp_cmdshell 'bcp "select top 10 invoiceid, stockitemid, description from wideworldimporters.sales.invoicelines order by invoicelineid" queryout "c:\temp\hw8_invoice_lines.txt" -S .\COURSE2025 -T -w -t"|" -r"\n"', no_output;

bulk insert dbo.hw8_invoice_lines
from 'c:\temp\hw8_invoice_lines.txt'
with
(
    datafiletype = 'widechar',
    fieldterminator = '|',
    rowterminator = '\n'
);

exec sp_configure 'xp_cmdshell', 0;
reconfigure;
exec sp_configure 'show advanced options', 0;
reconfigure;
