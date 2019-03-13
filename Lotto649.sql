create database Lotto649 on 
(
	NAME = Lotto649_data,
	FILENAME = 'C:\DB\MSSQL\Lotto649_data.mdf',
	SIZE = 10,
	FILEGROWTH = 64
)
log on
(
	NAME = Lotto649_log,
	FILENAME = 'C:\DB\MSSQL\Lotto649_log.ldf',
	SIZE = 10,
	FILEGROWTH = 256 -- 256 MB each time, reduce the count of requests
)
go

use Lotto649
go

-- table SNO49(ID): generate ID 1 ... 49 corresponding to 49 rows 
declare @start int = 1, @end int = 49;
with Sno as (
select @start as n
union all
select n + 1 from Sno where n + 1 <= @end
)
select n as ID into SNO49 from Sno
option (maxrecursion 10000)
--select * from SNO49

-- create Lotto649 table to contain all 13,983,816 Lotto patterns
create table Lotto649 (
	ID int identity(1, 1) not null primary key, 
	A tinyint not null,
	B tinyint not null,
	C tinyint not null,
	D tinyint not null,
	E tinyint not null,
	F tinyint not null,
);
--select * from Lottery49;

insert into Lotto649
select A.ID as A, B.ID as B, C.ID as C, D.ID as D, E.ID as E, F.ID as F
from SNO49 A, SNO49 B, SNO49 C, SNO49 D, SNO49 E, SNO49 F
where A.ID < B.ID and B.ID < C.ID and C.ID < D.ID and D.ID < E.ID and E.ID < F.ID;

-- Test response time of seeking a Lotto from 13,983,816 Lotto patterns
--select * from Lotto649 where A = 1 and B = 4 and C = 7 and D = 14 and E = 30 and F = 39

-- Create UQ index for rapidly searching and verifying the uniqueness of Lotto patterns 
create UNIQUE INDEX UQ_6No on Lotto649(A, B, C, D, E, F);
go
-- Test other Lotto pattern
--select * from Lotto649 where A = 10 and B = 14 and C = 17 and D = 24 and E = 33 and F = 49;

-- Truncate the log by changing the database recovery model to SIMPLE.  
ALTER DATABASE Lotto649  
SET RECOVERY SIMPLE;  
GO  
-- Shrink the truncated log file to 10 MB.  
DBCC SHRINKFILE (Lotto649_Log, 10);  
GO  
-- Reset the database recovery model.  
ALTER DATABASE Lotto649  
SET RECOVERY FULL;  
GO 

-- Generate @round random numbers between @n1 and @n2
-- Return string containing numbers separated by ",". 
-- E.g., 1, 2, 3, 4, 5, 6 or 3, 10, 11, 23, 36, 43
create or alter procedure xp_RandomBtw
@n1 int, @n2 int, @round int, @s varchar(100) out
-- Within [@n1, @n2], getting @round different numbers as output string @s
as
	declare @n int, @i int = 1
	declare @tab table(ID int)
	set @s = NULL
	while @i <= @round
	begin 
	select @n = convert(int, rand() * (@n2 - @n1 + 1)) + @n1
	if not exists (select * from @tab where ID = @n)
	begin
	insert @tab values(@n)
	set @i = @i + 1
	end
	end
	select @s = coalesce(@s + N', ', N'') + convert(varchar(10), ID) from @tab order by ID
	return
go

-- Test Insertion of random Lotto into a temporary table
declare @str varchar(100)
exec xp_RandomBtw 1, 49, 6, @str out; -- [1, 49] get 6 different numbers as output string
print @str

-- Test Insertion of 10 random Lottos into a temporary table
create table #Ticket(A tinyint, B tinyint, C tinyint, D tinyint, E tinyint, F tinyint); 
declare @str2 varchar(100), @i int = 0
declare @sql nvarchar(max) = ''
while @i < 10
begin
	exec xp_RandomBtw 1, 49, 6, @str2 out; -- [1, 49] get 6 different numbers as output string
	select @sql = 'insert #Ticket values(' + @str2 + ')'
	print @str2
	EXEC sp_executesql @sql
	set @i = @i + 1
end
select * from #Ticket

-- Test Generate a random Lotto from ID
declare @N int = 13983816
select * from Lotto649 where ID = convert(int, rand() * @N) + 1
