::Change the port of RDP(Microsoft Remote Desktop service)
::�קﻷ�{�ୱ�ݤf
:: Author   zhangha0
:: E-mail   zhangha0@outlook.com
:: Date     2020-08-06
@ECHO OFF
SETLOCAL EnableDelayedExpansion
::�P�_�O�_�H�޲z���v������
rem >nul 2>&1 "%SYSTEMROOT%\system32\bcdedit.exe" "%SYSTEMROOT%\system32\config\system"
rem if '%errorlevel%' NEQ '0' (goto UACPrompt) else (goto UACAdmin)
rem :UACPrompt
rem %1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
rem :UACAdmin

echo ----------------------------------------
:input
set /p port_number=�п�J�ݤf��(�Ʀr)�G
  :: �� �P�_��J�O�_���Ʀr
echo %port_number%|findstr "^[0-9]*$" >nul && echo.>nul || goto input
  :: �� �P�_��J�O���O�L�j�ιL�p
if %port_number% GTR 65536 goto input
if %port_number% LSS 1 goto input
set tpn=%port_number%
set str=0123456789abcde

::�p��16�i�׭�
:hex
set /a m=!tpn!/16
set /a n=!tpn!%%16
set n=!str:~%n%,1!
set h=!n!!h!
if !m! geq 16 set tpn=!m! &goto hex
set m=!str:~%m%,1!

set port_number_hex=0x!m!!h!
::�ܲz�`�U�����ݤf���]�m
echo.
echo ------------------------�ܲz�`�U�����ݤf���]�m------------------------
echo.
set /p="�]�m�`�U��1/2:               " <nul
d:\ProgramFiles\MyCmdTools\reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1
if %ErrorLevel%==0 (echo ���\) else (echo ����)
set /p="�]�m�`�U��2/2:               " <nul
d:\ProgramFiles\MyCmdTools\reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1
if %ErrorLevel%==0 (echo ���\) else (echo ����)

::��s������]�m
echo.
echo -----------------------------��s������]�m-----------------------------
echo.
netsh advfirewall firewall show rule name="Remote Desktop Services - Custom" >nul 2>&1
if %ErrorLevel%==0 goto update_firewall_rule

:add_firewall_rule
  set /p="������W�h���s�b�A�s�W��       " <nul
  netsh advfirewall firewall add rule name="Remote Desktop Services - Custom" dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1
  if %ErrorLevel%==0 (echo ���\) else (echo ����)
  goto exit_firewall_set
:update_firewall_rule
  set /p="������W�h�w�s�b�A��s��       " <nul
  netsh advfirewall firewall set rule name="Remote Desktop Services - Custom" new dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1
  if %ErrorLevel%==0 (echo ���\) else (echo ����)
:exit_firewall_set

::���һ��ݮୱ�A��
echo.
echo ----------------------------���һ��ݮୱ�A��----------------------------
echo.
set /p="���b����Remote Desktop Services UserMode Port Redirector�A��    " <nul
sc stop UmRdpService >nul 2>&1
if %ErrorLevel%==0 (echo ���\) else (echo ����)
ping 127.0.0.1 -n 2 >>nul 2>nul
set /p="���b����Remote Desktop Services�A��                             " <nul
sc stop TermService >nul 2>&1
if %ErrorLevel%==0 (echo ���\) else (echo ����)
ping 127.0.0.1 -n 2 >>nul 2>nul
set /p="���b�}��Remote Desktop Services UserMode Port Redirector�A��    " <nul
sc start TermService >nul 2>&1
if %ErrorLevel%==0 (echo ���\) else (echo ����)
set /p="���b�}��Remote Desktop Services�A��                             " <nul
sc start UmRdpService >nul 2>&1
if %ErrorLevel%==0 (echo ���\) else (echo ����)
echo.
set /p="�@�~�����A�Ы��^����h�X."
