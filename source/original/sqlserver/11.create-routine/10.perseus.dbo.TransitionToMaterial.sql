USE [perseus]
GO
            
CREATE PROCEDURE TransitionToMaterial @TransitionUid VARCHAR(50), @MaterialUid VARCHAR(50) AS
	INSERT INTO transition_material (material_id, transition_id) VALUES (@MaterialUid, @TransitionUid)

