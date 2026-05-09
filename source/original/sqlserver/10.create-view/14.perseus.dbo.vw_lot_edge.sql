USE [perseus]
GO
            
CREATE VIEW "vw_lot_edge" AS
SELECT
  sl.id AS src_lot_id,
  dl.id AS dst_lot_id,
  mt.added_on as created_on
FROM
  material_transition mt
JOIN vw_lot sl ON sl.uid = mt.material_id
JOIN vw_lot dl ON dl.process_uid = mt.transition_id

