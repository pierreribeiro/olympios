USE [perseus]
GO
            
CREATE PROCEDURE MoveContainer @ChildId INT, @ParentId INT AS
BEGIN
	
	DECLARE @myFormerScope VARCHAR(50);	
	DECLARE @myFormerLeft INT;
	DECLARE @myFormerRight INT;
	
	DECLARE @TempScope VARCHAR(32);
	
	DECLARE @myParentScope VARCHAR(50);
	DECLARE @myParentLeft INT;
	
	BEGIN TRY
	
		--Remove from current location
		SET @TempScope = LEFT(CONVERT(VARCHAR(150), NEWID()), 32)
		
		SELECT @myFormerScope = w.scope_id, @myFormerLeft = w.left_id, @myFormerRight = w.right_id FROM container w 
		WHERE w.id = @ChildId;
		
		UPDATE container 
		SET scope_id = @TempScope
		WHERE scope_id = @myFormerScope
		AND left_id >= @myFormerLeft
		AND right_id <= @myFormerRight
		
		UPDATE container
		SET left_id = left_id - (@myFormerRight - @myFormerLeft) - 1
		WHERE left_id > @myFormerRight
		AND scope_id = @myFormerScope; 
		
		UPDATE container
		SET right_id = right_id - (@myFormerRight - @myFormerLeft) - 1
		WHERE right_id > @myFormerRight
		AND scope_id = @myFormerScope; 
		
		-- Add in New Position
		
		SELECT 
			@myParentScope = scope_id, 
			@myParentLeft = left_id
		FROM container WHERE id = @ParentId;
						
		UPDATE container
		SET left_id = left_id + (@myFormerRight - @myFormerLeft) + 1
		WHERE left_id > @myParentLeft
		AND scope_id = @myParentScope;
		
		UPDATE container
		SET right_id = right_id + (@myFormerRight - @myFormerLeft) + 1
		WHERE right_id > @myParentLeft
		AND scope_id = @myParentScope;

		UPDATE container 
		SET scope_id = @myParentScope,
		left_id = @myParentLeft + (left_id - @myFormerLeft) + 1,
		right_id = @myParentLeft + (right_id - @myFormerLeft) + 1
		WHERE scope_id = @TempScope
		
		UPDATE rw
		SET rw.depth = d.parent_count
		FROM container rw
		JOIN (
			SELECT rw.id, COUNT(p_rw.id) AS parent_count 
			FROM container rw
			LEFT JOIN container p_rw ON rw.scope_id = p_rw.scope_id AND p_rw.left_id < rw.left_id AND p_rw.right_id > rw.right_id
			GROUP BY rw.id
		) d ON d.id = rw.id
		WHERE rw.scope_id IN (@myFormerScope, @myParentScope)
	
	END TRY
	BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;

		SELECT @ErrorMessage = ERROR_MESSAGE();
	
		RAISERROR('Could not move %d to %d: %s', 16, 1, @ChildId, @ParentId, @ErrorMessage) WITH LOG
		ROLLBACK
		
	END CATCH
END

