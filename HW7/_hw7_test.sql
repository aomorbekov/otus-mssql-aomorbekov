declare @columns nvarchar(max);
declare @columns_with_isnull nvarchar(max);
declare @sql nvarchar(max);

select @columns = stuff((
    select ',' + quotename(c.customername)
    from sales.customers as c
    order by c.customername
    for xml path(''), type
).value('.', 'nvarchar(max)'), 1, 1, '');

select @columns_with_isnull = stuff((
    select ',isnull(' + quotename(c.customername) + ', 0) as ' + quotename(c.customername)
    from sales.customers as c
    order by c.customername
    for xml path(''), type
).value('.', 'nvarchar(max)'), 1, 1, '');

set @sql = n'
select
    convert(varchar(10), p.invoicemonth, 104) as invoicemonth,
    ' + @columns_with_isnull + '
from (
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
    for customername in (' + @columns + ')
) as p
order by p.invoicemonth;';

exec sp_executesql @sql;