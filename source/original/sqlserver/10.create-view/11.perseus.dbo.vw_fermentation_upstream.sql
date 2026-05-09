USE [perseus]
GO
            
CREATE VIEW [dbo].[vw_fermentation_upstream] AS
  WITH upstream
  AS
  (
    SELECT pt.destination_process AS start_point,
           pt.destination_process AS parent,
           pt.destination_process_type AS process_type,
           pt.source_process AS child,
           CAST('/' + pt.destination_process AS VARCHAR(255)) AS path, 1 AS level
    FROM vw_process_upstream pt
    WHERE source_process_type = 22
    UNION ALL

    SELECT r.start_point,
      pt.destination_process,
      pt.destination_process_type AS process_type,
      pt.source_process,
      CASE
      WHEN pt.destination_process_type = 22 THEN CAST(r.path + '/' +  pt.source_process  AS VARCHAR(255))
      ELSE r.path
      END,
      CASE
      WHEN pt.destination_process_type = 22 THEN r.level + 1
      ELSE r.level
      END
    FROM vw_process_upstream pt
      JOIN upstream r ON pt.destination_process = r.child
    WHERE pt.destination_process != pt.source_process
  )

  SELECT start_point, child AS end_point, path, level FROM upstream where process_type = 22

