/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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

set quoted_identifier on;
set nocount on;

declare @xml_file_path nvarchar(4000) = 'c:\Users\askario\Desktop\otus-mssql-aomorbekov\HW9\StockItems.xml';

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

declare @stockitems_xml xml;
declare @sql nvarchar(max);

drop table if exists #xml_data;

create table #xml_data
(
    stockitems_xml xml
);

set @sql = '
select cast(bulkcolumn as xml) as stockitems_xml
from openrowset
(
    bulk ''' + replace(@xml_file_path, '''', '''''') + ''',
    single_blob
) as x;';

insert into #xml_data
(
    stockitems_xml
)
exec sp_executesql @sql;

select @stockitems_xml = stockitems_xml
from #xml_data;

drop table if exists #xml_data;

drop table if exists #stockitems_openxml;

create table #stockitems_openxml
(
    stockitemname nvarchar(200) collate database_default,
    supplierid int,
    unitpackageid int,
    outerpackageid int,
    quantityperouter int,
    typicalweightperunit decimal(18, 3),
    leadtimedays int,
    ischillerstock bit,
    taxrate decimal(18, 3),
    unitprice decimal(18, 6)
);

declare @doc int;

exec sp_xml_preparedocument @doc output, @stockitems_xml;

insert into #stockitems_openxml
(
    stockitemname,
    supplierid,
    unitpackageid,
    outerpackageid,
    quantityperouter,
    typicalweightperunit,
    leadtimedays,
    ischillerstock,
    taxrate,
    unitprice
)
select
    stockitemname,
    supplierid,
    unitpackageid,
    outerpackageid,
    quantityperouter,
    typicalweightperunit,
    leadtimedays,
    ischillerstock,
    taxrate,
    unitprice
from openxml(@doc, '/StockItems/Item', 2)
with
(
    stockitemname nvarchar(200) '@Name',
    supplierid int 'SupplierID',
    unitpackageid int 'Package/UnitPackageID',
    outerpackageid int 'Package/OuterPackageID',
    quantityperouter int 'Package/QuantityPerOuter',
    typicalweightperunit decimal(18, 3) 'Package/TypicalWeightPerUnit',
    leadtimedays int 'LeadTimeDays',
    ischillerstock bit 'IsChillerStock',
    taxrate decimal(18, 3) 'TaxRate',
    unitprice decimal(18, 6) 'UnitPrice'
);

exec sp_xml_removedocument @doc;

select
    stockitemname,
    supplierid,
    unitpackageid,
    outerpackageid,
    quantityperouter,
    typicalweightperunit,
    leadtimedays,
    ischillerstock,
    taxrate,
    unitprice
from #stockitems_openxml;

merge warehouse.stockitems as target
using #stockitems_openxml as source
on target.stockitemname = source.stockitemname
when matched then
    update
    set
        target.supplierid = source.supplierid,
        target.unitpackageid = source.unitpackageid,
        target.outerpackageid = source.outerpackageid,
        target.quantityperouter = source.quantityperouter,
        target.typicalweightperunit = source.typicalweightperunit,
        target.leadtimedays = source.leadtimedays,
        target.ischillerstock = source.ischillerstock,
        target.taxrate = source.taxrate,
        target.unitprice = source.unitprice,
        target.lasteditedby = 1
when not matched then
    insert
    (
        stockitemname,
        supplierid,
        unitpackageid,
        outerpackageid,
        quantityperouter,
        typicalweightperunit,
        leadtimedays,
        ischillerstock,
        taxrate,
        unitprice,
        lasteditedby
    )
    values
    (
        source.stockitemname,
        source.supplierid,
        source.unitpackageid,
        source.outerpackageid,
        source.quantityperouter,
        source.typicalweightperunit,
        source.leadtimedays,
        source.ischillerstock,
        source.taxrate,
        source.unitprice,
        1
    );

drop table if exists #stockitems_xquery;

