USE [perseus]
GO
            
CREATE TABLE [dbo].[smurf_property](
[id] int IDENTITY(1, 1) NOT NULL,
[property_id] int NOT NULL,
[sort_order] int NOT NULL DEFAULT ((99)),
[smurf_id] int NOT NULL,
[disabled] int NOT NULL DEFAULT ((0)),
[calculated] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];

