USE [perseus]
GO
            
CREATE VIEW [dbo].[vw_processable_logs] AS

SELECT rl.* FROM robot_log rl
JOIN robot_log_type rlt ON rlt.id = rl.robot_log_type_id
WHERE ISNULL(rl.loaded, 0 ) = 0
AND NOT EXISTS (
		SELECT * FROM robot_log_error rle 
		JOIN robot_log rl_c ON rle.robot_log_id = rl_c.id
		WHERE rle.robot_log_id = rl_c.id
		AND rl_c.robot_run_id = rl.robot_run_id
	)
AND rl.id IN (SELECT MIN(id) FROM robot_log rl_d GROUP BY robot_log_checksum)
AND (EXISTS (SELECT * FROM robot_log_read rlr WHERE rlr.robot_log_id = rl.id) OR EXISTS (SELECT * FROM robot_log_transfer rlt WHERE rlt.robot_log_id = rl.id))
AND ISNULL(rl.loadable, 0) = 1
AND rl.created_on > DATEADD(MONTH, -1, GETDATE())

