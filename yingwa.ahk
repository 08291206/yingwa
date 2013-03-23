#SingleInstance off ;
program_name:="Yingwa 0.1"
version:= "0.01.130324" 
;change icon. Must be here
menu, Tray, NoStandard
Menu, Tray, Icon, yingwa.exe, 2, 1
;acquire admin  
if not A_IsAdmin
{
   run *RunAs "%A_ScriptFullPath%",,UseErrorLevel  ; Requires v1.0.92.01+
   if ErrorLevel
	{
		msgbox,16,Yingwa Client, This program cannot run without administrative privileges.
		ExitApp
	}
   exitapp
}
;detect log off
DllCall("kernel32.dll\SetProcessShutdownParameters", UInt, 0x4FF, UInt, 0)
OnMessage(0x11, "WM_QUERYENDSESSION")
;end detect


if (Is64Bit()){
	ssocks_exe = ssocks64.exe
}else{
	ssocks_exe = ssocks32.exe
}

;close existing process if running
OnExit, ExitLabel

i=0
for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
  {
    if (process.Name="yingwa.exe")
      i+=1
  }
if (i=2)
	process, close, yingwa.exe

SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
DetectHiddenWindows, On
setting_dir=%A_ScriptDir%
privoxy_dir=%A_ScriptDir%\privoxy


iniread,ssocks_run, %setting_dir%\user.ini, variables, ssocks_run,0	


menu, tray, add,Show menu, ClickHandler
Menu, Tray, Default,Show menu
Menu, Tray, Add, Exit, ExitLabel
Menu, Tray, Click, 1
Menu,Tray, Tip, Yingwa version %version%		
Menu, Tool, add,Connect, quick_connect
Menu, Tool, Default,Connect

Menu, Tool, Add,Setup, setup
;Menu, Tool, Add,Show log, logfile
;menu, tool, add, About, about
Menu, Tool, Add,Exit, ExitLabel

DblClickSpeed := DllCall("GetDoubleClickTime") , firstClick := 0

connected:=0
goto, setup
return

setup:
if (disable_dbl_click)
	return
gui, 1:Destroy
if (connected=1)
{
	connect_bu:="&Disconnect"
}
else
{	
	connect_bu:="&Connect"
}
iniread ,ip, %setting_dir%\user.ini, variables, ip,%A_Space%
iniread ,password, %setting_dir%\user.ini, variables, Password,%A_Space%
iniread ,s_port, %setting_dir%\user.ini, variables, s_port,%A_Space%
restore_interface := 1

Gui, 1: Add, Text, x12 y19 w80 h20 , Server IP:
Gui, 1: Add, Edit, vip gsave x90 y19 w130 h20 , %ip%
Gui, 1: Add, Text, x12 y59 w80 h20 , Password:
Gui, 1: Add, Edit, vpassword gsave x90 y59 w130 h20 , %password%
Gui, 1: Add, Text, x12 y99 w80 h20 , Server Port:
Gui, 1: Add, Edit, vs_port gsave x90 y99 w130 h20 , %s_port%
gui, 1: Font, cblue 
Gui, 1: Add, Text, x12 y135 w100 h20 gopen_site, breakwallvpn.com
Gui, 1: Add, Text, x12 y155 w100 h20 gopen_site2, ut2.tv
gui, 1: Font, cblack 
Gui, 1: Add, Button, x120 y139 w100 h30 Default gconnect_button, %connect_bu%
; Generated using SmartGui, 1: Creator for SciTE
Gui +LastFound -Resize -MaximizeBox
Gui1 := WinExist() 
OnMessage( "0x112", "WM_SYSCOMMAND" ) 
Gui,1: Show, w227 h180, %program_name%
return

RemoveTrayTip:
TrayTip
return

save:
gui, 1:submit, nohide 
iniwrite ,%ip%, %setting_dir%\user.ini, variables, ip
iniwrite ,%password%, %setting_dir%\user.ini, variables, Password
iniwrite ,%s_port%, %setting_dir%\user.ini, variables, s_port
iniwrite ,%l_port%, %setting_dir%\user.ini, variables, l_port
return 

quick_connect:
restore_interface := 0	

goto, connect_button
return 
open_site:
run, http://breakwallvpn.com
return
open_site2:
run, http://ut2.tv
return
connect_button:
gui, 1:destroy
if (connected=1) ;disconnect if connected
{	
	
	splashtexton,,,Disconnecting...	
	disconnect_me()
	change_status("disconnect")
	if (restore_interface)
	{
	splashtextoff		
	goto, setup
	}
	exit
}

