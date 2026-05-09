EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'(Perseus) Import Common Users',
    @step_name = N'Import Common Users',
    @step_id = 2,
    @subsystem = N'TSQL',
    @command = N'-- remove inactive user with higher user_id
DELETE old
FROM perseus.dbo.perseus_user old
JOIN (
SELECT
cu_new.user_id,
cu_new.login,
cu_new.domain_id AS domain_id,
cu_new.name AS name,
cu_new.email, cu_new.is_active
FROM common.dbo.cm_user cu_old
JOIN common.dbo.cm_user cu_new ON cu_old.login = cu_new.login
-- in case of login reuse, muse have another attribute that matchs
AND (cu_old.name = cu_new.name OR cu_old.email = cu_new.email)
WHERE cu_old.is_active = 0
AND cu_new.is_active = 1
AND cu_new.user_id < cu_old.user_id
) new ON old.login = new.login

/*
  This version will only run on a system which has the common.dbo.cm_user
  table available in the same mssql database.
  cdolan 10/2013, adapted from original by Matt Ward.

SET QUOTED_IDENTIFIER ON
  
INSERT INTO perseus_user (common_id, domain_id, login, name, mail)
  SELECT cmu.user_id, cmu.domain_id, cmu.login, cmu.name, cmu.email
    FROM common.dbo.cm_user cmu
   WHERE NOT EXISTS
      ( SELECT * FROM perseus_user pu WHERE pu.domain_id = cmu.domain_id )
     AND NOT EXISTS
      ( SELECT * FROM perseus_user pu WHERE pu.login = cmu.login )
     AND cmu.user_id IN
      ( SELECT MAX(cmu.user_id) FROM common.dbo.cm_user cmu
        WHERE cmu.login IS NOT NULL
        GROUP BY cmu.login )
     AND cmu.user_id IN
      ( SELECT MAX(cmu.user_id) FROM common.dbo.cm_user cmu
        WHERE cmu.domain_id IS NOT NULL
        GROUP BY cmu.domain_id )
GO
GO
 */

/*
(Perseus) Import Common Users
Intended to be run nightly, loads new users from the common user tables
and updates user info.

Now accounting for when: (2022-02-11)
1. login stays the same, domain_id, name, or/and email changed
2. domain_id stays the same, login, name or/and email changed

@author: Simon Zhang
@version: 2
*/
SET QUOTED_IDENTIFIER ON
	-- insert new users
	INSERT INTO perseus_user (common_id, domain_id, login, name, mail)
	SELECT new.user_id, new.domain_id, new.login, new.name, new.email
	FROM common.dbo.cm_user new
	WHERE
		NOT EXISTS ( 
			SELECT * FROM perseus.dbo.perseus_user pu WHERE pu.domain_id = new.domain_id )
		AND NOT EXISTS (
			SELECT * FROM perseus.dbo.perseus_user pu WHERE pu.login = new.login )
		AND new.is_active = 1
		AND new.domain_id IS NOT NULL
		AND new.login IS NOT NULL;

	-- login remains the same: domain_id, name, or/and email changed in AD as recorded in common
	UPDATE perseus.dbo.perseus_user
	SET 
		name = new.name,
		domain_id = new.domain_id,
		mail = new.email,
		common_id = new.user_id
	FROM perseus.dbo.perseus_user old
		JOIN (
			SELECT 
				cu_new.user_id,
				cu_new.login,
				cu_new.domain_id AS domain_id, 
				cu_new.name AS name,
				cu_new.email, cu_new.is_active
			FROM common.dbo.cm_user cu_old
				JOIN common.dbo.cm_user cu_new ON cu_old.login = cu_new.login
					-- in case of login reuse, muse have another attribute that matchs
					AND (cu_old.name = cu_new.name OR cu_old.email = cu_new.email)
			WHERE cu_old.is_active = 0
				AND cu_new.is_active = 1
		) new ON old.login = new.login
	WHERE 
		new.domain_id <> old.domain_id
		OR new.name <> old.name
		OR new.email <> old.mail
		OR new.user_id <> old.common_id 

	-- domain id is the same, login, name or/and email changed
	UPDATE perseus.dbo.perseus_user
	SET 
		name = new.name,
		login = new.login,
		mail = new.email
	FROM common.dbo.cm_user new 
		JOIN perseus.dbo.perseus_user old ON new.domain_id = old.domain_id
	WHERE new.is_active = 1
		AND (new.name <> old.name 
			OR new.login <> old.login
			OR new.email <> old.mail)
GO',
    @additional_parameters = N'',
    @cmdexec_success_code = 0,
    @on_success_action = 1,
    @on_success_step_id = 0,
    @on_fail_action = 2,
    @on_fail_step_id = 0,
    @database_name = N'perseus',
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @flags = 0,
    @proxy_name = N'';

