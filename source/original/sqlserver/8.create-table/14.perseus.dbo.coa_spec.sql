USE [perseus]
GO
            
CREATE TABLE [dbo].[coa_spec](
[id] int IDENTITY(1, 1) NOT NULL,
[coa_id] int NOT NULL,
[property_id] int NOT NULL,
[upper_bound] float(53) NULL,
[lower_bound] float(53) NULL,
[equal_bound] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[upper_equal_bound] float(53) NULL,
[lower_equal_bound] float(53) NULL,
[result_precision] int NULL DEFAULT ((0))
)
ON [PRIMARY];

