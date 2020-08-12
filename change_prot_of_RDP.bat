::@author Z-h-o(zhanghao)
::@email zhangha0@outlook.com
::@create date 2020-08-10 17:08:22
::@modify date 2020-08-11 17:15:21
::@desc Change the port of RDP(Microsoft Remote Desktop service) 修改遠程桌面端口

@ECHO OFF
SETLOCAL EnableDelayedExpansion
title Change port of RDP v1.0 by Z-h-o
::判斷是否以管理員權限執行
>nul 2>&1 "%SYSTEMROOT%\system32\bcdedit.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (goto UACPrompt) else (goto UACAdmin)
:UACPrompt
echo 需要管理員權限...
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
:UACAdmin

::接受用戶輸入
echo ----------------------------------------
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
::變理注冊表中的端口號設置
echo.
echo ------------------------變理注冊表中的端口號設置------------------------
echo.
set /p="設置注冊表項1/2:               " <nul
d:\ProgramFiles\MyCmdTools\reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo 成功) || (echo 失敗)
set /p="設置注冊表項2/2:               " <nul
d:\ProgramFiles\MyCmdTools\reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo 成功) || (echo 失敗)

::更新防火牆設置
echo.
echo -----------------------------更新防火牆設置-----------------------------
echo.
netsh advfirewall firewall show rule name="Remote Desktop Services - Custom" >nul 2>&1
if %ErrorLevel%==0 goto update_firewall_rule

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
echo ----------------------------重啟遠端桌面服務----------------------------
echo.
set /p="正在停止Remote Desktop Services UserMode Port Redirector服務    " <nul
sc stop UmRdpService >nul 2>&1 && (echo 成功) || (echo 失敗)
ping 127.0.0.1 -n 2 >>nul 2>nul
set /p="正在停止Remote Desktop Services服務                             " <nul
sc stop TermService >nul 2>&1 && (echo 成功) || (echo 失敗)
ping 127.0.0.1 -n 2 >>nul 2>nul
set /p="正在開啟Remote Desktop Services UserMode Port Redirector服務    " <nul
sc start TermService >nul 2>&1 && (echo 成功) || (echo 失敗)
set /p="正在開啟Remote Desktop Services服務                             " <nul
sc start UmRdpService >nul 2>&1 && (echo 成功) || (echo 失敗)
echo.
set /p="作業完成，請按回車鍵退出 Enter>"
