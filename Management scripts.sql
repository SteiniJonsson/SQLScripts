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
  size = 100 MB, 
  maxsize = 5 GB, 
  filegrowth = 100 MB
)
to filegroup [Data1]

if not exists (select name from sys.filegroups where is_default=1 and name = N'Data1') 
alter database [<database_name, nvarchar(50), DB1>] modify filegroup [Data1] default
go

exec sp_changedbowner @loginame = N'sa'
go

use [master]

----------------------------------------------------------------------------------------------------
-- Create database template with primary filegroup for system objects and separated filegroups
-- for data and indexes.
----------------------------------------------------------------------------------------------------
use [master]
create database [<database_name, nvarchar(50), DB1>]
containment = none
on primary 
( 
  name = N'<database_name, nvarchar(50), DB1>_Primary', 
  filename = N'<data_directory, nvarchar ( 50 ), C:\Docs2\SQLData\Default>\<database_name, nvarchar(50), DB1>_Primary.mdf' , 
  size = 50 MB,
  maxsize = 1 GB, 
  filegrowth = 50 MB
)
log on 
( 
  name = N'<database_name, nvarchar(50), DB1>_Log', 
  filename = N'<log_directory, nvarchar ( 50 ),C:\Docs2\SQLTLogs\Default>\<database_name, nvarchar(50), DB1>_Log.ldf' , 
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
  filename = N'<data_directory, nvarchar ( 50 ), C:\Docs2\SQLData\Default>\<database_name, nvarchar(50), DB1>_Data1.ndf' , 
  size = 100 MB, 
  maxsize = 5 GB, 
  filegrowth = 100 MB
)
to filegroup [Data1]

if not exists (select name from sys.filegroups where is_default=1 and name = N'Data1') 
alter database [<database_name, nvarchar(50), DB1>] modify filegroup [Data1] default
go

alter database [<database_name, nvarchar(50), DB1>] add filegroup [Index1] 
go

alter database [<database_name, nvarchar(50), DB1>]
add file
( 
  name = N'<database_name, nvarchar(50), DB1>_Index1', 
  filename = N'<index_directory, nvarchar ( 50 ), C:\Docs2\SQLData\Default>\<database_name, nvarchar(50), DB1>_Index1.ndf' , 
  size = 100 MB, 
  maxsize = 5 GB, 
  filegrowth = 100 MB
)
to filegroup [Index1]

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

----------------------------------------------------------------------------------------------------
-- List all databases on a server with space and allocation information
-- script from http://gallery.technet.microsoft.com/scriptcenter/All-Databases-Data-log-a36da95d 
----------------------------------------------------------------------------------------------------
------------------------------Data file size---------------------------- 
if exists (select * from tempdb.sys.all_objects where name like '%#dbsize%') 
drop table #dbsize 
create table #dbsize 
(Dbname sysname,dbstatus varchar(50),Recovery_Model varchar(40) default ('NA'), file_Size_MB decimal(30,2)default (0),Space_Used_MB decimal(30,2)default (0),Free_Space_MB decimal(30,2) default (0)) 
go 
  
insert into #dbsize(Dbname,dbstatus,Recovery_Model,file_Size_MB,Space_Used_MB,Free_Space_MB) 
exec sp_msforeachdb 
'use [?]; 
  select DB_NAME() AS DbName, 
    CONVERT(varchar(20),DatabasePropertyEx(''?'',''Status'')) ,  
    CONVERT(varchar(20),DatabasePropertyEx(''?'',''Recovery'')),  
