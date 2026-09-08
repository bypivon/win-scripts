@echo off
title bypivon_kbm_script - bypivon@protonmail.com

REM =============================================
REM script para Windows 10/11
REM author: bypivon
REM mail: bypivon@protonmail.com
REM site: https://sites.google.com/view/bypivon/home
REM github: https://github.com/bypivon/win-scripts
REM ps1: Invoke-WebRequest -Uri https://github.com/bypivon/win-scripts/archive/refs/heads/main.zip -OutFile "%USERPROFILE%\Desktop\win-scripts.zip"
REM =============================================

REM =============================================
REM VERIFICATION OF PRIVILEGES (ADMIN)
REM =============================================
REM Comprobar pwsh
if not exist "%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe" (
   echo [ERROR]: %SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe not found.
   pause
   exit /b 1
)
REM Comprobar privilegios y relanzar si no es admin
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$IsAdmin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); if(-not $IsAdmin){try{Start-Process -FilePath '%~f0' -Verb RunAs}catch{Write-Error 'Elevacion rechazada o fallida.';exit 1}; exit 1}"
REM Si no es admin y falla la elevacion, cerrar el script
if %errorlevel% neq 0 (
   echo [ERROR]: Admin privileges not granted.
   exit /b 1
)
REM =============================================
REM VALIDATE WIN TOOLS
REM =============================================
if not exist "%SYSTEMROOT%\System32\reg.exe" (
   echo [ERROR]: %SYSTEMROOT%\System32\reg.exe not found.
   pause
   exit /b 1
)
REM =============================================
setlocal EnableDelayedExpansion
REM =============================================
REM Definir ruta logfile en el directorio ejecutable del script
set "log_file=%~dp0reglog_kbm.txt"
REM =============================================
REM Escape ANSI y Colores ANSI
set "ESC="
set "r=%ESC%[31m"
set "g=%ESC%[32m"
set "y=%ESC%[33m"
set "b=%ESC%[34m"
set "c=%ESC%[36m"
set "m=%ESC%[35m"
set "w=%ESC%[37m"
set "rset=%ESC%[0m"
REM ALERTS
set "alert_success=%g%[SUCCESS]:%rset%"
set "alert_warning=%y%[WARN]:%rset%"
set "alert_error=%r%[ERROR]:%rset%"
set "alert_info=%c%[INFO]:%rset%"
set "alert_status=%m%[ESTADO]:%rset%"
set "alert_log=%c%[LOG]:%rset%"
set "alert_question=[?]:"
REM =============================================
REM MAIN MENU
REM =============================================
:menu_kbm
cls
echo ------------------------------------------------------------------------------------------------------------------------
echo  MOUSE Y TECLADO - improves the feel of your peripherals
echo ------------------------------------------------------------------------------------------------------------------------
echo.
echo %alert_info% Aplicar mejoras para el mouse y teclado, ademas quita los sonidos del sistema.
echo.
echo 1. Aplicar tweaks
echo 2. Restablecer valores predeterminados
echo 3. Crear punto de restauracion
echo.
echo ------------------------------------------------------------------------------------------------------------------------
echo                                                                                                    S. Salir
echo ------------------------------------------------------------------------------------------------------------------------
choice /c 123s /n /m "%alert_question%Seleccione una opcion:"
if errorlevel 4 exit
if errorlevel 3 ( start "" "%SystemRoot%\System32\SystemPropertiesProtection.exe" & goto menu_kbm )
if errorlevel 2 goto opcion_2
if errorlevel 1 goto opcion_1
:opcion_1
 set "msg_alert=Aplicando ajustes"
 REM set "MouseFeedbackEnabled=0"
 set "MouseSensitivity=10"
 set "MouseDelay=0"
 set "MouseSpeed=0"
 set "KeyboardDelay=0"
 set "KeyboardSpeed=31"
 set "MouseThreshold1=0"
 set "MouseThreshold2=0"
 set "MouseTrails=0"
 set "DoubleClickSpeed=480"
 set "ActiveWindowTracking=0"
 set "DataQueueSize=16"
 set "apply_curve=0"
 set "nosound=0"
   echo %alert_info% Recomendado para Win10, si selecciona NO se usara la curva default.
   choice /c YNO /n /m "%alert_question%Desea aplicar el fix por MarkC? Y/N/O:"
   if errorlevel 3 goto menu_kbm
   if errorlevel 2 goto winsound
   if errorlevel 1 (
      set "apply_curve=1"
      set "SmoothMouseXCurve=0000000000000000c0cc0c0000000000809919000000000040662600000000000033330000000000"
      set "SmoothMouseYCurve=0000000000000000000038000000000000007000000000000000a800000000000000e00000000000"
   )
:winsound
   echo %alert_info% Desactiva los sonidos de Windows, asi evitar confusiones.
   choice /c YNO /n /m "%alert_question%Desea desactivar todos los sonidos del sistema? Y/N/O:"
   if errorlevel 3 goto menu_kbm
   if errorlevel 2 goto apply_kbm_tweaks
   if errorlevel 1 (
      set "nosound=1"
      set "WinSounds=.None"
      set "UserDuckingPreference=3"
      set "Beep=no"
      set "ExtendedSounds=no"
      goto apply_kbm_tweaks
   )
