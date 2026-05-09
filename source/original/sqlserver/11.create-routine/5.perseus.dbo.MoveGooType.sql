USE [perseus]
GO
            
CREATE PROCEDURE MoveGooType @ChildId INT, @ParentId INT AS
BEGIN
	
	DECLARE @myFormerScope NVARCHAR(50)
	DECLARE @myFormerLeft INT
	DECLARE @myFormerRight INT
	
	DECLARE @TempScope NVARCHAR(50)
	
	DECLARE @myParentScope NVARCHAR(50)
	DECLARE @myParentLeft INT
	
	BEGIN TRY
	
		--Remove from current location
		SET @TempScope = NEWID()
		
		SELECT @myFormerScope = w.scope_id, @myFormerLeft = w.left_id, @myFormerRight = w.right_id FROM goo_type w 
		WHERE w.id = @ChildId
		
		UPDATE goo_type 
		SET scope_id = @TempScope
		WHERE scope_id = @myFormerScope
		AND left_id >= @myFormerLeft
		AND right_id <= @myFormerRight
		
		UPDATE goo_type
		SET left_id = left_id - (@myFormerRight - @myFormerLeft) - 1
		WHERE left_id > @myFormerRight
		AND scope_id = @myFormerScope 
		
		UPDATE goo_type
		SET right_id = right_id - (@myFormerRight - @myFormerLeft) - 1
		WHERE right_id > @myFormerRight
		AND scope_id = @myFormerScope 
		
		-- Add in New Position
		
		SELECT 
			@myParentScope = scope_id, 
			@myParentLeft = left_id
		FROM goo_type WHERE id = @ParentId
						
		UPDATE goo_type
		SET left_id = left_id + (@myFormerRight - @myFormerLeft) + 1
		WHERE left_id > @myParentLeft
		AND scope_id = @myParentScope
		
		UPDATE goo_type
		SET right_id = right_id + (@myFormerRight - @myFormerLeft) + 1
		WHERE right_id > @myParentLeft
		AND scope_id = @myParentScope

		UPDATE goo_type 
		SET scope_id = @myParentScope,
		left_id = @myParentLeft + (left_id - @myFormerLeft) + 1,
		right_id = @myParentLeft + (right_id - @myFormerLeft) + 1
		WHERE scope_id = @TempScope
		
		UPDATE rw
		SET rw.depth = d.parent_count
		FROM goo_type rw
		JOIN (
			SELECT rw.id, COUNT(p_rw.id) AS parent_count 
			FROM goo_type rw
			LEFT JOIN goo_type p_rw ON rw.scope_id = p_rw.scope_id AND p_rw.left_id < rw.left_id AND p_rw.right_id > rw.right_id
			GROUP BY rw.id
		) d ON d.id = rw.id
		WHERE rw.scope_id IN (@myFormerScope, @myParentScope)
	
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000)
		DECLARE @ErrorSeverity INT

		SELECT @ErrorMessage = ERROR_MESSAGE()
	
		RAISERROR('Could not move %d to %d: %s', 16, 1, @ChildId, @ParentId, @ErrorMessage)
		ROLLBACK
		
	END CATCH
END