sum(size)/128.0 AS File_Size_MB, 
sum(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 as Space_Used_MB, 
SUM( size)/128.0 - sum(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS Free_Space_MB  
from sys.database_files  where type=0 group by type' 
  
  
  
  
  
go 
  
-------------------log size-------------------------------------- 
  if exists (select * from tempdb.sys.all_objects where name like '#logsize%') 
drop table #logsize 
create table #logsize 
(Dbname sysname, Log_File_Size_MB decimal(38,2)default (0),log_Space_Used_MB decimal(30,2)default (0),log_Free_Space_MB decimal(30,2)default (0)) 
go 
  
insert into #logsize(Dbname,Log_File_Size_MB,log_Space_Used_MB,log_Free_Space_MB) 
exec sp_msforeachdb 
'use [?]; 
  select DB_NAME() AS DbName, 
sum(size)/128.0 AS Log_File_Size_MB, 
sum(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 as log_Space_Used_MB, 
SUM( size)/128.0 - sum(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS log_Free_Space_MB  
from sys.database_files  where type=1 group by type' 
  
  
go 
--------------------------------database free size 
  if exists (select * from tempdb.sys.all_objects where name like '%#dbfreesize%') 
drop table #dbfreesize 
create table #dbfreesize 
(name sysname, 
database_size varchar(50), 
Freespace varchar(50)default (0.00)) 
  
insert into #dbfreesize(name,database_size,Freespace) 
exec sp_msforeachdb 
'use [?];SELECT database_name = db_name() 
    ,database_size = ltrim(str((convert(DECIMAL(15, 2), dbsize) + convert(DECIMAL(15, 2), logsize)) * 8192 / 1048576, 15, 2) + ''MB'') 
    ,''unallocated space'' = ltrim(str(( 
                CASE  
                    WHEN dbsize >= reservedpages 
                        THEN (convert(DECIMAL(15, 2), dbsize) - convert(DECIMAL(15, 2), reservedpages)) * 8192 / 1048576 
                    ELSE 0 
                    END 
                ), 15, 2) + '' MB'') 
FROM ( 
    SELECT dbsize = sum(convert(BIGINT, CASE  
                    WHEN type = 0 
                        THEN size 
                    ELSE 0 
                    END)) 
        ,logsize = sum(convert(BIGINT, CASE  
                    WHEN type <> 0 
                        THEN size 
                    ELSE 0 
                    END)) 
    FROM sys.database_files 
) AS files 
,( 
    SELECT reservedpages = sum(a.total_pages) 
        ,usedpages = sum(a.used_pages) 
        ,pages = sum(CASE  
                WHEN it.internal_type IN ( 
                        202 
                        ,204 
                        ,211 
                        ,212 
                        ,213 
                        ,214 
                        ,215 
                        ,216 
                        ) 
                    THEN 0 
                WHEN a.type <> 1 
                    THEN a.used_pages 
                WHEN p.index_id < 2 
                    THEN a.data_pages 
                ELSE 0 
                END) 
    FROM sys.partitions p 
    INNER JOIN sys.allocation_units a 
        ON p.partition_id = a.container_id 
    LEFT JOIN sys.internal_tables it 
        ON p.object_id = it.object_id 
) AS partitions' 
----------------------------------- 
  
  
  
if exists (select * from tempdb.sys.all_objects where name like '%#alldbstate%') 
drop table #alldbstate  
create table #alldbstate  
(dbname sysname, 
DBstatus varchar(55), 
R_model Varchar(30)) 
   
--select * from sys.master_files 
  
insert into #alldbstate (dbname,DBstatus,R_model) 
select name,CONVERT(varchar(20),DATABASEPROPERTYEX(name,'status')),recovery_model_desc from sys.databases 
--select * from #dbsize 
  
insert into #dbsize(Dbname,dbstatus,Recovery_Model) 
select dbname,dbstatus,R_model from #alldbstate where DBstatus <> 'online' 
  
insert into #logsize(Dbname) 
select dbname from #alldbstate where DBstatus <> 'online' 
  
insert into #dbfreesize(name) 
select dbname from #alldbstate where DBstatus <> 'online' 
  
select  
  
d.Dbname,d.dbstatus,d.Recovery_Model, 
(file_size_mb + log_file_size_mb) as DBsize, 
d.file_Size_MB,d.Space_Used_MB,d.Free_Space_MB, 
l.Log_File_Size_MB,log_Space_Used_MB,l.log_Free_Space_MB,fs.Freespace as DB_Freespace 
from #dbsize d join #logsize l  
on d.Dbname=l.Dbname join #dbfreesize fs  
on d.Dbname=fs.name 
order by Dbname 


----------------------------------------------------------------------------------------------------
-- List all tables, with name, row count and space used
----------------------------------------------------------------------------------------------------
with cte as
(
  select   s.Name + '.' + t.name                     [Tablename]
        ,  p.rows                                    [Row count]
        ,  ( sum ( a.total_pages ) * 8 ) / 1024.0    [Total space in MB] 
        ,  ( sum ( a.used_pages ) * 8  ) / 1024.0    [Used space in KB] 
        ,  ( ( sum ( a.total_pages ) - 
               sum ( a.used_pages ) ) * 8 ) / 1024.0 [Unused space in KB]
  from     sys.tables           t
  join     sys.schemas          s on  s.schema_id = t.schema_id
  join     sys.indexes          i on  t.object_id = i.object_id
  join     sys.partitions       p on  i.object_id = p.object_id 
                                  and i.index_id = p.index_id
  join     sys.allocation_units a on p.partition_id = a.container_id
  where    t.is_ms_shipped = 0
  and      t.name not like 'dt%' 
  and      i.object_id > 255 
  group by t.Name
         , s.Name
         , p.Rows
)
select *
from   cte
order by Tablename

----------------------------------------------------------------------------------------------------
-- Finding Tables with Nonclustered Primary Keys and no Clustered Index
--   http://www.brentozar.com/archive/2015/07/finding-tables-with-nonclustered-primary-keys-and-no-clustered-index/
----------------------------------------------------------------------------------------------------
set transaction isolation level read uncommitted;

select     quotename ( schema_name ( [t].[schema_id] ) ) + '.' + quotename ( [t].[name] )  [Table]
         , quotename ( object_name ( [kc].[object_id] ) )                                  [IndexName]
         , cast ( ( sum ( [a].[total_pages] ) * 8 / 1024.0 ) as decimal ( 18, 2 ) )        [IndexSizeMB]
from       [sys].[tables]           [t]
inner join [sys].[indexes]          [i] on  [t].[object_id] = [i].[object_id]
inner join [sys].[partitions]       [p] on  [i].[object_id] = [p].[object_id]
                                        and [i].[index_id] = [p].[index_id]
inner join [sys].[allocation_units] [a] on [a].[container_id] = case 
                                                                  when [a].[type] IN ( 1, 3 ) then [p].[hobt_id]
                                                                  when [a].[type] = 2 then [p].[partition_id]
                                                                end
inner join [sys].[key_constraints]  [kc] on [t].[object_id] = [kc].[parent_object_id]
where      [i].[name] is not null
and        objectproperty ( [kc].[object_id], 'CnstIsNonclustKey' ) = 1 --Unique Constraint or Primary Key can qualify
and        objectproperty ( [t].[object_id], 'TableHasClustIndex' ) = 0 --Make sure there's no Clustered Index, this is a valid design choice
and        objectproperty ( [t].[object_id], 'TableHasPrimaryKey' ) = 1 --Make sure it has a Primary Key and it's not just a Unique Constraint
and        objectproperty ( [t].[object_id], 'IsUserTable' ) = 1        --Make sure it's a user table because whatever, why not? We've come this far
group by   [t].[schema_id]
         , [t].[name]
         , object_name ( [kc].[object_id] )
order by   sum ( [a].[total_pages] ) * 8 / 1024.0 desc;

----------------------------------------------------------------------------------------------------
-- Query for job history
----------------------------------------------------------------------------------------------------
select j.[name]
     , h.[step_id]
     , h.[step_name]
     , h.[message]
     , h.[run_status]
     , case h.[run_status]
         when 0 then 'Failed'
         when 1 then 'Succseeded'
         when 2 then 'Retry'
         when 3 then 'Canceled'
       end                  [run_status_description]
     , h.[run_date]
     , h.[run_time]
     , h.[run_duration]
from   msdb..sysjobs j
join   msdb..sysjobhistory h on j.job_id = h.job_id
where  j.name in ( 'DW - Load STGVoruhus', 'DW - Process Motus SSAS' )
order by j.name, h.run_date, h.step_id
----------------------------------------------------------------------------------------------------
--
--
----------------------------------------------------------------------------------------------------
