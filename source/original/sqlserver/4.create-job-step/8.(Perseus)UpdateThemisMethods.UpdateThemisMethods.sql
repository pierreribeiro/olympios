EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'(Perseus) Update Themis Methods',
    @step_name = N'Update Themis Methods',
    @step_id = 2,
    @subsystem = N'PowerShell',
    @command = N'$url = "http://pegasus.amyris.local/services/themis/themis_method_sync";
$req = [System.Net.HttpWebRequest]::Create($url);
$req.Timeout=6000000;
$res = $req.GetResponse();',
    @additional_parameters = N'',
    @cmdexec_success_code = 0,
    @on_success_action = 1,
    @on_success_step_id = 0,
    @on_fail_action = 2,
    @on_fail_step_id = 0,
    @database_name = N'VBScript',
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @flags = 0,
    @proxy_name = N'';

