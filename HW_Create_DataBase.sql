

--__________________________________#____________________________#__________________________________#_______________________________
-- Создаем базу данных [DataBase2021]
--/////////////////////////////////////////////

USE master;
CREATE DATABASE [DataBase2021] --- COLLATE Cyrillic_General можно изменить тип юникода
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = DataBase2021, FILENAME = N'E:\SQL_Developer\DataBase\DataBase2021.mdf' ,  -- явное указание хранения файла
	SIZE = 500MB , --- проценты не указывать
	MAXSIZE = UNLIMITED, 
	FILEGROWTH = 100MB )
 LOG ON 
( NAME = DataBase2021_log, FILENAME = N'E:\SQL_Developer\DataBase\DataBase2021_log.ldf' ,  --- журнал логов
	SIZE = 500MB , 
	MAXSIZE = 1GB , 
	FILEGROWTH = 100MB  )
GO

---  *** при необходимости удаляем 
--USE master; 
--GO 
--IF DB_ID (N'DataBase2021') IS NOT NULL 
--	DROP DATABASE DataBase2021; 
--GO 

--Справочник контрагентов
--Справочник услуг
--Справочник регионов
--Справочник сотрудников
--Справочник цен на услуги (загрузочный тип)
--Календарь
--Таблица звонков
--Табица заказов
--Таблица продаж


------ загружаем данные в БД используя встроенный иструмент импорта неструкрированных файлов
--SELECT * FROM [dbo].[Contact]
--SELECT * FROM [dbo].[Deal]
--SELECT * FROM [dbo].[EMAIL]
--SELECT * FROM [dbo].[Emploee]
--SELECT * FROM [dbo].[Lead]
--SELECT * FROM [dbo].[Region]
--SELECT * FROM [dbo].[TypeProduct]
--SELECT * FROM [dbo].[WORK_POSITION]

--CREATE SCHEMA Sales  -- для продаж
--CREATE SCHEMA Prod  -- спроавоники орг


--SELECT CONCAT( COLUMN_NAME, ' ', DATA_TYPE, IIF( CHARACTER_MAXIMUM_LENGTH IS NULL, '', CONCAT('(',CHARACTER_MAXIMUM_LENGTH,'),') ) )
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_NAME = 'Lead'

--________________________________________________________________________________________________________________________
---------- Создание таблицы

---- Регион -----
DROP TABLE IF EXISTS  Sales.Region
CREATE TABLE Sales.Region(
	ID    int			not null identity(1, 1)  primary key,
	Name  nvarchar(100) not null
)

INSERT INTO Sales.Region ( Name)
	SELECT Name FROM [dbo].[Region]

SELECT * FROM  Sales.Region

--=======================================
---- Клиенты -----
DROP TABLE IF EXISTS  Sales.Customers
CREATE TABLE Sales.Customers(
	ID			int				not null identity(1, 1)  primary key,
	DATE_CREATE nvarchar(50)	not null,
	FIRST_NAME	nvarchar(50)	not null,
	LAST_NAME	nvarchar(50)	not null,
	SECOND_NAME nvarchar(50)	not null,
	BierthDay	date			not null CHECK (BierthDay >= N'19600101' AND BierthDay <= DATEADD( year, -21, GETDATE() ) ),
	RegionID	int				not null FOREIGN KEY REFERENCES Sales.Region (ID)  
)

--SELECT DATEADD( day, FLOOR(RAND()*(14600-100)+100), '19700101')
--(SELECT TOP 1 ID FROM Sales.Region ORDER BY NEWID())

--SELECT *  FROM [dbo].[Contact]
DROP TABLE IF EXISTS  #Contact
DECLARE @n int, @num int, @const int

SELECT DATE_CREATE, FIRST_NAME, LAST_NAME, SECOND_NAME, ROW_NUMBER() OVER( ORDER BY DATE_CREATE) as Row_Count 
INTO #Contact
FROM [dbo].[Contact]
WHERE FIRST_NAME != 'NULL' AND LAST_NAME != 'NULL'  AND SECOND_NAME != 'NULL'

