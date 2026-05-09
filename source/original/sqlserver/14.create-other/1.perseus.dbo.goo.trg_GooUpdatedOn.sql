USE [perseus]
GO
            
CREATE TRIGGER trg_GooUpdatedOn
ON dbo.goo
AFTER UPDATE
AS
    UPDATE dbo.goo
    SET updated_on = GETDATE()
    WHERE id IN
      (SELECT DISTINCT id FROM Inserted)

