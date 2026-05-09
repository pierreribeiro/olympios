USE [perseus]
GO
            
ALTER TABLE [dbo].[alembic_version]
ADD CONSTRAINT [alembic_version_pkc] PRIMARY KEY CLUSTERED ([version_num]);

