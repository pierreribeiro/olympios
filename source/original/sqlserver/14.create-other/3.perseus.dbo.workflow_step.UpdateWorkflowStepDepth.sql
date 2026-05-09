USE [perseus]
GO
            
CREATE TRIGGER UpdateWorkflowStepDepth ON workflow_step
FOR UPDATE, INSERT AS
BEGIN
	IF (UPDATE(scope_id) OR UPDATE(left_id) OR UPDATE(right_id))
	BEGIN
		UPDATE rw
		SET rw.depth = d.parent_count
		FROM workflow_step rw
		JOIN inserted ins ON ins.id = rw.id
		JOIN (
			SELECT rw.id, COUNT(*) AS parent_count 
			FROM workflow_step rw
			JOIN workflow_step p_rw ON rw.scope_id = p_rw.scope_id AND p_rw.left_id <= rw.left_id AND p_rw.right_id >= rw.right_id
			GROUP BY rw.id
		) d ON d.id = rw.id
	END
END

