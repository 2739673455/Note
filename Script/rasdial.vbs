sub connect()
	Wscript.Sleep 3000
	set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
	set colAdapters = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter WHERE NetConnectionID = 'ethernet'")
	For Each objAdapter in colAdapters
		connectStatus = objAdapter.NetConnectionStatus
		set colConfigs = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE Index = " & objAdapter.Index & " AND IPEnabled = True")
		For Each objConfig in colConfigs
			ipAddr = objConfig.IPAddress(0)
		Next
	Next
	set objWMIService = Nothing
	set ws = CreateObject("wscript.shell")
	if connectStatus=2 and (Mid(ipAddr,1,InStrRev(ipAddr,"."))="192.168.33." or Mid(ipAddr,1,7)="169.254") then
		ws.run "rasdial connect JYS3 jiaoyanshi3"
	end if
end sub

sub createTask()
	set service = CreateObject("Schedule.Service")
	service.Connect()

	set rootFolder = service.GetFolder("\")

	set taskDefinition = service.NewTask(0)

	set regInfo = taskDefinition.RegistrationInfo
	regInfo.Description = Now

	set trigger = taskDefinition.Triggers.Create(11)
	trigger.StateChange = 8 ' 8 表示工作站解锁

	set action = taskDefinition.actions.Create(0)
	action.Path = file
	action.Arguments = "connect"

	rootFolder.RegisterTaskDefinition "pppoe",taskDefinition,6,,,3,"" ' 6 表示创建或更新现有任务，3 表示使用当前用户登录信息（需要用户交互）
end sub

set args = WScript.Arguments
set fso = CreateObject("Scripting.FileSystemObject")
set file = fso.GetFile(WScript.ScriptFullName)

if args.Count=0 then
	set objShell = createobject("Shell.Application")
	cmd = "/c """ & file & " createTask"""
	objShell.ShellExecute "cmd.exe", cmd, "", "runas", 0
elseif args(0)="createTask" then
	createTask
	connect
elseif args(0)="connect" then
	connect
end if