SET @n = ( SELECT COUNT(*) FROM Sales.Region)
SET @const = ( SELECT COUNT(*) FROM #Contact )

SET @num = 1

--INSERT INTO  Sales.Customers (DATE_CREATE, FIRST_NAME, LAST_NAME, SECOND_NAME, BierthDay, RegionID)
BEGIN
WHILE @num <= @const
	BEGIN
		INSERT INTO  Sales.Customers (DATE_CREATE, FIRST_NAME, LAST_NAME, SECOND_NAME, BierthDay, RegionID)
			SELECT DATE_CREATE, FIRST_NAME, LAST_NAME, SECOND_NAME,  DATEADD( day, FLOOR(RAND()*(14600-100)+100), '19600101'), FLOOR(RAND()*(@n-1)+1) FROM #Contact
			WHERE  Row_Count = @num
	
		SET @num = @num + 1
	END
END
SELECT * FROM Sales.Customers


CREATE NONCLUSTERED INDEX IX_NonClustered ON  Sales.Customers
(
DATE_CREATE ASC, FIRST_NAME ASC, LAST_NAME ASC, SECOND_NAME ASC, BierthDay ASC, RegionID ASC
)


SELECT STRING_AGG(COLUMN_NAME, ' ASC, ') FROm INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Customers'
AND TABLE_SCHEMA = 'Sales'


--============================================================
---- Email -----
DROP TABLE IF EXISTS  Prod.Email
CREATE TABLE Prod.Email(
	ID		int			 not null identity(1, 1)  primary key,
	Name	nvarchar(50) not null CHECK (Name LIKE '%@%' )
)

--SELECT * FROM [dbo].[EMAIL]

INSERT INTO Prod.Email ( NAme)
	SELECT NAme FROM [dbo].[EMAIL]

SELECT * FROM Prod.Email
--===========================================================
---- job -----
DROP TABLE IF EXISTS  Prod.Job
CREATE TABLE Prod.Job(
	ID		int				not null identity(1, 1)  primary key,
	Name	nvarchar(50)	not null
)

SELECT * FROM [dbo].[WORK_POSITION]

INSERT INTO Prod.Job ( NAme)
	SELECT NAme FROM [dbo].[WORK_POSITION]

SELECT * FROM Prod.Job

--============================================================
---- Цены -----
DROP TABLE IF EXISTS  Sales.Price
CREATE TABLE Sales.Price(
	ID		int		not null identity  primary key,
	Price	decimal not null CHECK (Price >= 1000 AND Price <= 50000)
)

DECLARE  @np int

SET @np = 1

WHILE @np <= 10
	BEGIN
		INSERT INTO Sales.Price ( Price)
			SELECT  FLOOR(RAND()*(50000-1000)+1000)
			SET @np = @np + 1
	END

SELECT * FROM Sales.Price
--TRUNCATE TABLE Sales.Price

--===================================================================
---- Виды услуг -----
DROP TABLE IF EXISTS  Sales.TypesOfServices
CREATE TABLE  Sales.TypesOfServices(
	ID		int			 not null identity  primary key,
	Name	nvarchar(50) not null,
	PriceID int			 not null FOREIGN KEY REFERENCES Sales.Price (ID)
)

DECLARE @n1 int, @cp int, @q int

SET @n1 = (SELECT COUNT(*) FROM Sales.Price )
SET @q =  (SELECT COUNT(*) FROM [dbo].[TypeProduct] )

SET @cp = 1

DROP TABLE IF EXISTS  #Prodact
SELECT *, ROW_NUMBER() OVER( ORDER BY ID) as Row
INTO #Prodact
FROM [dbo].[TypeProduct]

WHILE @cp <= @q
	BEGIN
		INSERT INTO Sales.TypesOfServices ( Name, PriceID)
			SELECT Name, CAST(FLOOR(RAND()*(@n1-1)+1) as int) FROM #Prodact
			WHERE Row = @cp
			SET @cp = @cp + 1
	END

SELECT  * FROM Sales.TypesOfServices
--TRUNCATE TABLE Sales.TypesOfServices

--===================================================================
----  Источники -----
DROP TABLE IF EXISTS  Sales.Source
CREATE TABLE  Sales.Source(
	ID	 int		  not null identity(1, 1)  primary key,
	Name nvarchar(100) not null
)

--SELECT * FROM [dbo].[Source]

INSERT INTO Sales.Source ( Name)
	SELECT Name FROM [dbo].[Source]

SELECT * FROM Sales.Source

--=================================================================
----  Статусы -----
DROP TABLE IF EXISTS  Prod.Status
CREATE TABLE   Prod.Status(
	ID	 int		  not null identity(1, 1)  primary key,
	Name nvarchar(50) not null,
	Type nvarchar(50) not null
)

INSERT INTO Prod.Status ( Name, Type)
	VALUES ( 'Брак', 'Lead'),
		   ('Сконвертирован', 'Lead'),
		   ('Завешилась', 'Deal'),
		   ('В работе', 'Deal')

SELECT * FROM  Prod.Status

--=================================================================
------ Продавцы -----
DROP TABLE IF EXISTS  Prod.Employee
CREATE TABLE Prod.Employee(
	ID					int			 not null identity(1, 1)  primary key,
	DateStart			Datetime2 not null,
	DateEnd				Datetime2  null,
	JOB_ID				int			 not null FOREIGN KEY REFERENCES Prod.Job (ID),
	EMAIL_ID			int			 not null FOREIGN KEY REFERENCES Prod.Email (ID),
	FIRST_NAME			nvarchar(50) not null,
	LAST_NAME			nvarchar(50) not null,
	SECOND_NAME			nvarchar(50) not null,
	BIRTHDAY			date		 not null
)

--SELECT FLOOR(RAND()*(15-5)+5); --- рандом
--SELECT * FROM [dbo].[Emploee]

--UPDATE [dbo].[Emploee] SET ID = c2.[Row]
--FROM [dbo].[Emploee] c
--JOIN ( SELECT *, ROW_NUMBE-R() OVER( ORDER BY DateStart ) as [Row] FROM [dbo].[Emploee] ) c2 ON c2.ID=c.ID


DECLARE 
 @JOB_C INT,
 @EMAIL_C INT,
 @Emploee INT,
 @cc int


SET @JOB_C = (SELECT COUNT(*) FROM Prod.Job )
SET @EMAIL_C = (SELECT COUNT(*) FROM Prod.Email )
SET @Emploee = (SELECT COUNT(*) FROM [dbo].[Emploee] )
SET @cc = 1

WHILE @cc <= @Emploee
	BEGIN
	INSERT INTO Prod.Employee (DateStart ,DateEnd ,JOB_ID ,EMAIL_ID , FIRST_NAME, LAST_NAME ,SECOND_NAME ,BIRTHDAY)
		 SELECT DateStart ,IIF(DateEnd = 'NULL', NULL, DateEnd) ,FLOOR(RAND()*(@JOB_C-1)+1) ,ID,  n.Name ,LAST_NAME ,SECOND_NAME ,
		 DATEADD( day, FLOOR(RAND()*(3650-100)+100), '19850101')
		 FROM [dbo].[Emploee] e
		 OUTER APPLY (
			SELECT TOP 1 Gender , NAME FROM ( VALUES (1, 'Анастасия'), (0, 'Евгений'), (0, 'Александр'), (0, 'Артем'), (1, 'Жанна'), (1, 'Диана'), (1, 'Виктория'), (0, 'Николай'), (0, 'Никита'), (0, 'Сергей'), (1, 'Наталья'),
				(1, 'Татьяна'), (0, 'Вячеслав'), (0, 'Константин'), (0, 'Евегний'), (0, 'Юрий'), (0, 'Владимир'), (1, 'Ольга'), (0, 'Роман'), (1, 'Алена') 
					) d(Gender, Name)
			WHERE IIF( RIGHT(e.SECOND_NAME,1) = 'а',1,0)=Gender
			ORDER BY  NEWID()
			) n 
		 WHERE e.ID = @cc 
	SET @cc = @cc + 1 
	END

SELECT * FROM Prod.Employee


CREATE NONCLUSTERED INDEX IX_NonClustered ON  Prod.Employee
(
DateStart ASC, DateEnd ASC, JOB_ID ASC, EMAIL_ID ASC, FIRST_NAME ASC, LAST_NAME ASC, SECOND_NAME ASC, BIRTHDAY ASC
)


SELECT STRING_AGG(COLUMN_NAME, ' ASC, ') FROm INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Employee'
AND TABLE_SCHEMA = 'Prod'

--=====================================================================
------ Заявки -----
DROP TABLE IF EXISTS  Sales.Lead
CREATE TABLE Sales.Lead(
	Lead_ID		int			not null identity(1, 1)  primary key,
	DATE_CREATE datetime2	not null,
	CustomerID	int			not null FOREIGN KEY REFERENCES Sales.Customers (ID),
	StatusID	int			not null FOREIGN KEY REFERENCES Prod.Status (ID),
	SourceID	int			not null FOREIGN KEY REFERENCES Sales.Source (ID) 
)

--SELECT * FROM [dbo].[Lead] ORDER BY Lead_ID

--UPDATE [dbo].[Lead] SET Lead_ID = c2.[Row]
--FROM [dbo].[Lead] c
--JOIN ( SELECT *, ROW_NUMBER() OVER( ORDER BY DATE_CREATE ) as [Row] FROM [dbo].[Lead] ) c2 ON c2.UID=c.UID

DECLARE 
 @Customers_C INT,
 @Source_C INT,
 @Lead INT,
 @cc int


SET @Customers_C = ( SELECT COUNT(*) FROM [Sales].[Customers] )
SET @Source_C = ( SELECT COUNT(*) FROM [Sales].[Source] )
SET @Lead = ( SELECT COUNT(*) FROM [dbo].[Lead] )
SET @cc = 1

WHILE @cc <= @Lead
	BEGIN
	INSERT INTO Sales.Lead(DATE_CREATE ,CustomerID ,StatusID ,SourceID)
		 SELECT 
			DATE_CREATE , FLOOR(RAND()*(@Customers_C-1)+1) ,IIF(Lead_ID %2 > 0,2,1) ,FLOOR(RAND()*(@Source_C-1)+1) 
		 FROM [dbo].[Lead]  e
		 WHERE e.Lead_ID = @cc 
	SET @cc = @cc + 1 
	END

SELECT * FROM Sales.Lead ORDER BY Lead_ID


CREATE NONCLUSTERED INDEX IX_NonClustered ON  Sales.Lead
(
DATE_CREATE ASC, CustomerID ASC, StatusID ASC, SourceID ASC
)


SELECT STRING_AGG(COLUMN_NAME, ' ASC, ') FROm INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Lead'
AND TABLE_SCHEMA = 'Sales'

--==================================================================================
------ Сделки -----
DROP TABLE IF EXISTS  Sales.Deal
CREATE TABLE Sales.Deal(
	Deal_ID		int			not null identity(1, 1) primary key,
	Lead_ID		int			not null FOREIGN KEY REFERENCES  Sales.Lead (Lead_ID),
	Date_Create datetime2	not null,
	Date_Close	datetime2	null,
	TypeID		int			not null FOREIGN KEY REFERENCES Sales.TypesOfServices (ID),
	StatusID	int			not null FOREIGN KEY REFERENCES Prod.Status (ID),
	EmploeeID	int			not null FOREIGN KEY REFERENCES [Prod].[Employee] (ID)
)

--SELECT * FROM [Sales].[TypesOfServices]
----SELECT * FROM [dbo].[Deal] ORDER BY Deal_ID

--UPDATE [dbo].Deal SET Deal_ID = c2.[Row]
--FROM [dbo].Deal c
--JOIN ( SELECT *, ROW_NUMBER() OVER( ORDER BY DATE_CREATE ) as [Row] FROM [dbo].Deal ) c2 ON c2.Deal_ID=c.Deal_ID

DECLARE 
 @Deal INT,
 @cc int

SET @Deal = ( SELECT COUNT(*) FROM [dbo].[Deal]  ) 
SET @cc = 1

WHILE @cc <= @Deal
	BEGIN
		INSERT INTO Sales.Deal(Lead_ID ,Date_Create ,Date_Close ,TypeID ,StatusID, EmploeeID)
			 SELECT 
				n.Lead_ID, DATE_CREATE , IIF(DateClose = 'NULL', NULL, DateClose), t.ID, IIF(DateClose = 'NULL', 4, 3) , emp.ID
			 FROM [dbo].[Deal]  e
			 OUTER APPLY (
				SELECT TOP 1 
					Lead_ID	
				FROM Sales.Lead
				WHERE StatusID = 2
				ORDER BY  NEWID()
				) n
			 OUTER APPLY (
				SELECT TOP 1 
					ID	
				FROM Sales.TypesOfServices
				ORDER BY  NEWID()
				) t
			 OUTER APPLY (
				SELECT TOP 1 
					ID	
				FROM [Prod].[Employee] 
				WHERE  CAST(  e.DATE_CREATE as DATE) BETWEEN CAST( ISNULL(DateStart, N'99900101') as DATE) AND CAST( ISNULL(DateEnd, N'99900101') as DATE)
				ORDER BY  NEWID()
				) emp
			 WHERE e.Deal_ID = @cc 
		SET @cc = @cc + 1 
	END

SELECT * FROM Sales.[Deal]



CREATE NONCLUSTERED INDEX IX_NonClustered ON Sales.[Deal]
(
 Lead_ID ASC, Date_Create ASC, Date_Close ASC, TypeID ASC, StatusID ASC, EmploeeID ASC
)


SELECT STRING_AGG(COLUMN_NAME, ' ASC, ') FROm INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Deal'
AND TABLE_SCHEMA = 'Sales'


--===================================================================================
----- Календарь -----------

--CREATE PROCEDURE [Calendar].[UpdateDay]

--AS
--BEGIN
--    SET NOCOUNT ON;
--    SET XACT_ABORT ON;

	--TRUNCATE TABLE  Prod.[CalendarDay]
	DROP TABLE IF EXISTS Prod.[CalendarDay]
	CREATE TABLE  Prod.[CalendarDay] ([CreatedDate] date NOT NULL UNIQUE, 
			[SatrtMonth] date NOT NULL,
			[EndMonth] date NOT NULL,
			[Year] int NOT NULL,
			[Month] int NOT NULL,
			[Day] int NOT NULL,
			[MonthReport] NVARCHAR(10) NOT NULL,
			[MONTHNAME] NVARCHAR(10) NOT NULL,
			[Quarter] int NOT NULL,
			[dayofyear] int NOT NULL,
			[week] int NOT NULL,
			[weekday] int NOT NULL)

	DECLARE @date date
	SET @date = '2020-01-01'
 
	WHILE @date <= EOMONTH(GETDATE() )
		BEGIN

			INSERT INTO  Prod.[CalendarDay] ([CreatedDate], [SatrtMonth], [EndMonth], [Year], [Month], [Day], [MonthReport], [MONTHNAME], [Quarter], [dayofyear], [week], [weekday]) 
				VALUES(
						@date
						, DATEFROMPARTS(YEAR(@date), MONTH(@date), 1) --[SatrtMonth]
						, EOMONTH(@date) -- as [EndMonth]
						, YEAR(@date) -- [Year]
						, MONTH(@date) -- [Month]
						, DAY(@date) -- [Day]
						, FORMAT(@date, 'yyyy-MM') -- [MonthReport]
						, CASE MONTH(@date) 
							WHEN 1 THEN 'Январь' 
							WHEN 2 THEN 'Февраль'
							WHEN 3 THEN 'Март'
							WHEN 4 THEN 'Апрель'
							WHEN 5 THEN 'Май'
							WHEN 6 THEN 'Июнь'
							WHEN 7 THEN 'Июль'
							WHEN 8 THEN 'Август'
							WHEN 9 THEN 'Сентябрь'
							WHEN 10 THEN 'Октябрь'
							WHEN 11 THEN 'Ноябрь'
							WHEN 12 THEN 'Декабрь'
							END --- [MONTHNAME]
						, DATEPART(Quarter, @date ) --[Quarter]
						, DATEPART(dayofyear, @date ) -- [dayofyear]
						, DATEPART(week, @date ) -- [week]
						, DATEPART(weekday, @date ) -- [weekday] )
					)
			SET @date = DATEADD(DAY,1,@date)

      
		END;
	
	SELECT * FROM Prod.[CalendarDay]

