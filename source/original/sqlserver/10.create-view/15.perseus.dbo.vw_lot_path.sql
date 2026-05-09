USE [perseus]
GO
            
CREATE VIEW "vw_lot_path" AS
SELECT
  sl.id AS src_lot_id,
  dl.id AS dst_lot_id,
  mu.path,
  mu.level AS length
FROM
  m_upstream mu
JOIN vw_lot sl ON sl.uid = mu.end_point
JOIN vw_lot dl ON dl.uid = mu.start_point

