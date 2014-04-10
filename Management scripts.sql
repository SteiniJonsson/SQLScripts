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
-- List indexes for all tables in current database with size and filegroup.
----------------------------------------------------------------------------------------------------
with cte as 
(
  select s.name + '.' + o.[name] [Object name]
       , i.[name]                [Index name]
       , i.type_desc             [Index type]
       , f.[name]                [Filegroup name]
       , p.used_page_count * 8   [Index size in KB]
  from   sys.indexes                i
  join   sys.filegroups             f on  i.data_space_id = f.data_space_id
  join   sys.all_objects            o on  i.[object_id] = o.[object_id]
  join   sys.schemas                s on  o.schema_id = s.schema_id
  join   sys.dm_db_partition_stats  p on  i.object_id = p.object_id 
                                      and i.index_id = p.index_id
  where  i.data_space_id = f.data_space_id
  and    o.type = 'U'
)
select   [Object name]
       , [Index name]
       , [Index type]
       , [Filegroup name]
       , convert ( decimal ( 20, 2 )
                 , sum ( [Index size in KB] / 1024.0 ) 
                 ) [Index size in MB]
from     cte
group by [Object name]
       , [Index name]
       , [Index type]
       , [Filegroup name]