create table #stockitems_xquery
(
    stockitemname nvarchar(200) collate database_default,
    supplierid int,
    unitpackageid int,
    outerpackageid int,
    quantityperouter int,
    typicalweightperunit decimal(18, 3),
    leadtimedays int,
    ischillerstock bit,
    taxrate decimal(18, 3),
    unitprice decimal(18, 6)
);

insert into #stockitems_xquery
(
    stockitemname,
    supplierid,
    unitpackageid,
    outerpackageid,
    quantityperouter,
    typicalweightperunit,
    leadtimedays,
    ischillerstock,
    taxrate,
    unitprice
)
select
    t.c.value('@Name[1]', 'nvarchar(200)'),
    t.c.value('(SupplierID/text())[1]', 'int'),
    t.c.value('(Package/UnitPackageID/text())[1]', 'int'),
    t.c.value('(Package/OuterPackageID/text())[1]', 'int'),
    t.c.value('(Package/QuantityPerOuter/text())[1]', 'int'),
    t.c.value('(Package/TypicalWeightPerUnit/text())[1]', 'decimal(18, 3)'),
    t.c.value('(LeadTimeDays/text())[1]', 'int'),
    t.c.value('(IsChillerStock/text())[1]', 'bit'),
    t.c.value('(TaxRate/text())[1]', 'decimal(18, 3)'),
    t.c.value('(UnitPrice/text())[1]', 'decimal(18, 6)')
from @stockitems_xml.nodes('/StockItems/Item') as t(c);

select
    stockitemname,
    supplierid,
    unitpackageid,
    outerpackageid,
    quantityperouter,
    typicalweightperunit,
    leadtimedays,
    ischillerstock,
    taxrate,
    unitprice
from #stockitems_xquery;

merge warehouse.stockitems as target
using #stockitems_xquery as source
on target.stockitemname = source.stockitemname
when matched then
    update
    set
        target.supplierid = source.supplierid,
        target.unitpackageid = source.unitpackageid,
        target.outerpackageid = source.outerpackageid,
        target.quantityperouter = source.quantityperouter,
        target.typicalweightperunit = source.typicalweightperunit,
        target.leadtimedays = source.leadtimedays,
        target.ischillerstock = source.ischillerstock,
        target.taxrate = source.taxrate,
        target.unitprice = source.unitprice,
        target.lasteditedby = 1
when not matched then
    insert
    (
        stockitemname,
        supplierid,
        unitpackageid,
        outerpackageid,
        quantityperouter,
        typicalweightperunit,
        leadtimedays,
        ischillerstock,
        taxrate,
        unitprice,
        lasteditedby
    )
    values
    (
        source.stockitemname,
        source.supplierid,
        source.unitpackageid,
        source.outerpackageid,
        source.quantityperouter,
        source.typicalweightperunit,
        source.leadtimedays,
        source.ischillerstock,
        source.taxrate,
        source.unitprice,
        1
    );

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

select
    (
        select
            s.stockitemname as '@Name',
            s.supplierid as 'SupplierID',
            s.unitpackageid as 'Package/UnitPackageID',
            s.outerpackageid as 'Package/OuterPackageID',
            s.quantityperouter as 'Package/QuantityPerOuter',
            s.typicalweightperunit as 'Package/TypicalWeightPerUnit',
            s.leadtimedays as 'LeadTimeDays',
            s.ischillerstock as 'IsChillerStock',
            s.taxrate as 'TaxRate',
            s.unitprice as 'UnitPrice'
        from warehouse.stockitems as s
        order by s.stockitemname
        for xml path('Item'), root('StockItems'), type
    ) as stockitems_xml;


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select
    stockitemid,
    stockitemname,
    json_value(customfields, '$.CountryOfManufacture') as countryofmanufacture,
    json_value(customfields, '$.Tags[0]') as firsttag
from warehouse.stockitems;

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


select
    s.stockitemid,
    s.stockitemname,
    (
        select string_agg(t.value, ', ')
        from openjson(s.customfields, '$.Tags') as t
    ) as tags
from warehouse.stockitems as s
where exists
(
    select 1
    from openjson(s.customfields, '$.Tags') as t
    where t.value = 'Vintage'
);
