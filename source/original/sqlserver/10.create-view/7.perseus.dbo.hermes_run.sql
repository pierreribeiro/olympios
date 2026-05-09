USE [perseus]
GO
            
CREATE VIEW hermes_run AS
SELECT 
r.experiment_id, 
r.local_id AS run_id,
r.description,
r.created_on,
r.strain,
r.max_yield AS yield,
r.max_titer AS titer,
rg.id AS result_goo_id,
ig.id AS feedstock_goo_id,
c.id AS container_id,
r.start_time AS run_on,
r.stop_time AS duration
FROM hermes.run r
LEFT JOIN goo rg ON 'm'+CONVERT(VARCHAR(10), rg.id) = r.resultant_material
LEFT JOIN goo ig ON 'm'+CONVERT(VARCHAR(10), ig.id) = r.feedstock_material
LEFT JOIN container c ON c.uid = r.tank
WHERE (ISNULL(r.feedstock_material,'') != '' OR ISNULL(r.resultant_material,'') != '')
AND ISNULL(r.feedstock_material,'') != ISNULL(r.resultant_material,'')

