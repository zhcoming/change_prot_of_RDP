::@author zh
::@email zhangha0@outlook.com
::@create date 2020-08-10 17:08:22
::@desc Change the port of RDP(Microsoft Remote Desktop service) 修改遠程桌面端口

@ECHO OFF
@mode con lines=25 cols=90
SETLOCAL EnableDelayedExpansion
title Change port of RDP v2.2 by zh
::判斷是否以管理員權限執行
>nul 2>&1 "%SYSTEMROOT%\system32\bcdedit.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (goto UACPrompt) else (goto UACAdmin)
:UACPrompt
echo 需要管理員權限...
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
:UACAdmin

::檢測
set _new=true
:check_service
echo.
echo --------------------------- 當前遠程桌面服務狀態 ---------------------------
echo.
set /p="Remote Desktop Services 服務狀態                             " <nul
sc query TermService | Find "RUNNING" >nul 2>&1 && (echo 正常運行中) || (echo 未運行)
set /p="Remote Desktop Services UserMode Port Redirector 服務狀態    " <nul
sc query UmRdpService| Find "RUNNING" >nul 2>&1 && (echo 正常運行中) || (echo 未運行)
set /p="系統設置中遠程桌面開啟狀態                                   " <nul
(reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections) | find "0x0" >nul 2>&1 && (echo 已開啟) || (echo 已關閉)
set /p="當前使用的端口號                                             " <nul
for /f "tokens=3 delims= " %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" ^| find "PortNumber"') do set /a port_number=%%a
echo %port_number%
set /p="端口開啟狀態                                                 " <nul
(netstat -an) | (find "LISTENING") | (find "%port_number%")   >nul 2>&1 && (echo 已開啟) || (echo 已關閉)
echo.
echo ----------------------------------------------------------------------------
if "%_new%"=="false" (goto end)


:wait_input
set continue=
set /p continue=是否修改當前端口號[y/n]:
if "%continue%"=="y" goto change_port
if "%continue%"=="n" goto exit_app
goto wait_input

@REM 修改端口
:change_port
echo.
echo ----------------------------------------
echo.
:input
set /p port_number=請輸入端口號(數字1~65536)：
  :: ↓ 判斷輸入是否為數字
echo %port_number%|findstr "^[0-9]*$" >nul && echo.>nul || goto input
  :: ↓ 判斷輸入是不是過大或過小
if %port_number% GTR 65536 goto input
if %port_number% LSS 1 goto input
set tpn=%port_number%
set str=0123456789abcde

::計算16進制值
:hex
set /a m=!tpn!/16
set /a n=!tpn!%%16
set n=!str:~%n%,1!
set h=!n!!h!
if !m! geq 16 set tpn=!m! &goto hex
set m=!str:~%m%,1!
set port_number_hex=0x!m!!h!
::變更注冊表中的端口號設置
echo.
echo ------------------------變更注冊表中的端口號:%port_number%------------------------
echo.
if not exist "%temp%\reg.exe" (copy c:\Windows\System32\reg.exe "%temp%\reg.exe" >nul)
set /p="設置注冊表項1/2:               " <nul
"%temp%\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo 成功) || (echo 失敗)
set /p="設置注冊表項2/2:               " <nul
"%temp%\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo 成功) || (echo 失敗)
ping 127.0.0.1 -n 1 >>nul 2>nul
del %temp%\reg.exe

::更新防火牆設置
echo.
echo -----------------------------更新防火牆設置-----------------------------
echo.
(netsh advfirewall firewall show rule name="Remote Desktop Services - Custom" >nul 2>&1) && goto update_firewall_rule

:add_firewall_rule
  set /p="防火牆規則不存在，新增中       " <nul
  netsh advfirewall firewall add rule name="Remote Desktop Services - Custom" dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1 && (echo 成功) || (echo 失敗)
  goto exit_firewall_set
:update_firewall_rule
  set /p="防火牆規則已存在，更新中       " <nul
  netsh advfirewall firewall set rule name="Remote Desktop Services - Custom" new dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1 && (echo 成功) || (echo 失敗)
:exit_firewall_set

::重啟遠端桌面服務
echo.
echo ---------------------------------重啟遠端桌面服務---------------------------------
echo.
set /p="正在設置 Remote Desktop Services UserMode Port Redirector 服務開機自啟動   " <nul
sc config UmRdpService start=auto >nul 2>&1 && (echo 成功) || (echo 失敗)
set /p="正在設置 Remote Desktop Services 服務開機自啟動                            " <nul
sc config TermService start=auto >nul 2>&1 && (echo 成功) || (echo 失敗)
set /p="正在開啟系統遠程桌面設置                                                   " <nul
(reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0x0 /f)  >nul 2>&1 && (echo 成功) || (echo 失敗)
set /p="正在停止 Remote Desktop Services UserMode Port Redirector 服務             " <nul
sc stop UmRdpService >nul 2>&1 && (echo 成功) || (echo 失敗)
set /p="正在停止 Remote Desktop Services 服務                                      " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc stop TermService >nul 2>&1 && (echo 成功) || (echo 失敗)
set /p="正在開啟 Remote Desktop Services 服務                                      " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc start TermService >nul 2>&1 && (echo 成功) || (echo 失敗)
set /p="正在開啟 Remote Desktop Services UserMode Port Redirector 服務             " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc start UmRdpService >nul 2>&1 && (echo 成功) || (echo 失敗)
echo.
set _new=false
goto check_service

:end
set /p="作業完成，請按[回車鍵]退出..."
:exit_app