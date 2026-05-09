USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_person_km_session_id]
    ON [dbo].[person] ([km_session_id] ASC)
    WITH (FILLFACTOR = 90);

