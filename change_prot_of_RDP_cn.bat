::@author zh
::@email zhangha0@outlook.com
::@create date 2020-08-10 17:08:22
::@desc Change the port of RDP(Microsoft Remote Desktop service) �޸�Զ������˿�

@ECHO OFF
@mode con lines=25 cols=90
SETLOCAL EnableDelayedExpansion
title Change port of RDP v2.2 by zh
::�ж��Ƿ��Թ���ԱȨ��ִ��
>nul 2>&1 "%SYSTEMROOT%\system32\bcdedit.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (goto UACPrompt) else (goto UACAdmin)
:UACPrompt
echo ��Ҫ����ԱȨ��...
%1 mshta vbscript:CreateObject("Shell.Application").ShellExecute("cmd.exe","/c %~s0 ::","","runas",1)(window.close)&&exit
:UACAdmin

::���
set _new=true
:check_service
echo.
echo --------------------------- ��ǰԶ���������״̬ ---------------------------
echo.
set /p="Remote Desktop Services ����״̬                             " <nul
sc query TermService | Find "RUNNING" >nul 2>&1 && (echo ����������) || (echo δ����)
set /p="Remote Desktop Services UserMode Port Redirector ����״̬    " <nul
sc query UmRdpService| Find "RUNNING" >nul 2>&1 && (echo ����������) || (echo δ����)
set /p="ϵͳ������Զ�����濪��״̬                                   " <nul
(reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections) | find "0x0" >nul 2>&1 && (echo �ѿ���) || (echo �ѹر�)
set /p="��ǰʹ�õĶ˿ں�                                             " <nul
for /f "tokens=3 delims= " %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" ^| find "PortNumber"') do set /a port_number=%%a
echo %port_number%
set /p="�˿ڿ���״̬                                                 " <nul
(netstat -an) | (find "LISTENING") | (find "%port_number%")   >nul 2>&1 && (echo �ѿ���) || (echo �ѹر�)
echo.
echo ----------------------------------------------------------------------------
if "%_new%"=="false" (goto end)


:wait_input
set continue=
set /p continue=�Ƿ��޸ĵ�ǰ�˿ں�[y/n]:
if "%continue%"=="y" goto change_port
if "%continue%"=="n" goto exit_app
goto wait_input

@REM �޸Ķ˿�
:change_port
echo.
echo ----------------------------------------
echo.
:input
set /p port_number=������˿ں�(����1~65536)��
  :: �� �ж������Ƿ�Ϊ����
echo %port_number%|findstr "^[0-9]*$" >nul && echo.>nul || goto input
  :: �� �ж������ǲ��ǹ�����С
if %port_number% GTR 65536 goto input
if %port_number% LSS 1 goto input
set tpn=%port_number%
set str=0123456789abcde

::����16����ֵ
:hex
set /a m=!tpn!/16
set /a n=!tpn!%%16
set n=!str:~%n%,1!
set h=!n!!h!
if !m! geq 16 set tpn=!m! &goto hex
set m=!str:~%m%,1!
set port_number_hex=0x!m!!h!
::���ע����еĶ˿ں�����
echo.
echo ------------------------���ע����еĶ˿ں�:%port_number%------------------------
echo.
if not exist "%temp%\reg.exe" (copy c:\Windows\System32\reg.exe "%temp%\reg.exe" >nul)
set /p="����ע�����1/2:               " <nul
"%temp%\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Wds\rdpwd\Tds\tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
set /p="����ע�����2/2:               " <nul
"%temp%\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d %port_number_hex% /f >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
ping 127.0.0.1 -n 1 >>nul 2>nul
del %temp%\reg.exe

::���·���ǽ����
echo.
echo -----------------------------���·���ǽ����-----------------------------
echo.
(netsh advfirewall firewall show rule name="Remote Desktop Services - Custom" >nul 2>&1) && goto update_firewall_rule

:add_firewall_rule
  set /p="����ǽ���򲻴��ڣ�������       " <nul
  netsh advfirewall firewall add rule name="Remote Desktop Services - Custom" dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
  goto exit_firewall_set
:update_firewall_rule
  set /p="����ǽ�����Ѵ��ڣ�������       " <nul
  netsh advfirewall firewall set rule name="Remote Desktop Services - Custom" new dir=in action=allow localport=%port_number% protocol=tcp interfacetype=any >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
:exit_firewall_set

::����Զ���������
echo.
echo ---------------------------------����Զ���������---------------------------------
echo.
set /p="�������� Remote Desktop Services UserMode Port Redirector ���񿪻�������   " <nul
sc config UmRdpService start=auto >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
set /p="�������� Remote Desktop Services ���񿪻�������                            " <nul
sc config TermService start=auto >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
set /p="���ڿ���ϵͳԶ����������                                                   " <nul
(reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0x0 /f)  >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
set /p="����ֹͣ Remote Desktop Services UserMode Port Redirector ����             " <nul
sc stop UmRdpService >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
set /p="����ֹͣ Remote Desktop Services ����                                      " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc stop TermService >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
set /p="���ڿ��� Remote Desktop Services ����                                      " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc start TermService >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
set /p="���ڿ��� Remote Desktop Services UserMode Port Redirector ����             " <nul
ping 127.0.0.1 -n 4 >>nul 2>nul
sc start UmRdpService >nul 2>&1 && (echo �ɹ�) || (echo ʧ��)
echo.
set _new=false
goto check_service

:end
set /p="��ҵ��ɣ��밴[�س���]�˳�..."
:exit_app