:opcion_2
 set "msg_alert=Restableciendo valores predeterminados"
 REM set "MouseFeedbackEnabled=1"
 set "MouseSensitivity=10"
 set "MouseDelay=1"
 set "MouseSpeed=1"
 set "KeyboardDelay=1"
 set "KeyboardSpeed=31"
 set "MouseThreshold1=6"
 set "MouseThreshold2=10"
 set "MouseTrails=0"
 set "DoubleClickSpeed=500"
 set "ActiveWindowTracking=0"
 set "DataQueueSize=100"
 set "WinSounds=.Default"
 set "Beep=yes"
 set "ExtendedSounds=yes"
 set "UserDuckingPreference=1"
 set "SmoothMouseXCurve=0000000000000000156e000000000000004001000000000029dc0300000000000000280000000000"
 set "SmoothMouseYCurve=0000000000000000fd11010000000000002404000000000000fc12000000000000c0bb0100000000"
 set "apply_curve=1"
 set "nosound=1"
goto apply_kbm_tweaks

REM Curve Mouse fix credits MarkC (https://donewmouseaccel.blogspot.com/2010/04/markc-mouse-acceleration-fix-builder.html)
REM Si no usa el control deslizante de velocidad del puntero del ratón configurado en 6/11 y desea una precisión 1:1 en el juego, configure el juego para que habilite la opción "Mejorar la precisión del puntero" en el Panel de control.
REM Si desea la aceleración de Windows 2000+98+95 en el juego, configure el juego para que habilite la opción "Mejorar la precisión del puntero" en el Panel de control.
REM (Por ejemplo, en Counter-Strike: Source y otros juegos de Source, usa -useforcedmparms y no -noforcemspd.
REM En Half-Life y Counter-Strike 1.6, no uses -noforcemspd ni -noforcemparms).
REM ¡Disfruta de una respuesta exacta del ratón al puntero con la configuración personalizada de tu escritorio!)
REM Mouse and keyboard buffer sizes credits (https://sites.google.com/view/melodystweaks/home)
:apply_kbm_tweaks
   echo %alert_log% %msg_alert%..

   REM AJUSTES MOUSE
   REM https://www.elevenforum.com/t/enable-or-disable-mouse-haptic-feedback-in-windows-11.46083/
   REM call :reg_add_log "HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Windows\EnhancedPenSupport" "MouseFeedbackEnabled" REG_DWORD "%MouseFeedbackEnabled%"

   REM LIMITACION DE LA FRECUENCIA DEL MOUSE PARA APPS EN 2DO PLANO (LAS APPS EN 2DO PLANO NO NECESITAN ALTAS TASAS DE SONDEO COMO LAS APPS EN 1ER PLANO)
   REM Podría ser útil en casos como el de un usuario con una CPU extremadamente lenta y un ratón de 8000 Hz.
   REM https://blogs.windows.com/windowsdeveloper/2023/05/26/delivering-delightful-performance-for-more-than-one-billion-users-worldwide/
   REM reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "RawMouseThrottleEnabled" /t REG_DWORD /d 1 /f
   REM reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "RawMouseThrottleDuration" /t REG_DWORD /d 20 /f

   REM MOUSE ACCEL
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "MouseSpeed" "REG_SZ" "%MouseSpeed%"
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "MouseThreshold1" "REG_SZ" "%MouseThreshold1%"
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "MouseThreshold2" "REG_SZ" "%MouseThreshold2%"
   REM MAS MOUSE
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "MouseSensitivity" "REG_SZ" "%MouseSensitivity%"
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "DoubleClickSpeed" "REG_SZ" "%DoubleClickSpeed%"
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "MouseDelay" "REG_SZ" "%MouseDelay%"
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "MouseTrails" "REG_SZ" "%MouseTrails%"
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "ActiveWindowTracking" "REG_DWORD" "%ActiveWindowTracking%"
   REM cantidad de eventos que pueden ser almacenados en la cola del controlador del mouse (tweak=16, defalut=100)
   call :reg_add_log "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" "MouseDataQueueSize" "REG_DWORD" "%DataQueueSize%"

   REM AJUSTES TECLADO
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Keyboard" "KeyboardDelay" "REG_SZ" "%KeyboardDelay%"
   call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Keyboard" "KeyboardSpeed" "REG_SZ" "%KeyboardSpeed%"
   REM cantidad de eventos que pueden ser almacenados en la cola del controlador del teclado (tweak=16, defalut=100)
   call :reg_add_log "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" "KeyboardDataQueueSize" "REG_DWORD" "%DataQueueSize%"

   if "%apply_curve%"=="1" (
      REM CURVA
      call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "SmoothMouseXCurve" "REG_BINARY" "%SmoothMouseXCurve%"
      call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "SmoothMouseYCurve" "REG_BINARY" "%SmoothMouseYCurve%"
   )
   if "%nosound%"=="1" (
      REM SONIDOS DE WINDOWS
      call :reg_add_log "HKEY_CURRENT_USER\AppEvents\Schemes" "/ve" "REG_SZ" "%WinSounds%"
      REM Desactivar beep del sistema
      call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Sound" "Beep" "REG_SZ" "%Beep%"
      REM Sonidos extendidos (eventos de Windows)
      call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Sound" "ExtendedSounds" "REG_SZ" "%ExtendedSounds%"
      REM COMUNICACIONES (UserDuckingPreference - 0: Desactivar el resto de los sonidos cuando windows detecta actividad, 1: 80% reduccion, 2: 50% reduccion, 3: No hacer nada)
      call :reg_add_log "HKEY_CURRENT_USER\Software\Microsoft\Multimedia\Audio" "UserDuckingPreference" "REG_DWORD" "%UserDuckingPreference%"
   )

   echo %alert_log% Puedes revisar logs en el directorio de ejecucion del script.
   echo %alert_success% Ajustes aplicados. Reinicia.
   pause

goto menu_kbm

REM =============================================
REM FUNCTIONS
REM =============================================
REM GET TIMESTAMP
REM =============================================
:get_ts
 for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd-HH:mm:ss')"`) do set "ts=%%t"
goto :eof
REM =============================================
REM ADD/UPDATE REGLOG
REM Uso: call :reg_add_log "HKEY_CURRENT_USER\Control Panel\Mouse" "MouseSensitivity" REG_SZ "1"
REM =============================================
:reg_add_log
 set "key_path=%~1"
 set "value_name=%~2"
 set "value_type=%~3"
 set "data=%~4"
 call :get_ts

REM comprobar existencia
if not defined key_path (
   echo [!ts!]-[AddModifyKey-ErrorNull] Missing KeyPath - !value_name! - !value_type! - !data! >> "%log_file%"
   goto :eof
)
REM caso especial /ve
if /i "!value_name!"=="/ve" (
   if "!data!"=="" (
      echo [!ts!]-[AddModifyKey-ErrorNull] Missing Data - !key_path! - !value_type! >> "%log_file%"
      goto :eof
   )
   reg add "!key_path!" /ve /d "!data!" /f >nul 2>&1
   if !errorlevel! equ 0 (
      echo [!ts!]-[AddModifyKey-Ok] !key_path! - !value_type! - !data! >> "%log_file%"
   ) else (
      echo [!ts!]-[AddModifyKey-Error] Unexpected error - !key_path! - !value_type! - !data! >> "%log_file%"
   )
   goto :eof
)
if not defined value_name (
   echo [!ts!]-[AddModifyKey-ErrorNull] Missing ValueName - !key_path! - !value_type! - !data! >> "%log_file%"
   goto :eof
)
if not defined value_type (
   echo [!ts!]-[AddModifyKey-ErrorNull] Missing ValueType - !key_path! - !value_name! - !data! >> "%log_file%"
   goto :eof
)
if not defined data (
   echo [!ts!]-[AddModifyKey-ErrorNull] Missing Data - !key_path! - !value_name! - !value_type! >> "%log_file%"
   goto :eof
)

REM ejecutar reg add y capturar salida
reg add "!key_path!" /v "!value_name!" /t !value_type! /d "!data!" /f >nul 2>&1
if !errorlevel! equ 0 (
   echo [!ts!]-[AddModifyKey-Ok] !key_path! - !value_name! - !value_type! - !data! >> "%log_file%"
) else (
   echo [!ts!]-[AddModifyKey-Error] Unexpected error !key_path! - !value_name! - !value_type! - !data! >> "%log_file%"
)
goto :eof

REM =============================================
REM DELETE VALUE/KEY REGLOG
REM Uso para borrar valor: call :reg_del_log "HKEY_CURRENT_USER\Control Panel\Mouse" "MouseSensitivity"
REM Uso para borrar clave: call :reg_del_log "HKEY_CURRENT_USER\Control Panel\Mouse"
REM =============================================
:reg_del_log
 set "key_path=%~1"
 set "value_name=%~2"
 call :get_ts

if defined value_name (
   REM borrar valor concreto
   reg delete "!key_path!" /v "!value_name!" /f >nul 2>&1
   if !errorlevel! equ 0 (
      echo [!ts!]-[DeletedValue-Ok] !key_path! - !value_name! >> "%log_file%"
   ) else (
      echo [!ts!]-[DeletedValue-Error] Missing !key_path! - !value_name! >> "%log_file%"
   )
) else (
   REM borrar clave completa
   reg delete "!key_path!" /f >nul 2>&1
   if !errorlevel! equ 0 (
      echo [!ts!]-[DeletedKey-Ok] !key_path! >> "%log_file%"
   ) else (
      echo [!ts!]-[DeletedKey-Error] Missing !key_path! >> "%log_file%"
   )   
)
goto :eof

REM =============================================
REM END FUNCTIONS & SCRIPT
REM =============================================

endlocal
exit