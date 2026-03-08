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

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

insert into sales.customers (
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
    deliverylocation,
    postaladdressline1,
    postaladdressline2,
    postalpostalcode,
    lasteditedby
)
select
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
    c.accountopeneddate,
    c.standarddiscountpercentage,
    c.isstatementsent,
    c.isoncredithold,
    c.paymentdays,
    c.phonenumber,
    c.faxnumber,
    c.deliveryrun,
    c.runposition,
    c.websiteurl,
    c.deliveryaddressline1,
    c.deliveryaddressline2,
    c.deliverypostalcode,
    c.deliverylocation,
    c.postaladdressline1,
    c.postaladdressline2,
    c.postalpostalcode,
    1
from (
    values
        ('otus student customer 188-01'),
        ('otus student customer 188-02'),
        ('otus student customer 188-03'),
        ('otus student customer 188-04'),
        ('otus student customer 188-05')
) as v(customername)
cross join (
    select top (1)
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
        deliverylocation,
        postaladdressline1,
        postaladdressline2,
        postalpostalcode
    from sales.customers
    where customerid = 1
) as c
where not exists (
    select 1
    from sales.customers as x
    where x.customername = v.customername
);

select customerid, customername
from sales.customers
where customername like 'otus student customer 188-%'
order by customerid;

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete from sales.customers
where customername = 'otus student customer 188-05';

select customerid, customername
from sales.customers
where customername like 'otus student customer 188-%'
order by customerid;


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update sales.customers
set
    phonenumber = '+7 (700) 188-0001',
    websiteurl = 'https://otus.example/hw8-customer-188-01',
    lasteditedby = 1
where customername = 'otus student customer 188-01';

select customerid, customername, phonenumber, websiteurl
from sales.customers
where customername = 'otus student customer 188-01';

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

merge sales.customers as target
using (
    select
        cast('otus student customer 188-merge' as nvarchar(100)) as customername,
        c.billtocustomerid,
        c.customercategoryid,
        c.buyinggroupid,
        c.primarycontactpersonid,
        c.alternatecontactpersonid,
        c.deliverymethodid,
        c.deliverycityid,
        c.postalcityid,
        c.creditlimit,
        c.accountopeneddate,
        c.standarddiscountpercentage,
        c.isstatementsent,
        c.isoncredithold,
        c.paymentdays,
        cast('+7 (700) 188-0099' as nvarchar(40)) as phonenumber,
        cast('+7 (700) 188-0199' as nvarchar(40)) as faxnumber,
        c.deliveryrun,
        c.runposition,
        cast('https://otus.example/hw8-merge' as nvarchar(512)) as websiteurl,
        c.deliveryaddressline1,
        c.deliveryaddressline2,
        c.deliverypostalcode,
        c.deliverylocation,
        c.postaladdressline1,
        c.postaladdressline2,
        c.postalpostalcode,
        cast(1 as int) as lasteditedby
    from (
        select top (1)
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
            deliveryrun,
            runposition,
            deliveryaddressline1,
            deliveryaddressline2,
            deliverypostalcode,
            deliverylocation,
            postaladdressline1,
            postaladdressline2,
            postalpostalcode
        from sales.customers
        where customerid = 1
    ) as c
) as source
on target.customername = source.customername
when matched then
    update set
        target.phonenumber = source.phonenumber,
        target.faxnumber = source.faxnumber,
        target.websiteurl = source.websiteurl,
        target.lasteditedby = source.lasteditedby
when not matched then
    insert (
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
        deliverylocation,
        postaladdressline1,
        postaladdressline2,
        postalpostalcode,
        lasteditedby
    )
    values (
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
        source.deliverylocation,
        source.postaladdressline1,
        source.postaladdressline2,
        source.postalpostalcode,
        source.lasteditedby
    );

select customerid, customername, phonenumber, websiteurl
from sales.customers
where customername = 'otus student customer 188-merge';

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

declare @server_name nvarchar(128) = cast(serverproperty('servername') as nvarchar(128));
declare @file_path nvarchar(260) = 'c:\temp\invoicelines_hw8.txt';
declare @bcp_command nvarchar(4000);

set @bcp_command = 'bcp "[wideworldimporters].sales.invoicelines" out "' + @file_path
    + '" -t"@eu&$1&" -w -T -S "' + @server_name + '"';

print 'run this command manually in powershell/cmd if xp_cmdshell is disabled:';
print @bcp_command;

if is_srvrolemember('sysadmin') = 1
begin
    begin try
        exec master..xp_cmdshell 'if not exist "c:\temp" mkdir "c:\temp"', no_output;
        exec master..xp_cmdshell @bcp_command;
    end try
    begin catch
        print 'xp_cmdshell failed, run bcp manually and rerun bulk insert.';
        print error_message();
    end catch
end
else
begin
    print 'no sysadmin rights for xp_cmdshell, run bcp command manually.';
end;

drop table if exists sales.invoicelines_bulk_hw8;

select *
into sales.invoicelines_bulk_hw8
from sales.invoicelines
where 1 = 0;

declare @file_info table (
    file_exists int,
    file_is_dir int,
    parent_dir_exists int
);

insert into @file_info
exec master.dbo.xp_fileexist @file_path;

if exists (select 1 from @file_info where file_exists = 1)
begin
    begin try
        bulk insert sales.invoicelines_bulk_hw8
        from 'c:\temp\invoicelines_hw8.txt'
        with (
            batchsize = 10000,
            datafiletype = 'widechar',
            fieldterminator = '@eu&$1&',
            rowterminator = '\n',
            keepnulls,
            tablock
        );

        select count(*) as loaded_rows
        from sales.invoicelines_bulk_hw8;
    end try
    begin catch
        print 'bulk insert failed. check separators/rights and rerun.';
        print error_message();
    end catch
end
else
begin
    print 'data file not found. run bcp command above, then rerun bulk insert block.';
end;