change_status("connect")
SplashTextOn, , , connecting...
iniread ,ip, %setting_dir%\user.ini, variables, ip,%A_Space%
iniread ,password, %setting_dir%\user.ini, variables, Password,%A_Space%
iniread ,s_port, %setting_dir%\user.ini, variables, s_port,%A_Space%
myfile=config.json
content=
	(
{
    "server":"%ip%",
    "server_port":%s_port%,
    "local_port":65509,
    "password":"%password%",
    "timeout":600,
    "method":null
}	
	)

file := fileopen(myfile, "w")
file.write(content)
File.Close()

run, %ssocks_exe%,%A_ScriptDir%,hide,ssocks_pid
IfWinNotExist,ahk_class PrivoxyLogWindow
	run, %privoxy_dir%\privoxy.exe,%privoxy_dir%,hide,privoxy_pid
setproxy("ON")
change_status("connected")

return

ClickHandler:
If ((A_TickCount-firstClick) < DblClickSpeed)   ; double click
{
   firstClick = 0   
	goto, setup
		
}
Else                  ; Single click
{
   firstClick := A_TickCount
   KeyWait, LButton
   KeyWait, LButton, % "D T" . DblClickSpeed/1000
   IF (ErrorLevel && firstClick)
	;MsgBox,, Tray Icon Single Click,Put here actions for Single Click.
   If ( A_ThisMenuItem = "Show Menu" )
        {
                Menu, Tool, Show
        }
}
Return

check_if_broken:		
	;return
	if WinExist(ssocks_exe) && WinExist("ahk_class PrivoxyLogWindow") 
	{
		return
	}
	disconnect_me()
	change_status("disconnect")
return

ExitLabel:
	if (connected)
	{	
		disconnect_me()	
	}
	winclose,ahk_class PrivoxyLogWindow
	process, close, privoxy.exe
	ExitApp

about:
gui, 1:Destroy

Msg:="Yingwa Shadowsocks Client " . version . "`nFirst released on 2013-03-23`nCoded by Chao Yi Fan`n`n" 
msg.="Autohotkey version: " . A_AhkVersion . "`n"
msg.="Icon designed by Double-J Design and edited using icoFX`n`n"
msg.="This program uses work of autohotkey, microsoft, Privoxy and clowwindy.`n`n"
msg.="Shadowsocks is written by clowwindy.`n`n"
msg.="What a wonder404 world."
MsgBox, 64, About,  %Msg%, 
Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disconnect_me()
{
	global
	gui, 1:Destroy
	settimer, check_if_broken, off
	setproxy("OFF")
	WinActivate,%ssocks_exe%
	send, ^c
	sleep, 1000
	winclose,%ssocks_exe%
	winwaitclose,%ssocks_exe%	
}

change_status(action,tray_tip="")
{
;inidelete,%a_appdata%\Microsoft\Network\Connections\Pbk\rasphone.pbk, Yingwa_Client 
global
	if (action=="disconnect")
	{
		settimer, check_if_broken, off
		if (tray_tip=="")
			tray_tip = Disconnected. %server_str%_%method_str%. Double click to change servers. Single click for menu items.
		tray_tip=%tray_tip%
		splashtextoff 
		TrayTip, Yingwa Client, %tray_tip%
		SetTimer, RemoveTrayTip, -5000
		Menu, Tray, Icon, yingwa.exe, 2, 1
		menu,tool,rename,Disconnect,Connect		
		menu,tool,enable,Connect	
		Menu,Tray, Tip, %tray_tip%				
		connected:=0
		disable_dbl_click := 0 ;鏀惧湪鍚庨潰
	}
	else
	if (action=="connect")
	{
		disable_dbl_click := 1
		tray_tip=Connecting to Yingwa...
		switcher:=1
		connected:=1 
		menu,tool,rename,Connect,Disconnect
		menu,tool,disable,Disconnect
		icon_no := 3
		;SetTimer, flash_icon, 100		
		TrayTip, Yingwa Client, %tray_tip%
		Menu,Tray, Tip, %tray_tip%
		SetTimer, RemoveTrayTip, -5000		
	}
	else
	if (action=="connected")
	{
		connected:=1
		menu,tool,enable,Disconnect	
		tray_tip = Successfully connected to Yingwa_Client.     
		Menu,Tray, Tip, Client Connected. %server_str%_%method_str%. 		
		
		splashtextoff 
		disable_dbl_click := 0   
		TrayTip, Yingwa Client, Successfully connected to Yingwa_Client.     		
		SetTimer, RemoveTrayTip, -5000
		settimer, check_if_broken, 5000
		disable_dbl_click := 0
		Menu, Tray, Icon, yingwa.exe, 1, 1	
	}
}


