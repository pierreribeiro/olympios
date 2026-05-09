USE [perseus]
GO
            
CREATE PROCEDURE MaterialToTransition @MaterialUid VARCHAR(50), @TransitionUid VARCHAR(50) AS
	INSERT INTO material_transition (material_id, transition_id) VALUES (@MaterialUid, @TransitionUid)

