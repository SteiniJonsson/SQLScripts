/*====================================================================================================

  Performance scripts for SQL Server

  Author: Steini Jonsson

====================================================================================================*/

----------------------------------------------------------------------------------------------------
-- Drop buffers and cache, update stats
----------------------------------------------------------------------------------------------------
checkpoint
dbcc dropcleanbuffers
dbcc freeproccache

exec sp_updatestats

----------------------------------------------------------------------------------------------------
-- List index fragmentations
----------------------------------------------------------------------------------------------------
with cte as 
(
  select schema_name ( o.schema_id )      [Schema name]
       , o.name                           [Object name]
       , i.index_id                       [Index Id]
       , x.name                           [Index name]
       , i.index_type_desc                [Index type description]
       , i.index_level                    [Index level]
       , i.avg_fragmentation_in_percent   [Index framentation %]
       , i.avg_page_space_used_in_percent [Average page space used %]
       , i.page_count                     [Page count]
  from sys.dm_db_index_physical_stats(db_id(), null, null, null , null ) i
  join sys.objects o on  i.object_id = o.object_id
  join sys.indexes x on  i.object_id = x.object_id
                     and i.index_id = x.index_id
)
select * from cte
where [Object name] = '<TableName>'

----------------------------------------------------------------------------------------------------
-- Compare two methods of deleting duplicate rows from a table.
----------------------------------------------------------------------------------------------------
use Steini;
drop table DuplData
create table DuplData
(
  Id       int            not null,
  FullName varchar ( 50 ) not null

  constraint PK_DuplData_Id primary key clustered ( Id ),
  index idxNafn ( FullName )
)

insert DuplData values ( 1, 'Steini' )
insert DuplData values ( 2, 'Eggert' )
insert DuplData values ( 3, 'Keli' )
insert DuplData values ( 4, 'Steini' )

select * from DuplData;

set statistics io on

with cte
as 
(
  select Id
       , FullName
       , row_number() over ( partition by FullName
                             order by     FullName
                           ) as RowNr
  from DuplData
)
delete
from   cte
where  RowNr != 1
-- Table 'DuplData'. Scan count 1, logical reads 8, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

delete 
from   DuplData 
where  id in 
( 
  select   max ( Id ) [MaxId]
  from     DuplData
  group by FullName
  having   count(*) > 1 
)
-- Table 'DuplData'. Scan count 1, logical reads 8, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.


select * from DuplData;

set statistics io off
----------------------------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------------------------
