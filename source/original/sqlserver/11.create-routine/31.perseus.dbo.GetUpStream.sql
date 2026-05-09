USE [perseus]
GO
            
CREATE FUNCTION GetUpStream(@StartPoint INT) 
RETURNS @Paths TABLE (start_point INT, end_point INT, level INT)

AS BEGIN

	WITH Tree
	AS
	(
		-- Anchor member definition
		SELECT NULL AS child, g.id AS parent, 0 AS level
		FROM goo g
		WHERE g.id = @StartPoint
		UNION ALL
	   
		-- Recursive member definition
		SELECT g.id, c.id, r.level + 1
		FROM goo g
		JOIN goo c ON c.tree_scope_key = g.tree_scope_key AND c.tree_left_key < g.tree_left_key AND c.tree_right_key > g.tree_right_key
		JOIN Tree r ON g.id = r.parent
		UNION ALL
		SELECT gr.child, gr.parent, r.level + 1
		FROM goo g
		JOIN goo_relationship gr ON g.id = gr.child
		JOIN Tree r ON gr.child = r.parent	   
	)

	INSERT INTO @Paths
	SELECT @StartPoint, parent, MIN(level) AS level FROM Tree 
	GROUP BY parent
	
	RETURN;
END

