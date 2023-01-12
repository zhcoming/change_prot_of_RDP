::@author zh
::@email zhangha0@outlook.com
::@create date 2020-08-10 17:08:22
::@desc Change the port of RDP(Microsoft Remote Desktop service) �קﻷ�{�ୱ�ݤf

@ECHO OFF
@mode con lines=25 cols=90
SETLOCAL EnableDelayedExpansion
title Change port of RDP v2.2 by zh
::�P�_�O�_�H�޲z���v������
>nul 2>&1 "%SYSTEMROOT%\system32\bcdedit.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (goto UACPrompt) else (goto UACAdmin)
:UACPrompt
echo �ݭn�޲z���v��...
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
:UACAdmin

::�˴�
set _new=true
:check_service
echo.
echo --------------------------- ��e���{�ୱ�A�Ȫ��A ---------------------------
echo.
set /p="Remote Desktop Services �A�Ȫ��A                             " <nul
sc query TermService | Find "RUNNING" >nul 2>&1 && (echo ���`�B�椤) || (echo ���B��)
set /p="Remote Desktop Services UserMode Port Redirector �A�Ȫ��A    " <nul
sc query UmRdpService| Find "RUNNING" >nul 2>&1 && (echo ���`�B�椤) || (echo ���B��)
set /p="�t�γ]�m�����{�ୱ�}�Ҫ��A                                   " <nul
(reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections) | find "0x0" >nul 2>&1 && (echo �w�}��) || (echo �w����)
set /p="��e�ϥΪ��ݤf��                                             " <nul
for /f "tokens=3 delims= " %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" ^| find "PortNumber"') do set /a port_number=%%a
echo %port_number%
set /p="�ݤf�}�Ҫ��A                                                 " <nul
(netstat -an) | (find "LISTENING") | (find "%port_number%")   >nul 2>&1 && (echo �w�}��) || (echo �w����)
echo.
echo ----------------------------------------------------------------------------
if "%_new%"=="false" (goto end)


:wait_input
set continue=
set /p continue=�O�_�ק��e�ݤf��[y/n]:
if "%continue%"=="y" goto change_port
if "%continue%"=="n" goto exit_app
goto wait_input

@REM �ק�ݤf
:change_port
echo.
echo ----------------------------------------
echo.
:input
set /p port_number=�п�J�ݤf��(�Ʀr1~65536)�G
  :: �� �P�_��J�O�_���Ʀr
echo %port_number%|findstr "^[0-9]*$" >nul && echo.>nul || goto input
  :: �� �P�_��J�O���O�L�j�ιL�p
if %port_number% GTR 65536 goto input
if %port_number% LSS 1 goto input
set tpn=%port_number%
set str=0123456789abcde

::�p��16�i���
:hex
set /a m=!tpn!/16
set /a n=!tpn!%%16
set n=!str:~%n%,1!
set h=!n!!h!
if !m! geq 16 set tpn=!m! &goto hex
set m=!str:~%m%,1!
set port_number_hex=0x!m!!h!
::�ܧ�`�U�����ݤf���]�m
echo.
echo ------------------------�ܧ�`�U�����ݤf��:%port_number%------------------------
echo.
if not exist "%temp%\reg.exe" (copy c:\Windows\System32\reg.exe "%temp%\reg.exe" >nul)
set /p="�]�m�`�U��1/2:               " <nul
"%temp%\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo ���\) || (echo ����)
set /p="�]�m�`�U��2/2:               " <nul
"%temp%\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo ���\) || (echo ����)
ping 127.0.0.1 -n 1 >>nul 2>nul
del %temp%\reg.exe

::��s������]�m
echo.
echo -----------------------------��s������]�m-----------------------------
echo.
(netsh advfirewall firewall show rule name="Remote Desktop Services - Custom" >nul 2>&1) && goto update_firewall_rule

:add_firewall_rule
  set /p="������W�h���s�b�A�s�W��       " <nul
  netsh advfirewall firewall add rule name="Remote Desktop Services - Custom" dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1 && (echo ���\) || (echo ����)
  goto exit_firewall_set
:update_firewall_rule
  set /p="������W�h�w�s�b�A��s��       " <nul
  netsh advfirewall firewall set rule name="Remote Desktop Services - Custom" new dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1 && (echo ���\) || (echo ����)
:exit_firewall_set

::���һ��ݮୱ�A��
echo.
echo ---------------------------------���һ��ݮୱ�A��---------------------------------
echo.
set /p="���b�]�m Remote Desktop Services UserMode Port Redirector �A�ȶ}���۱Ұ�   " <nul
sc config UmRdpService start=auto >nul 2>&1 && (echo ���\) || (echo ����)
set /p="���b�]�m Remote Desktop Services �A�ȶ}���۱Ұ�                            " <nul
sc config TermService start=auto >nul 2>&1 && (echo ���\) || (echo ����)
set /p="���b�}�Ҩt�λ��{�ୱ�]�m                                                   " <nul
(reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0x0 /f)  >nul 2>&1 && (echo ���\) || (echo ����)
set /p="���b���� Remote Desktop Services UserMode Port Redirector �A��             " <nul
sc stop UmRdpService >nul 2>&1 && (echo ���\) || (echo ����)
set /p="���b���� Remote Desktop Services �A��                                      " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc stop TermService >nul 2>&1 && (echo ���\) || (echo ����)
set /p="���b�}�� Remote Desktop Services �A��                                      " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc start TermService >nul 2>&1 && (echo ���\) || (echo ����)
set /p="���b�}�� Remote Desktop Services UserMode Port Redirector �A��             " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc start UmRdpService >nul 2>&1 && (echo ���\) || (echo ����)
echo.
set _new=false
goto check_service

:end
set /p="�@�~�����A�Ы�[�^����]�h�X..."
:exit_app