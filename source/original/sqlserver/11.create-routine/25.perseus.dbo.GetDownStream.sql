USE [perseus]
GO
            
CREATE FUNCTION GetDownStream(@StartPoint INT) 
RETURNS @Paths TABLE (start_point INT, end_point INT)

AS BEGIN

	WITH Tree
	AS
	(
		-- Anchor member definition
		SELECT NULL AS parent, g.id AS child
		FROM goo g
		WHERE g.id = @StartPoint
		UNION ALL
	   
		-- Recursive member definition
		SELECT g.id, c.id
		FROM goo g
		JOIN goo c ON c.tree_scope_key = g.tree_scope_key AND c.tree_left_key > g.tree_left_key AND c.tree_right_key < g.tree_right_key
		JOIN Tree r ON g.id = r.child
		UNION ALL
		SELECT gr.parent, gr.child
		FROM goo g
		JOIN goo_relationship gr ON g.id = gr.parent
		JOIN Tree r ON gr.parent = r.child
	   
	)

	INSERT INTO @Paths
	SELECT @StartPoint, child FROM Tree 
	
	RETURN;
END

