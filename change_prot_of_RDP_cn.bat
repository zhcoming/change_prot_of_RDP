::@author zh
::@email zhangha0@outlook.com
::@create date 2020-08-10 17:08:22
::@desc Change the port of RDP(Microsoft Remote Desktop service) 修改远程桌面端口

@ECHO OFF
@mode con lines=25 cols=90
SETLOCAL EnableDelayedExpansion
title Change port of RDP v2.2 by zh
::判断是否以管理员权限执行
>nul 2>&1 "%SYSTEMROOT%\system32\bcdedit.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (goto UACPrompt) else (goto UACAdmin)
:UACPrompt
echo 需要管理员权限...
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
:UACAdmin

::检测
set _new=true
:check_service
echo.
echo --------------------------- 当前远程桌面服务状态 ---------------------------
echo.
set /p="Remote Desktop Services 服务状态                             " <nul
sc query TermService | Find "RUNNING" >nul 2>&1 && (echo 正常运行中) || (echo 未运行)
set /p="Remote Desktop Services UserMode Port Redirector 服务状态    " <nul
sc query UmRdpService| Find "RUNNING" >nul 2>&1 && (echo 正常运行中) || (echo 未运行)
set /p="系统设置中远程桌面开启状态                                   " <nul
(reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections) | find "0x0" >nul 2>&1 && (echo 已开启) || (echo 已关闭)
set /p="当前使用的端口号                                             " <nul
for /f "tokens=3 delims= " %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" ^| find "PortNumber"') do set /a port_number=%%a
echo %port_number%
set /p="端口开启状态                                                 " <nul
(netstat -an) | (find "LISTENING") | (find "%port_number%")   >nul 2>&1 && (echo 已开启) || (echo 已关闭)
echo.
echo ----------------------------------------------------------------------------
if "%_new%"=="false" (goto end)


:wait_input
set continue=
set /p continue=是否修改当前端口号[y/n]:
if "%continue%"=="y" goto change_port
if "%continue%"=="n" goto exit_app
goto wait_input

@REM 修改端口
:change_port
echo.
echo ----------------------------------------
echo.
:input
set /p port_number=请输入端口号(数字1~65536)：
  :: ↓ 判断输入是否为数字
echo %port_number%|findstr "^[0-9]*$" >nul && echo.>nul || goto input
  :: ↓ 判断输入是不是过大或过小
if %port_number% GTR 65536 goto input
if %port_number% LSS 1 goto input
set tpn=%port_number%
set str=0123456789abcde

::计算16进制值
:hex
set /a m=!tpn!/16
set /a n=!tpn!%%16
set n=!str:~%n%,1!
set h=!n!!h!
if !m! geq 16 set tpn=!m! &goto hex
set m=!str:~%m%,1!
set port_number_hex=0x!m!!h!
::变更注册表中的端口号设置
echo.
echo ------------------------变更注册表中的端口号:%port_number%------------------------
echo.
if not exist "%temp%\reg.exe" (copy c:\Windows\System32\reg.exe "%temp%\reg.exe" >nul)
set /p="设置注册表项1/2:               " <nul
"%temp%\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo 成功) || (echo 失败)
set /p="设置注册表项2/2:               " <nul
"%temp%\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo 成功) || (echo 失败)
ping 127.0.0.1 -n 1 >>nul 2>nul
del %temp%\reg.exe

::更新防火墙设置
echo.
echo -----------------------------更新防火墙设置-----------------------------
echo.
(netsh advfirewall firewall show rule name="Remote Desktop Services - Custom" >nul 2>&1) && goto update_firewall_rule

:add_firewall_rule
  set /p="防火墙规则不存在，新增中       " <nul
  netsh advfirewall firewall add rule name="Remote Desktop Services - Custom" dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1 && (echo 成功) || (echo 失败)
  goto exit_firewall_set
:update_firewall_rule
  set /p="防火墙规则已存在，更新中       " <nul
  netsh advfirewall firewall set rule name="Remote Desktop Services - Custom" new dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1 && (echo 成功) || (echo 失败)
:exit_firewall_set

::重启远端桌面服务
echo.
echo ---------------------------------重启远端桌面服务---------------------------------
echo.
set /p="正在设置 Remote Desktop Services UserMode Port Redirector 服务开机自启动   " <nul
sc config UmRdpService start=auto >nul 2>&1 && (echo 成功) || (echo 失败)
set /p="正在设置 Remote Desktop Services 服务开机自启动                            " <nul
sc config TermService start=auto >nul 2>&1 && (echo 成功) || (echo 失败)
set /p="正在开启系统远程桌面设置                                                   " <nul
(reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0x0 /f)  >nul 2>&1 && (echo 成功) || (echo 失败)
set /p="正在停止 Remote Desktop Services UserMode Port Redirector 服务             " <nul
sc stop UmRdpService >nul 2>&1 && (echo 成功) || (echo 失败)
set /p="正在停止 Remote Desktop Services 服务                                      " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc stop TermService >nul 2>&1 && (echo 成功) || (echo 失败)
set /p="正在开启 Remote Desktop Services 服务                                      " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc start TermService >nul 2>&1 && (echo 成功) || (echo 失败)
set /p="正在开启 Remote Desktop Services UserMode Port Redirector 服务             " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc start UmRdpService >nul 2>&1 && (echo 成功) || (echo 失败)
echo.
set _new=false
goto check_service

:end
set /p="作业完成，请按[回车键]退出..."
:exit_app