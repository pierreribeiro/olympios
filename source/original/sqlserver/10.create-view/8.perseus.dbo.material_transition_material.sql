USE [perseus]
GO
            
CREATE VIEW material_transition_material AS
SELECT source_material AS start_point, transition_id, destination_material AS end_point FROM translated

