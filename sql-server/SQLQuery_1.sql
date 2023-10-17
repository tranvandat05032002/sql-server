/*Ví dụ: Viết thủ tục 
				proc_GetOrderDetails
					@orderId int
Có chức năng hiển thị mã hàng, tên hàng, đơn vị tính, số lượng, giá bán và thành tiền
của các mặt hàng thuộc đơn hàng có mã là @orderId */

if exists(select * from sys.objects where name = 'proc_GET_OrderDetails')
    drop procedure proc_GET_OrderDetails
GO
create procedure proc_GET_OrderDetails (
                    @orderId int
                )
AS
BEGIN
    SET NOCOUNT on;
    select p.ProductId, p.ProductName, od.Quantity, sum(od.Quantity * od.SalePrice) as ThanhTien
    from Products as p
    join OrderDetails as od
    on p.ProductId = od.ProductId
    where od.OrderId = @orderId
    group by p.ProductId, p.ProductName, od.Quantity
END
GO
-- Goi ham proc_GET_OrderDetails
exec proc_GET_OrderDetails @orderId = 10248
/*
Ví dụ: Viết thủ tục 
			proc_GetRevenueByDate
				@month int,
				@year int
Có chức năng thống kê doanh thu bán hàng trong từng ngày của tháng @month năm @year.
Yêu cầu phải thống kê tất cả các ngày trong tháng. */

if exists(select * from sys.objects where name = 'proc_GET_RevenueByDate')
    drop procedure proc_GET_OrderDetails
GO
CREATE PROCEDURE proc_GET_RevenueByDate (
                    @month int,
                    @year int
                )
as
    BEGIN
        set nocount on;
        if(@month not between 1 and 12)
            return
        declare @firstDate date = DATEFROMPARTS(@year, @month, 1); -- start date is 1/@month/@year
     declare @lastDate date = EOMONTH(@firstDate, 0) --get last date in month
        --declare @lastDate date = DATEFROMPARTS(@firstDate, @month + 1, 1) -- get start date of next month
        --set @lastDate = DATEADD(DAY, -1, @lastDate)

        ;with cte_DoanhThu as (
            select o.OrderDate, sum(od.Quantity * od.SalePrice) as DoanhThuByDate
            from Orders as o
            join OrderDetails as od
            on o.OrderId = od.OrderId
            where o.OrderDate between @firstDate and @lastDate
            group by o.OrderDate
        ),cte_ngay as (
            select @firstDate as SummaryDate
            union all
            select DATEADD(day, 1, cte_ngay.SummaryDate)
            from cte_ngay   
            where cte_ngay.SummaryDate < @lastDate
        )
        select cte_1.SummaryDate, ISNULL(cte_2.DoanhThuByDate, 0) as DoanhThu
        from cte_ngay as cte_1
        left join cte_DoanhThu as cte_2
        on cte_1.SummaryDate = cte_2.OrderDate
    END
GO

exec proc_GET_RevenueByDate @year = 2017, @month = 7
GO
-- function

create function fn_CongHaiSo(@a int, @b int) 
returns INT
AS
BEGIN
    declare @c INT
    set @c = @a + @b
    return @c
END
GO

SELECT dbo.fn_CongHaiSo(10, 12) as CongHaiSo
GO

if exists(select * from sys.objects where name = 'fn_TotalRevenueOfMOnth')
    drop function fn_TotalRevenueOfMOnth
GO

create function fn_TotalRevenueOfMOnth(@month int, @year int) 
returns money
as 
BEGIN
    if @month not between 1 and 12
        return 0
    if @year < 0
        return 0
    select sum(od.Qua)
    from Orders as o
    join OrderDetails as od
    on o.OrderId = od.OrderId
    where month(o.OrderDate) = @month and year(o.OrderDate) = @year

END
GO