CREATE or alter PROCEDURE dbo.OrdersSearch_KitchenSink @OrderId INT = NULL
	,@CustomerID INT = NULL
	,@OrderDateFrom DATE = NULL
	,@OrderDateTo DATE = NULL
	,@SalespersonPersonID INT = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SELECT OrderId,OrderDate,CustomerID,SalespersonPersonID
	FROM Sales.Orders
	WHERE (@CustomerID IS NULL OR CustomerID = @CustomerID)
		AND (@OrderId IS NULL OR OrderId = @OrderId)
		AND (OrderDate >= COALESCE(@OrderDateFrom, OrderDate))
		AND (@OrderDateTo IS NULL OR OrderDate <= @OrderDateTo)
		AND (@SalespersonPersonID IS NULL OR SalespersonPersonID = @SalespersonPersonID);
END