setproxy(state = "",address = "127.0.0.1:8118"){ 
if (address = "") and (state = "") 
    state = TOGGLE 

if address
    regwrite,REG_SZ,HKCU,Software\Microsoft\Windows\CurrentVersion\Internet Settings,ProxyServer,%address%
  if (state ="ON")
    regwrite,REG_DWORD,HKCU,Software\Microsoft\Windows\CurrentVersion\Internet Settings,Proxyenable,1
  else if (state="OFF")
    regwrite,REG_DWORD,HKCU,Software\Microsoft\Windows\CurrentVersion\Internet Settings,Proxyenable,0
  else if (state = "TOGGLE")
    {
      if regread("HKCU","Software\Microsoft\Windows\CurrentVersion\Internet Settings","Proxyenable") = 1
        regwrite,REG_DWORD,HKCU,Software\Microsoft\Windows\CurrentVersion\Internet Settings,Proxyenable,0
      else if regread("HKCU","Software\Microsoft\Windows\CurrentVersion\Internet Settings","Proxyenable") = 0
        regwrite,REG_DWORD,HKCU,Software\Microsoft\Windows\CurrentVersion\Internet Settings,Proxyenable,1 
    }
  dllcall("wininet\InternetSetOptionW","int","0","int","39","int","0","int","0")
  dllcall("wininet\InternetSetOptionW","int","0","int","37","int","0","int","0")
  Return
}
RegRead(RootKey, SubKey, ValueName = "") {
	RegRead, v, %RootKey%, %SubKey%, %ValueName%
	Return, v
}

Is64Bit() {
	envget temp_str, Processor_Identifier
   return (RegexMatch(temp_str, "^[^ ]+64") > 0)
}

WM_QUERYENDSESSION(wParam, lParam)
{
    global
	ENDSESSION_LOGOFF = 0x80000000
    if (lParam & ENDSESSION_LOGOFF){
			EventType = Logoff
			shutdown_code = 0
	}
    else{
			EventType = Shutdown
			shutdown_code = 9
	}
	if (connected:=1)
	{
		MsgBox, 36,Yingwa, Click Yes to restore your proxy settings.
		ifmsgbox, Yes
		{
			disconnect_me()
			change_status("disconnect")
			shutdown,%shutdown_code%
		}		
		return true
	}
	
}

;miminize to tray
WM_SYSCOMMAND( wParam, lParam, Msg, hWnd ) {
  Global R 
  If (A_Gui && wParam=0xF020) {
    MinimizeGuiToTray( R, hWnd )
    Return 0
}}

MinimizeGuiToTray( ByRef R, hGui ) { ; www.autohotkey.com/forum/viewtopic.php?p=214612#214612 
  WinGetPos, X0,Y0,W0,H0, % "ahk_id " (Tray:=WinExist("ahk_class Shell_TrayWnd")) 
  ControlGetPos, X1,Y1,W1,H1, TrayNotifyWnd1,ahk_id %Tray% 
  SW:=A_ScreenWidth,SH:=A_ScreenHeight,X:=SW-W1,Y:=SH-H1,P:=((Y0>(SH/3))?("B"):(X0>(SW/3)) 
  ? ("R"):((X0<(SW/3))&&(H0<(SH/3)))?("T"):("L")),((P="L")?(X:=X1+W0):(P="T")?(Y:=Y1+H0):) 
  VarSetCapacity(R,32,0), DllCall( "GetWindowRect",UInt,hGui,UInt,&R) 
  NumPut(X,R,16), NumPut(Y,R,20), DllCall("RtlMoveMemory",UInt,&R+24,UInt,&R+16,UInt,8 ) 
  DllCall("DrawAnimatedRects", UInt,hGui, Int,3, UInt,&R, UInt,&R+16 ) 
  ;WinHide, ahk_id %hGui%
  gui, 1:destroy
TrayTip, Yingwa, I am here! Click to show menu.
SetTimer, RemoveTrayTip, -3000  
}
