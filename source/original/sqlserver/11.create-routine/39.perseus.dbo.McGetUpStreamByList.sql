USE [perseus]
GO
            
CREATE  FUNCTION [dbo].[McGetUpStreamByList](@StartPoint GooList READONLY)
  RETURNS @Paths TABLE(start_point VARCHAR(50), end_point VARCHAR(50), neighbor VARCHAR(50), path VARCHAR(500), level INT)

AS BEGIN

  WITH upstream
  AS
  (
    SELECT
      pt.destination_material   AS start_point,
      pt.destination_material   AS parent,
      pt.source_material        AS child,
      CAST('/' AS VARCHAR(500)) AS path,
      1                         AS level
    FROM translated pt
      JOIN @StartPoint sp ON sp.uid = pt.destination_material
    UNION ALL

    SELECT
      r.start_point,
      pt.destination_material,
      pt.source_material,
      CAST(r.path + r.child + '/' AS VARCHAR(500)),
      r.level + 1
    FROM translated pt
      JOIN upstream r ON pt.destination_material = r.child
    WHERE pt.destination_material != pt.source_material
  )

  INSERT INTO @Paths
    SELECT
      start_point,
      child AS end_point,
      parent,
      path,
      level
    FROM upstream

  INSERT INTO @Paths
    SELECT
      sp.uid,
      sp.uid,
      NULL,
      '',
      0
    FROM @StartPoint sp
   WHERE EXISTS (SElECT 1 FROM goo WHERE sp.uid=goo.uid)

  RETURN
END

