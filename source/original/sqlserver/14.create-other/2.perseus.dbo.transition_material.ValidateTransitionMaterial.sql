USE [perseus]
GO
            
CREATE TRIGGER [dbo].[ValidateTransitionMaterial] ON [dbo].[transition_material]
FOR INSERT AS
BEGIN
	IF 
		(
			SELECT COUNT(*) FROM inserted ins
			JOIN transition_material tm ON ins.material_id = tm.material_id
			WHERE tm.transition_id != ins.transition_id
		) > 0
	BEGIN
		RAISERROR('A material cannot be the output of more than 1 process.', 16, 1)
		RETURN
	END
END

