USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [ix_container_scope_id_left_id_right_id_depth]
    ON [dbo].[container] ([scope_id] ASC, [left_id] ASC, [right_id] ASC, [depth] ASC);

