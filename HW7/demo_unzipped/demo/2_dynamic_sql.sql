USE [WideWorldImporters]

EXEC ('SELECT 1 AS ValueDynamic');
EXEC ('SELECT CustomerName, CustomerId FROM Sales.Customers WHERE CustomerID = 1');
-------
---передача значения NULL
declare @i int;
declare @sql varchar(100) = 'select ' + str(@i + 1);
print @sql;
execute( @sql );
go
--------
-- передача параметров через временную таблицу (типизация)
-- повышает безопасность и позволяет избежать SQL инъекций
create table #params ( v1 int, v2 datetime, v3 nvarchar(100) );

insert #params values ( 1, getdate(), 'String ''1'' ');
declare @sql varchar(1000) = '
  declare @v1 int, @v2 datetime, @v3 nvarchar(100);
  select @v1 = v1 , @v2 = v2, @v3 = v3 from #params;
  select @v1, @v2, @v3;
'
execute(@sql);
drop table #params;

-------
--- Создание последовательности с указанного значения

declare @id int, @str nvarchar(500);
select @id = max(CustomerID) from Sales.Customers;
select @id;

set @str = 'CREATE SEQUENCE cust_seq AS int START WITH ' + CAST(@id as varchar(10)) + ';';
select @str;
exec (@str);

-------
--- Динамический PIVOT

-- отладка запроса
select *
from (
	select SupplierName
		, eomonth(o.OrderDate) as mm
		, StockItemID
	from Purchasing.Suppliers as s
	inner join Purchasing.PurchaseOrders as o on o.SupplierID = s.SupplierID
	inner join Purchasing.PurchaseOrderLines as l on l.PurchaseOrderID = o.PurchaseOrderID
) t
pivot (
	count(StockItemID)
	for SupplierName in ([Contoso, Ltd.])
	) pvt
order by mm

-- заключаем в []
select QUOTENAME('test')
select QUOTENAME('test', '()')

DECLARE @columns NVARCHAR(MAX), 
		@query NVARCHAR(MAX);
-- !! CONVERT(NVARCHAR(MAX))
-- !! QUOTENAME()
SELECT @columns = STRING_AGG(CONVERT(NVARCHAR(MAX), QUOTENAME(SupplierName)), ',') within group(order by SupplierName)
FROM Purchasing.Suppliers

print @columns

set @query = N'
select *
from (
	select SupplierName
		, eomonth(o.OrderDate) as mm
		, StockItemID
	from Purchasing.Suppliers as s
	inner join Purchasing.PurchaseOrders as o on o.SupplierID = s.SupplierID
	inner join Purchasing.PurchaseOrderLines as l on l.PurchaseOrderID = o.PurchaseOrderID
) t
pivot (
	count(StockItemID)
	for SupplierName in (' + @columns + ')
	) pvt
order by mm
'
PRINT @query;
EXEC(@query);

---- инъекции
Declare @CustomerName NVARCHAR(50),
	@command NVARCHAR(4000);

SET @CustomerName = 'Tailspin Toys (Guin, AL)'' OR 1 = 1 --'

SET @command = 'SELECT top 20 CustomerName, CustomerId 
FROM Sales.Customers WHERE CustomerName = '''+@CustomerName+''''; 

SELECT @command;

EXECute (@command);
go
---
-- QUOTENAME()

Declare @CustomerName NVARCHAR(50),
	@command NVARCHAR(4000),
	@param NVARCHAR(4000);

-- SET @CustomerName = N'Tailspin Toys (Guin, AL)'
SET @CustomerName = N'Tailspin Toys (Guin, AL)'' OR 1 = 1 --'
print QUOTENAME(@CustomerName)

SET @command = 'SELECT top 20 CustomerName, CustomerId 
			FROM Sales.Customers WHERE CustomerName = '+QUOTENAME(@CustomerName,''''); 
select @command;
EXEC (@command);
go
---------

Declare @table NVARCHAR(50),
	@schema NVARCHAR(50),
	@command NVARCHAR(4000);

SET @schema = 'Sales'
SET @table = 'Orders'

SET @command = 'SELECT top 20 * FROM '+QUOTENAME(@schema)+'.'+QUOTENAME(@table); 

SELECT @command;

EXEC (@command);
------- еще инъекции - системные параметры
DECLARE @query NVARCHAR(4000),
		@sort NVARCHAR(100),
		@cnt INT = 10,
		@PersonId INT, 
		@Name NVARCHAR(200);

SET @Name = 'Amy Trefl'' UNION ALL 
SELECT null, loginname COLLATE Latin1_General_100_CI_AS, null FROM sys.syslogins; --'

SET @query = N'SELECT top '+CAST(@cnt AS NVARCHAR(50))+' PersonId, FullName, IsEmployee 
	FROM Application.People
	WHERE FullName = '''+@Name+'''';

PRINT @query;
EXEC (@query);
go

----sp_executesql - параметры!
Declare @CustomerName NVARCHAR(50),
	@command NVARCHAR(4000),
	@param NVARCHAR(4000);

SET @CustomerName = 'Tailspin Toys (Guin, AL)'

SET @command = 'SELECT top 20 CustomerName, CustomerId 
			FROM Sales.Customers WHERE CustomerName = @CustomerName'; 

SELECT @command;
SET @param = '@CustomerName NVARCHAR(50)'

EXEC sp_executesql @command, @param, @CustomerName;

-----------


DECLARE @query NVARCHAR(4000),
		@sort NVARCHAR(100),
		@cnt INT = 10;

SET @sort = 'CustomerId'

SET @query = 'SELECT top '+ CAST(@cnt AS VARCHAR(10))
	+' CustomerName, CustomerId FROM Sales.Customers ORDER BY '+@sort+';'

	select @query;
EXEC sp_executesql @query;
go
------------ еще про инъекции
drop table if exists test;
create table test (id int);

DECLARE @query NVARCHAR(4000),
		@sort NVARCHAR(100),
		@cnt INT = 10;

SET @sort = 'CreditLimit DESC; DROP TABLE dbo.test'

SET @query = 'SELECT top '+ CAST(@cnt AS VARCHAR(10)) +' CustomerName, CustomerId FROM Sales.Customers ORDER BY '+@sort+';'
-- quotename()
--SET @query = 'SELECT top '+ CAST(@cnt AS VARCHAR(10)) +' CustomerName, CustomerId FROM Sales.Customers ORDER BY '+quotename(@sort)+';'

PRINT @query;
EXEC sp_executesql @query;
select * from test; 
go
---------
-- входные - выходные параметры
declare @p1 int = 10, @p2 int = 0;
declare @sql nvarchar(4000);
set @sql = N'select @p1 = @p1 * 2, @p2 = @p2 + 1; select N''мы внутри'', @p1, @p2';
exec sp_executesql @sql, N'@p1 int, @p2 int', @p1, @p2;
select N'мы снаружи', @p1, @p2;
-- выходные
exec sp_executesql @sql, N'@p1 int, @p2 int out', @p1, @p2 out;
select N'мы снаружи-2', @p1, @p2;