--END;
--GO

CREATE NONCLUSTERED INDEX IX_NonClustered ON Prod.[CalendarDay]
(
 SatrtMonth ASC, EndMonth ASC, Year ASC, Month ASC, Day ASC
)


SELECT STRING_AGG(COLUMN_NAME, ' ASC, ') FROm INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CalendarDay'

--===================================================================================
--____________________________________________________________________________________________________________
------------ Проверка созданных таблиц --------
USE DataBase2021
DECLARE @dml AS NVARCHAR(MAX), @COUNT AS INT, @N int, @TABLE_NAME NVARCHAR(100)

SET @COUNT = (SELECT  COUNT(*) FROM INFORMATION_SCHEMA.TABLES -- STRING_AGG(CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) , ',' ) 
				WHERE TABLE_SCHEMA IN ('Prod','Sales') )


DROP TABLE IF EXISTS #tab_tt
SELECT  CONCAT(TABLE_SCHEMA,'.', TABLE_NAME)  as Name, ROW_NuMBER() OVER( ORDER BY TABLE_SCHEMA ) as ID
INTO #tab_tt
FROM INFORMATION_SCHEMA.TABLES -- STRING_AGG(CONCAT(TABLE_SCHEMA,'.', TABLE_NAME) , ',' ) 
WHERE TABLE_SCHEMA IN ('Prod','Sales')

--SELECT @COUNT

SET @N = 1

WHILE @N <= @COUNT
	BEGIN 
		SET @TABLE_NAME = (SELECT NAME FROM #tab_tt WHERE ID=@N )
		SET @dml = N'SELECT TOP 5 * FROM ' +  @TABLE_NAME
		SELECT @TABLE_NAME as TableName
		SET @N =  1 + @N
		--SELECT @dml
		EXEC sp_executesql @dml;
	END
