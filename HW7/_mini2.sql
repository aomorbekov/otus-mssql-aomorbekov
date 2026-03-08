use wideworldimporters;
declare @x nvarchar(max) = N'1';
declare @sql nvarchar(max);
set @sql = n'select ' + @x + n' as v';
exec sp_executesql @sql;
