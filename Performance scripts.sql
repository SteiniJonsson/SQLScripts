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
-- Rule of thumb: if avg_page_space_used_in_percent > 5% and <= 30% you should reorganize index
--                if avg_page_space_used_in_percent > 30% you should rebuild index
----------------------------------------------------------------------------------------------------
select   s.name + '.' + o.name                 [Table/view name]
       , o.type_desc                           [Object type]
       , index_id                              [Index ID]
       , index_type_desc                       [Index type]
       , index_level                           [Index level]
       , avg_fragmentation_in_percent          [Fragmentation in %]
       , fragment_count                        [Fragement count]
       , page_count                            [Page count]
from     sys.dm_db_index_physical_stats(db_id(), null, null, null , null ) i
join     sys.all_objects                                                   o on i.object_id = o.object_id
join     sys.schemas                                                       s on o.schema_id = s.schema_id
order by avg_fragmentation_in_percent desc

----------------------------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------------------------
