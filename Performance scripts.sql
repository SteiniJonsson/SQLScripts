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
-- 
----------------------------------------------------------------------------------------------------
