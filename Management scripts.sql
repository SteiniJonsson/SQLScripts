/*====================================================================================================

  Management scripts for SQL Server

  Author: Steini Jonsson

====================================================================================================*/

----------------------------------------------------------------------------------------------------
-- List jobs from Reporting server (with usefule names)
----------------------------------------------------------------------------------------------------
select  sc.ScheduleID       [SQLAgent_Job_Name]
      , j.[name]            [Job name]
      , s.Description       [sub_desc]
      , s.DeliveryExtension [sub_delExt]
      , c.Name              [ReportName]
      , c.Path              [ReportPath]
from    ReportServer..ReportSchedule   rs
join    ReportServer..Schedule      sc  on  rs.ScheduleID = sc.ScheduleID 
join    ReportServer..Subscriptions s   on  rs.SubscriptionID = s.SubscriptionID 
join    ReportServer..[Catalog]     c   on  rs.ReportID = c.ItemID 
                                        and s.Report_OID = c.ItemID
join    msdb..sysjobs               j   on  convert ( sysname, sc.ScheduleID ) = j.name

----------------------------------------------------------------------------------------------------
-- Create database template with primary filegroup for system objects and a separated filegroup
-- for data.
----------------------------------------------------------------------------------------------------
use [master]
create database [<database_name, nvarchar(50), DB1>]
containment = none
on primary 
( 
  name = N'<database_name, nvarchar(50), DB1>_Primary', 
  filename = N'C:\SQLData\Default\<database_name, nvarchar(50), DB1>_Primary.mdf' , 
  size = 50 MB,
  maxsize = 1 GB, 
  filegrowth = 50 MB
)
log on 
( 
  name = N'<database_name, nvarchar(50), DB1>_Log', 
  filename = N'C:\SQLTLogs\Default\<database_name, nvarchar(50), DB1>_Log.ldf' , 
  size = 100 MB, 
  maxsize = 5 GB, 
  filegrowth = 100 MB 
)
go

alter database [<database_name, nvarchar(50), DB1>] set compatibility_level = 120
alter database [<database_name, nvarchar(50), DB1>] set recovery simple 
go

use [<database_name, nvarchar(50), DB1>]
go

alter database [<database_name, nvarchar(50), DB1>] add filegroup [Data1] 
go

alter database [<database_name, nvarchar(50), DB1>]
add file
( 
  name = N'<database_name, nvarchar(50), DB1>_Data1', 
  filename = N'C:\SQLData\Default\<database_name, nvarchar(50), DB1>_Data1.ndf' , 
  size = 50 MB, 
  maxsize = 5 GB, 
  filegrowth = 50 MB
)
to filegroup [Data1]

if not exists (select name from sys.filegroups where is_default=1 and name = N'Data1') 
alter database [<database_name, nvarchar(50), DB1>] modify filegroup [Data1] default
go

exec sp_changedbowner @loginame = N'sa'
go

use [master]
----------------------------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------------------------
