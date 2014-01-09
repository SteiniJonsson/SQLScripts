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
-- 
----------------------------------------------------------------------------------------------------
