EXEC master.dbo.sp_addlinkedserver
    @server = N'ADSI',
    @srvproduct = N'Active Directory Service Interfaces',
    @provider = N'ADsDSOObject'

