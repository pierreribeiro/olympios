USE [perseus]
GO
            
CREATE UNIQUE NONCLUSTERED INDEX [uniq_index]
    ON [dbo].[smurf_goo_type] ([smurf_id] ASC, [goo_type_id] ASC, [is_input] ASC);

