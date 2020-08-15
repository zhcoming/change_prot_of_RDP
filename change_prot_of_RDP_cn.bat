::@author Z-h-o(zhanghao)
::@email zhangha0@outlook.com
::@create date 2020-08-10 17:08:22
::@modify date 2020-08-15 16:27:09
::@desc Change the port of RDP(Microsoft Remote Desktop service) 修改远程桌面端口

@ECHO OFF
SETLOCAL EnableDelayedExpansion
title Change port of RDP v1.0 by Z-h-o
::判断是否以管理员权限执行
>nul 2>&1 "%SYSTEMROOT%\system32\bcdedit.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (goto UACPrompt) else (goto UACAdmin)
:UACPrompt
echo 需要管理员权限...
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
:UACAdmin

::接受用户输入
echo ----------------------------------------
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
::变理注册表中的端口号设置
echo.
echo ------------------------变理注册表中的端口号设置------------------------
echo.
if not exist %temp%\reg.exe (cp c:\Windows\System32\reg.exe "%temp%\reg.exe")
set /p="设置注册表项1/2:               " <nul
%temp%\reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo 成功) || (echo 失败)
set /p="设置注册表项2/2:               " <nul
%temp%\reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo 成功) || (echo 失败)
ping 127.0.0.1 -n 1 >>nul 2>nul
del %temp%\reg.exe

::更新防火墙设置
echo.
echo -----------------------------更新防火墙设置-----------------------------
echo.
netsh advfirewall firewall show rule name="Remote Desktop Services - Custom" >nul 2>&1
if %ErrorLevel%==0 goto update_firewall_rule

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
echo ----------------------------重启远端桌面服务----------------------------
echo.
set /p="正在停止Remote Desktop Services UserMode Port Redirector服务    " <nul
sc stop UmRdpService >nul 2>&1 && (echo 成功) || (echo 失败)
ping 127.0.0.1 -n 2 >>nul 2>nul
set /p="正在停止Remote Desktop Services服务                             " <nul
sc stop TermService >nul 2>&1 && (echo 成功) || (echo 失败)
ping 127.0.0.1 -n 2 >>nul 2>nul
set /p="正在开启Remote Desktop Services UserMode Port Redirector服务    " <nul
sc start TermService >nul 2>&1 && (echo 成功) || (echo 失败)
set /p="正在开启Remote Desktop Services服务                             " <nul
sc start UmRdpService >nul 2>&1 && (echo 成功) || (echo 失败)
echo.
set /p="作业完成，请按[回车键]退出..."
