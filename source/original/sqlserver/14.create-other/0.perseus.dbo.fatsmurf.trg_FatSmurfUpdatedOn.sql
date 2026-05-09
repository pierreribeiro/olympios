USE [perseus]
GO
            
CREATE TRIGGER trg_FatSmurfUpdatedOn
ON dbo.fatsmurf
AFTER UPDATE
AS
    UPDATE dbo.fatsmurf
    SET updated_on = GETDATE()
    WHERE id IN
      (SELECT DISTINCT id FROM Inserted)

