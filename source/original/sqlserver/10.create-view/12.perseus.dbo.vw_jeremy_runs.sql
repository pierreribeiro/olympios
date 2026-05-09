USE [perseus]
GO
            
CREATE VIEW vw_jeremy_runs AS
	WITH Tree
	AS
	(
		-- Anchor member definition
		SELECT g.id AS starting_point, NULL AS parent, g.id AS child
		FROM dbo.goo g
		JOIN hermes.run r ON r.resultant_material = g.uid 
		UNION ALL
	   
		-- Recursive member definition
		SELECT r.starting_point, g.id, c.id AS child
		FROM dbo.goo g
		JOIN dbo.goo c ON c.tree_scope_key = g.tree_scope_key AND c.tree_left_key > g.tree_left_key AND c.tree_right_key < g.tree_right_key
		JOIN Tree r ON g.id = r.child
		UNION ALL
		SELECT r.starting_point, gr.parent, gr.child AS child
		FROM dbo.goo g
		JOIN dbo.goo_relationship gr ON g.id = gr.parent
		JOIN Tree r ON gr.parent = r.child
	   
	)

SELECT * FROM (
	SELECT r.experiment_id AS experiment, r.local_id AS run, 
	r.description AS run_label,
	rcv.value AS vessel_size,
	gt.name AS feedstock_type, 
	r.strain, g.name, g.description, MIN(cs.id) AS cell_harvest_id, MIN(ls.id) AS liquid_separation_id
	FROM hermes.run r
	JOIN dbo.goo g ON r.resultant_material = g.uid
	JOIN Tree t ON g.id = t.starting_point
	LEFT JOIN hermes.run_condition_value rcv ON rcv.run_id = r.id AND rcv.master_condition_id = 65
	LEFT JOIN dbo.goo i ON i.uid = r.feedstock_material
	LEFT JOIN dbo.goo_type gt ON gt.id = i.goo_type_id
	LEFT JOIN dbo.fatsmurf cs ON t.child = cs.goo_id AND cs.smurf_id = 23
	LEFT JOIN dbo.fatsmurf ls ON t.child = ls.goo_id AND ls.smurf_id = 25
	GROUP BY r.experiment_id, r.local_id, gt.name, r.strain, g.name, g.description, r.description, rcv.value
) d WHERE cell_harvest_id IS NOT NULL
	OR liquid_separation_id IS NOT NULL

