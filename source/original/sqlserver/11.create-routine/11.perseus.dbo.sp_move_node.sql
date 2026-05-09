USE [perseus]
GO
            
CREATE PROCEDURE sp_move_node @myId INT, @parentId INT AS
BEGIN
	
	DECLARE @myFormerScope VARCHAR(100);	
	DECLARE @myFormerLeft INT;
	DECLARE @myFormerRight INT;
	
	DECLARE @myParentScope VARCHAR(100);
	DECLARE @myParentLeft INT;
	
	SELECT @myParentScope = tree_scope_key, @myParentLeft = tree_left_key FROM goo WHERE id = @parentId;
	
	SELECT @myFormerScope = g.tree_scope_key, @myFormerLeft = g.tree_left_key, @myFormerRight = g.tree_right_key FROM goo g
	WHERE g.id = @myId;
	
	UPDATE goo
	SET tree_left_key = tree_left_key + (@myFormerRight - @myFormerLeft) + 1
	WHERE tree_left_key > @myParentLeft
	AND tree_scope_key = @myParentScope;
	
	UPDATE goo
	SET tree_right_key = tree_right_key + (@myFormerRight - @myFormerLeft) + 1
	WHERE tree_right_key > @myParentLeft
	AND tree_scope_key = @myParentScope;
	
	UPDATE goo 
	SET tree_scope_key = @myParentScope,
	tree_left_key = @myParentLeft + (tree_left_key - @myFormerLeft) + 1,
	tree_right_key = @myParentLeft + (tree_right_key - @myFormerLeft) + 1
	WHERE tree_scope_key = @myFormerScope
	AND tree_left_key >= @myFormerLeft
	AND tree_right_key <= @myFormerRight;
	
	UPDATE goo
	SET tree_left_key = tree_left_key - (@myFormerRight - @myFormerLeft) - 1
	WHERE tree_left_key > @myFormerRight
	AND tree_scope_key = @myFormerScope; 
	
	UPDATE goo
	SET tree_right_key = tree_right_key - (@myFormerRight - @myFormerLeft) - 1
	WHERE tree_right_key > @myFormerRight
	AND tree_scope_key = @myFormerScope; 
	
END

