USE [perseus]
GO
            
CREATE TABLE [dbo].[poll](
[id] int IDENTITY(1, 1) NOT NULL,
[smurf_property_id] int NOT NULL,
[fatsmurf_reading_id] int NOT NULL,
[value] varchar(2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[standard_deviation] float(53) NULL,
[detection] int NULL,
[limit_of_detection] float(53) NULL,
[limit_of_quantification] float(53) NULL,
[lower_calibration_limit] float(53) NULL,
[upper_calibration_limit] float(53) NULL,
[bounds_limit] int NULL
)
ON [PRIMARY];

