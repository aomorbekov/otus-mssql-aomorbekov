use wideworldimporters;

declare @columns nvarchar(max);
declare @columns_with_isnull nvarchar(max);
declare @sql nvarchar(max);

select @columns = stuff((
    select ',' + quotename(customername)
    from sales.customers
    order by customername
    for xml path(''), type
).value('.', 'nvarchar(max)'), 1, 1, '');

select @columns_with_isnull = stuff((
    select ',isnull(' + quotename(customername) + ', 0) as ' + quotename(customername)
    from sales.customers
    order by customername
    for xml path(''), type
).value('.', 'nvarchar(max)'), 1, 1, '');

set @sql = n'select convert(varchar(10), p.invoicemonth, 104) as invoicemonth, ' + @columns_with_isnull + n' from (select dateadd(month, datediff(month, 0, i.invoicedate), 0) as invoicemonth, c.customername, count(*) as purchases_count from sales.invoices as i inner join sales.customers as c on c.customerid = i.customerid group by dateadd(month, datediff(month, 0, i.invoicedate), 0), c.customername) as s pivot (sum(purchases_count) for customername in (' + @columns + n')) as p order by p.invoicemonth;';

exec sp_executesql @sql;
