@echo off
chcp 65001 >nul 2>&1
title bypivon_system_cleaner_script - bypivon@protonmail.com
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
   echo [ERROR]: powershell.exe not found.
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
   echo [ERROR]: reg.exe not found.
   pause
   exit /b 1
)
if not exist "%SYSTEMROOT%\System32\sc.exe" (
   echo [ERROR]: sc.exe not found.
   pause
   exit /b 1
)
if not exist "%SYSTEMROOT%\System32\cleanmgr.exe" (
   echo [ERROR]: cleanmgr.exe not found.
   pause
   exit /b 1
)
if not exist "%SYSTEMROOT%\System32\vssadmin.exe" (
   echo [ERROR]: vssadmin.exe not found.
   pause
   exit /b 1
)
REM =============================================
setlocal EnableDelayedExpansion
REM =============================================
REM Definir ruta logfile en el directorio ejecutable del script
set "log_file=%~dp0cleanlog_sys.txt"
REM =============================================
REM Escape ANSI y Colores ANSI
REM =============================================
set "ESC="
set "r=%ESC%[31m"
set "g=%ESC%[32m"
set "y=%ESC%[33m"
set "b=%ESC%[34m"
set "c=%ESC%[36m"
set "m=%ESC%[35m"
set "w=%ESC%[37m"
set "rset=%ESC%[0m"
REM =============================================
REM ALERTS
REM =============================================
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
:menu_cleaner
cls
echo ------------------------------------------------------------------------------------------------------------------------
echo  LIMPIADOR DEL SISTEMA OPERATIVO - basic and solid system cleaner
echo ------------------------------------------------------------------------------------------------------------------------
echo.
echo %alert_info% La limpieza completa elimina archivos de Descargas, Documentos, Musica, Papelera, etc.
echo         Tambien residuos de NVIDIA, AMD, Epic, Steam y Discord.
echo %alert_warning% Cierre todo antes de ejecutar.
echo.
echo 1. Realizar limpieza profunda
echo 2. Crear punto de restauracion
echo.
echo ------------------------------------------------------------------------------------------------------------------------
echo                                                                                                    S. Salir
echo ------------------------------------------------------------------------------------------------------------------------
choice /c 12s /n /m "%alert_question%Seleccione una opcion:"
if errorlevel 3 exit
if errorlevel 2 ( start "" "%SystemRoot%\System32\SystemPropertiesProtection.exe" & goto menu_cleaner )
if errorlevel 1 goto opcion_1
:opcion_1
echo %alert_warning% Seguro que desea comenzar la limpieza?
choice /c YN /n /m "%alert_question% Presione Y/N:"
if errorlevel 2 goto menu_cleaner
if errorlevel 1 goto clean_confirm

:clean_confirm
   echo %alert_log% Finalizando explorador ..
   taskkill /F /IM explorer.exe >nul 2>&1

   REM Limpiar archivos temporales
   echo %alert_log% Limpiando temporales sistema y usuario ..
   call :clean_path_all "%SystemRoot%\Temp"
   call :clean_path_all "%Temp%"
   call :clean_file "%SystemDrive%\*.tmp"
   call :clean_file "%SystemRoot%\System32\config\systemprofile\AppData\Local\*.tmp"

   REM Limpiar prefetch
   echo %alert_log% Limpiando prefetch ..
   call :clean_path_all "%SystemRoot%\Prefetch"

   REM Limpiar archivos old, chkdisk y bak
   echo %alert_log% Limpiando archivos de instalaciones anteriores, restos de archivos recuperados y copia de respaldo ..
   REM del /s /f /q "%SystemDrive%\*.old" > puede perjudicar borrar a nivel de disco
   REM del /s /f /q "%SystemDrive%\*.chk" > puede perjudicar borrar a nivel de disco
   REM del /s /f /q "%SystemDrive%\*.bak" > puede perjudicar borrar a nivel de disco
   for %%p in ( "%Temp%" "%SystemRoot%\Temp" "%SystemRoot%\Prefetch" "%AppData%" "%ProgramData%" ) do (
      call :clean_file "%%~p\*.old"
      call :clean_file "%%~p\*.chk"
      call :clean_file "%%~p\*.bak"
      call :clean_file "%%~p\*.tmp"
      call :clean_file "%%~p\*.log"
      call :clean_file "%%~p\*.dmp"
      call :clean_file "%%~p\*.swp"
      call :clean_file "%%~p\*.DS_Store"
   )

   echo %alert_log% Limpiando archivos log ..
   REM limpia todo log del sistema pero algunos podrian ser importantes
   REM call :clean_file "%SystemDrive%\*.log"
   REM call :clean_file "%ProgramData%\*.log"
   REM call :clean_file "%AppData%\*.log"
   call :clean_path_all "%SystemRoot%\Logs"
   call :clean_path_all "%SystemDrive%\PerfLogs"

   REM El uso del parámetro /ResetBase junto con el parámetro /StartComponentCleanup de DISM.exe en una versión en ejecución de Windows 10 o posterior 
   REM elimina todas las versiones sustituidas de cada componente del almacén de componentes.
   echo %alert_log% Limpiando temporales del almacen de componentes ..
   REM Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
   call :clean_path_all "%SystemRoot%\WinSxS\Temp"

   REM Carpeta temporal de instaladores de Microsoft x86.
   echo %alert_log% Limpiando temporales de instaladores de Microsoft x86 ..
   call :clean_path_all "%ProgramFiles(x86)%\Microsoft\Temp"
   call :clean_path_all "%ProgramFiles(x86)%\Temp"
   call :clean_file "%ProgramFiles%\WindowsApps.tmp"

   REM Limpiar restos de instalacion MS OFFICE
   echo %alert_log% Limpiando restos de instalacion MSOffice ..
   call :clean_folder "%SystemDrive%\MSOCache"

   REM Windows Search Indexer temp
   echo %alert_log% Limpiando temporales del indexador ..
   call :clean_path_all "%ProgramData%\Microsoft\Search\Data\Temp"

   REM Limpiar archivos y documentos recientes
   echo %alert_log% Limpiando archivos y documentos recientes ..
   call :clean_path_all "%AppData%\Microsoft\Windows\Recent"
   call :clean_path_all "%AppData%\Microsoft\Windows\Recent\CustomDestinations"
   call :clean_path_all "%AppData%\Microsoft\Windows\Recent\AutomaticDestinations"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\Recent"

   REM Limpiar archivos portapapeles
   echo %alert_log% Limpiando archivos portapapeles ..
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\CloudStore"
   call :clean_path_all "%AppData%\Microsoft\Windows\CloudStore"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\CloudAPCache\MicrosoftAccount"
   REM call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\CloudAPCache\AzureAD"

   REM Limpiar historial de navegacion y actividad del usuario
   echo %alert_log% Limpiando historial de navegacion y actividad del usuario en el explorador de archivos ..
   call :clean_folder "%LocalAppData%\Microsoft\Windows\History"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\History"

   REM Limpiar cache microsoft
   echo %alert_log% Limpiando cache del sistema general y mas ..
   REM Cachés de Windows (miniaturas, datos temporales, etc)
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\Caches"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Caches"
   REM Caché de Internet
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\INetCache"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache"
   REM call :clean_path_all "%LocalAppData%\Microsoft\Windows\Burn"
   REM call :clean_path_all "%LocalAppData%\Microsoft\Windows\Ringtones"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\ActionCenterCache"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\IECompatCache"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\IECompatUaCache"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\PPBCompatCache"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\PPBCompatUaCache"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\PRICache"
   REM Stores crash dump files for various applications
   call :clean_path_all "%LocalAppData%\CrashDumps"

   REM BASURA EN LA UNIDAD PRINCIPAL DEL SISTEMA
   echo %alert_log% Limpiando logs y temporales unidad principal del sistema ..
   REM Archivos de log generados por aplicaciones de 32 bits en sistemas de 64 bits.
   call :clean_path_all "%SystemRoot%\SysWOW64\LogFiles"
   REM Carpeta temporal usada por procesos del sistema.
   call :clean_path_all "%SystemRoot%\SystemTemp"
   REM Cumple la función de almacenar registros de distintos servicios y componentes del sistema operativo
   call :clean_path_all "%SystemRoot%\System32\LogFiles"
   REM Contiene archivos de depuración y logs (ej. Netlogon.log).
   call :clean_path_all "%SystemRoot%\debug"
   REM Logs de actividad de módems y conexiones telefónicas.
   call :clean_path_all "%SystemRoot%\ModemLogs"
   call :clean_path_all "%SystemRoot%\LiveKernelReports"
   call :clean_path_all "%SystemRoot%\security\logs"
   call :clean_path_all "%SystemRoot%\registration\CRMLog"
   call :clean_path_all "%SystemRoot%\rescache"
   call :clean_path_all "%SystemRoot%\SchCache"
   call :clean_path_all "%SystemRoot%\LanguageOverlayCache"
   call :clean_path_all "%SystemRoot%\PLA\Reports"
   REM call :clean_path_all "%SystemRoot%\Tasks"
   call :clean_path_all "%SystemRoot%\tracing"
   call :clean_path_all "%SystemRoot%\CbsTemp"
   REM Contains minidump files created during system crashes
   REM call :clean_path_all "%SystemRoot%\Minidumps"
   REM Almacena datos de diagnóstico y telemetría que Windows envía a Microsoft.
   call :clean_path_all "%SystemRoot%\DiagTrack"
   REM Carpeta de depuración (debug logs).
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\DBG"
   REM Carpeta temporal usada por el sistema para controladores (drivers)
   call :clean_path_all "%SystemRoot%\System32\DriverStore\Temp"
   REM Guarda registros del servicio WMI (Windows Management Instrumentation)
   call :clean_path_all "%SystemRoot%\System32\wbem\Logs"
   call :clean_path_all "%SystemRoot%\Logs\wbem"
   REM Archivos de diagnóstico de rendimiento (Windows Diagnostic Infrastructure)
   REM %SystemRoot%\System32\WDI
   call :clean_path_all "%SystemRoot%\System32\WDI\LogFiles"
   REM SoftLanding
   call :clean_path_all "%SystemRoot%\System32\Tasks\SoftLanding"

   REM CONJUNTO RECOPILADORES DE DATOS > SYSTEM DIAGNOSTICS / SYSTEM PERFORMANCE
   echo %alert_log% Limpiando archivos del recopilador de rendimiento ..
   call :clean_path_all "%systemdrive%\perflogs\System\Performance"
   call :clean_path_all "%systemdrive%\perflogs\System\Diagnostics"
   call :clean_path_all "%ProgramData%\WindowsPerformanceRecorder"
   
   REM Limpiar cache de iconos / thumbnails
   echo %alert_log% Limpiando cache de iconos y miniaturas ..
   call :clean_file "%LocalAppData%\IconCache.db"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\Explorer"
   REM call :clean_file "%LocalAppData%\Microsoft\Windows\Explorer\thumbcache_*.db"
   REM call :clean_file "%LocalAppData%\Microsoft\Windows\Explorer\iconcache_*.db"

   REM Limpiar informes de errores y eventos del sistema
   echo %alert_log% Deteniendo servicios de informe de errores y eventos ..
   REM SVCS STOP
   for %%s in ( "WerSvc" "Wecsvc" "EventLog" ) do ( sc stop %%s >nul 2>&1 & timeout /t 2 /nobreak >nul 2>&1 )

   REM Informes de errores de Windows
   echo %alert_log% Limpiando informes de errores de Windows ..
   REM call :clean_path_all "%ProgramData%\Microsoft\Windows\WER"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\WER"
   call :clean_path_all "%ProgramData%\Microsoft\Windows\WER\ReportQueue"
   call :clean_path_all "%ProgramData%\Microsoft\Windows\WER\ReportArchive"
   call :clean_path_all "%ProgramData%\Microsoft\Windows\WER\Temp"

   REM Eventos del sistema
   echo %alert_log% Limpiando eventos del sistema ..
   call :clean_path_all "%ProgramData%\Microsoft\Event Viewer"
   call :clean_path_all "%SystemRoot%\System32\winevt\logs"
   REM "%SystemRoot%\System32\winevt"
   for %%w in ( "Application" "Security" "System" "Setup" "ForwardedEvents" ) do ( wevtutil cl %%w >nul 2>&1 )

   REM SVCS START
   for %%s in ( "WerSvc" "Wecsvc" "EventLog" ) do ( sc start %%s >nul 2>&1 )
   
   REM Cache ubicacion geografica en Windows (GPS, Wi-Fi, red).
   echo %alert_log% Deteniendo servicio de geolocalizacion y mapas ..
   REM SVC STOP
   for %%s in ( "LfSvc" "MapsBroker" ) do ( sc stop %%s >nul 2>&1 & timeout /t 2 /nobreak >nul 2>&1 )
   
   echo %alert_log% Limpiando cache ubicacion geografica ..
   call :clean_path_all "%ProgramData%\Microsoft\Windows\LfSvc\Cache"
   REM Almacena datos de mapas de Windows (usado por apps de mapas y servicios de localización)
   echo %alert_log% Limpiando datos de mapas ..
   call :clean_path_all "%ProgramData%\Microsoft\MapData"
   REM SVC START
   for %%s in ( "LfSvc" "MapsBroker" ) do ( sc start %%s >nul 2>&1 )

   REM WIDGETS - TOKENBROKER CACHE - IE - MEDIA PLAYER - PEN WORKSPACE
   echo %alert_log% Limpiando cache widgets, ie, media player y pen workspace ..
   call :clean_path_all "%LocalAppData%\Microsoft\Feeds"
   call :clean_path_all "%LocalAppData%\Microsoft\TokenBroker\Cache"
   call :clean_path_all "%LocalAppData%\Microsoft\Internet Explorer\CacheStorage"
   call :clean_path_all "%LocalAppData%\Microsoft\Media Player\Transcoded Files Cache"
   call :clean_path_all "%LocalAppData%\Microsoft\PenWorkspace"

   REM Contiene archivos de voz y reconocimiento de habla de Windows.
   echo %alert_log% Limpiando datos de voz y reconocimiento de habla ..
   call :clean_path_all "%ProgramData%\Microsoft\Speech_OneCore"

   REM Recopilan registros de diagnostico para ayudar a detectar problemas del sistema.
   echo %alert_log% Limpiando registros de diagnostico ..
   call :clean_path_all "%ProgramData%\Microsoft\Diagnosis"
   call :clean_path_all "%ProgramData%\Microsoft\DiagnosticLogCSP"

   REM Recopilan registros de diagnostico de eficiencia energetica
   echo %alert_log% Limpiando diagnosticos de eficiencia energetica ..
   call :clean_path_all "%ProgramData%\Microsoft\Windows\Power Efficiency Diagnostics"

   REM DATOS DE SINCRONIZACION DE DISPOSITIVOS
   call :clean_path_all "%ProgramData%\Microsoft\DeviceSync"
   
   REM Datos de sincronización entre dispositivos (teléfono-PC, Bluetooth, notificaciones cruzadas).
   REM C:\Users\User\AppData\Local\ConnectedDevicesPlatform\L.User -> directorio especifico con nombre del usuario
   echo %alert_log% Limpiando cache de sincronizacion entre dispositivos ..
   call :clean_path_all "%LocalAppData%\ConnectedDevicesPlatform\L.%USERNAME%"

   REM Cache generados por aplicaciones que usan ubicacion en comun setup "%LocalAppData%\setup\cache"
   echo %alert_log% Limpiando cache generados por aplicaciones que usan ubicacion en comun ..
   call :clean_path_all "%LocalAppData%\setup\cache"

   REM Datos del Chromium Embedded Framework (navegador interno usado por apps como Spotify, Discord, Steam). Contiene cache, historial y cookies.
   REM echo %alert_log% Limpiando cache CEF ..
   REM call :clean_path_all "%LocalAppData%\CEF\User Data"
   
   REM TEMPORALES DE AI FABRIC
   REM Activa procesos como WorkloadsSessionHost, que gestionan cargas de trabajo de IA en Windows (ej. Recall, búsqueda semántica, Copilot).
   REM Se integra con el sistema de paquetes UWP/AppX
   echo %alert_log% Limpiando temporales de AIFabric ..
   sc stop "WSAIFabricSvc" >nul 2>&1
   timeout /t 2 /nobreak >nul 2>&1
   call :clean_path_all "%ProgramData%\Microsoft\Windows\WSAIFabric\Temp"
   sc start "WSAIFabricSvc" >nul 2>&1

   REM Bases de datos internas de Windows para Correo y Calendario y apps de comunicacion.
   REM echo %alert_log% Limpiando datos de Correo y Calendario ..
   REM call :clean_path_all "%LocalAppData%\Comms\UnistoreDB"
   REM call :clean_path_all "%LocalAppData%\Comms\Unistore\data"

   REM Relacionado con BranchCache/Peer Distribution (tecnología de Windows para compartir datos en red).
   REM echo %alert_log% Limpiando BranchCache ..
   REM call :clean_path_all "%LocalAppData%\PeerDistRepub"
   
   REM Limpiar carpeta usada para recuperacion
   REM echo %alert_log% Limpiando carpeta recovery ..
   REM call :clean_folder "%SystemDrive%\Recovery"

   REM PUBLIC ACCESS
   REM echo %alert_log% Limpiando carpetas de acceso publico ..
   REM call :clean_path_all "%SystemDrive%\Users\Public"

   REM DEFAULT USER FOLDER (generalmente no usada)
   REM echo %alert_log% Limpiando carpeta de usuario default ..
   REM call :clean_path_all "%SystemDrive%\Users\Default"
   
   REM Telemetria del sistema de compatibilidad de aplicaciones de Windows.
   REM SVCS STOP
   for %%s in ( "DiagTrak" "PcaSvc" ) do ( sc stop %%s >nul 2>&1 & timeout /t 2 /nobreak >nul 2>&1 )
   echo %alert_log% Limpiando telemetria de compatibilidad de aplicaciones de Windows ..
   call :clean_path_all "%SystemRoot%\appcompat\appraiser\Telemetry"
   REM call :clean_path_all "%SystemRoot%\appcompat\Backup"
   for %%s in ( "DiagTrak" "PcaSvc" ) do ( sc start %%s >nul 2>&1 )

   REM Guardan archivos temporales durante la instalación o desinstalación de ensamblados .NET.
   echo %alert_log% Limpiando temporales .net ..
   call :clean_path_all "%SystemRoot%\assembly\temp"
   call :clean_path_all "%SystemRoot%\assembly\tmp"

   REM Limpiar archivos muicache nombres de programas
   echo %alert_log% Limpiando archivos MuiCache ..
   call :reg_del_log "HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
  
   REM Limpiar archivos Windows Defender
   echo %alert_log% Limpiando datos generados por Windows Defender ..
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender\Scans\History\Service"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender\Scans\History\Results"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender\Scans\Software Monitoring"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender\Scans\SpynetVista"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender\Support"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender\Network Inspection System"
   REM call :clean_path_all "%ProgramData%\Microsoft\Windows Defender\Quarantine"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender\Definition Updates\Backup"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender\Definition Updates\NisBackup"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender Advanced Threat Protection\Temp"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender Advanced Threat Protection\Cache"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender Advanced Threat Protection\Trace"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender Advanced Threat Protection\ImageCache"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Defender Advanced Threat Protection\DataCollection"
   call :clean_path_all "%ProgramData%\Microsoft\Windows Security Health\Logs"

   REM Limpiar Windows Update
   echo %alert_log% Deteniendo servicios de Win Update ..
   REM SVCS STOP
   for %%s in ( "wuauserv" "UsoSvc" "wscsvc" ) do ( sc stop %%s >nul 2>&1 & timeout /t 2 /nobreak >nul 2>&1 )

   REM Detener tareas programadas relacionadas con Win Update
   echo %alert_log% Deteniendo tareas de Win Update ..
   powershell -NoProfile -Command "Get-ScheduledTask -TaskPath 'Microsoft\Windows\WindowsUpdate' -ErrorAction SilentlyContinue | Stop-ScheduledTask -ErrorAction SilentlyContinue" >nul 2>&1
   powershell -NoProfile -Command "Get-ScheduledTask -TaskPath 'Microsoft\Windows\UpdateOrchestrator' -ErrorAction SilentlyContinue | Stop-ScheduledTask -ErrorAction SilentlyContinue" >nul 2>&1

   echo %alert_log% Limpiando Windows Update ..
   call :clean_path_all "%SystemRoot%\SoftwareDistribution"
   call :clean_path_all "%ProgramData%\SoftwareDistribution"
   call :clean_path_all "%LocalAppData%\Microsoft\Windows\DeliveryOptimization"
   call :clean_path_all "%ProgramData%\Microsoft\Windows\DeliveryOptimization"
   REM call :clean_path_all "%SystemRoot%\System32\CatRoot"
   REM call :clean_path_all "%SystemRoot%\SysWOW64\catroot"
   call :clean_path_all "%SystemRoot%\System32\catroot2"
   call :clean_path_all "%SystemRoot%\SysWOW64\catroot2"

   REM Supervisa el dispositivo para obtener una mejor experiencia de usuario
   echo %alert_log% Deteniendo servicio Estado y experiencias optimizadas de Windows ..
   sc stop "whesvc" >nul 2>&1
   timeout /t 2 /nobreak >nul 2>&1
   echo %alert_log% Limpiando logs ..
   call :clean_path_all "%ProgramData%\Whesvc"
   sc start "whesvc" >nul 2>&1

   REM USOPrivate / USOShared: relacionadas con el servicio Update Session Orchestrator (USO), que gestiona las actualizaciones de Windows.
   echo %alert_log% Limpiando logs Update Orchestrator ..
   call :clean_path_all "%ProgramData%\USOShared\Logs"
   REM call :clean_path_all "%ProgramData%\USOPrivate"
   REM SVCS START
   for %%s in ( "wuauserv" "UsoSvc" "wscsvc" ) do ( sc start %%s >nul 2>&1 )

   REM Limpiar Package Cache
   echo %alert_log% Limpiando cache aplicaciones Microsoft ..
   call :clean_path_all "%ProgramData%\Package Cache"
   REM call :clean_path_all "%LocalAppData%\Packages"
   REM Temporales genéricos de apps UWP/MSIX
   echo %alert_log% Limpiando temporales de apps UWP ..
   REM for /d %%u in ("%LocalAppData%\Packages\*") do (
   call :clean_path_all "%LocalAppData%\Packages\AC\Temp"
   call :clean_path_all "%LocalAppData%\Packages\ActiveSync\LocalState\Temp"
   call :clean_path_all "%LocalAppData%\Packages\LocalState\Temp"
   call :clean_path_all "%LocalAppData%\Packages\LocalCache"

   REM Caché de Direct3D Shader
   echo %alert_log% Limpiando cache Direct3D ..
   call :clean_path_all "%LocalAppData%\D3DSCache"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\D3DSCache"
   REM call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\D3DSCache"
   
   REM Limpiar carpeta Windows.old
   echo %alert_log% Limpiando Windows.old ..
   call :clean_path_all "%SystemDrive%\Windows.old"
   call :clean_folder "%SystemDrive%\Windows.old"

   REM LOCALOW
   echo %alert_log% Limpiando cache y temporales en localow ..
   call :clean_path_all "%UserProfile%\AppData\LocalLow\Microsoft\Internet Explorer\IEFlipAheadCache"
   call :clean_path_all "%UserProfile%\AppData\LocalLow\Microsoft\CryptnetUrlCache"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\LocalLow\Microsoft\CryptnetUrlCache"
   REM call :clean_path_all "%UserProfile%\AppData\LocalLow\Microsoft\IME"
   call :clean_path_all "%UserProfile%\AppData\LocalLow\Temp"

   REM Limpiar cache Epic
   REM Matar procesos steam y epic antes de proceder con la limpieza
   echo %alert_log% Finalizando launchers de Epic y Steam ..
   for %%t in ( "steam.exe" "steamservice.exe" "steamwebhelper.exe" "EpicGamesLauncher.exe" "EpicWebHelper.exe" ) do ( taskkill /F /IM %%t >nul 2>&1 & timeout /t 2 /nobreak >nul 2>&1 )

   echo %alert_log% Limpiando temp, logs, reports y shader cache Epic Games ..
   call :clean_path_all "%ProgramFiles(x86)%\Epic Games\Epic Online Services\Engine\Shaders"
   call :clean_path_all "%ProgramFiles(x86)%\Epic Games\Epic Online Services\Engine\Programs\CrashReportClient"
   call :clean_path_all "%LocalAppData%\EpicGamesLauncher\Saved\Config\CrashReportClient"
   call :clean_path_all "%LocalAppData%\EpicGamesLauncher\Saved\Logs"
   call :clean_path_all "%LocalAppData%\EpicGamesLauncher\Saved\webcache"
   REM call :clean_path_suffix "%LocalAppData%\EpicGamesLauncher\Saved\webcache_*"
   call :clean_path_all "%LocalAppData%\Epic Games\Epic Online Services\MainService\Logs"
   call :clean_path_all "%LocalAppData%\Epic Games\Epic Online Services\InstallHelper\Logs"
   call :clean_path_all "%LocalAppData%\Epic Games\Epic Online Services\EpicOnlineServicesHost\Logs"
   call :clean_path_all "%LocalAppData%\Epic Games\Epic Online Services\Bootstrapper\Logs"
   call :clean_path_all "%LocalAppData%\Epic Games\EOSOverlay\BrowserCache"
   REM call :clean_path_all "%AppData%\EasyAntiCheat"
   call :clean_path_all "%ProgramData%\Epic\EpicGamesLauncher\Logs"
   REM call :clean_path_all "%ProgramData%\Epic\EpicGamesLauncher\VaultCache"
   call :clean_path_all "%ProgramData%\Epic\EpicGamesLauncher\Data\ManifestTemp"

   REM Limpiar cache Steam
   echo %alert_log% Limpiando shader cache y temps Steam ..
   call :clean_path_all "%ProgramFiles(x86)%\Steam\appcache\httpcache"
   call :clean_path_all "%ProgramFiles(x86)%\Steam\appcache\librarycache"
   call :clean_path_all "%ProgramFiles(x86)%\Steam\config\avatarcache"
   call :clean_path_all "%ProgramFiles(x86)%\Steam\depotcache"
   call :clean_path_all "%ProgramFiles(x86)%\Steam\dumps"
   call :clean_path_all "%ProgramFiles(x86)%\Steam\logs"
   REM Los archivos de la nube se guardan localmente aca, contiene ids y juegos asociados a esas cuentas de Steam (NO BORRAR PERDERA SINCRONIZACION)
   REM call :clean_path_all "%ProgramFiles(x86)%\Steam\userdata"
   call :clean_path_all "%ProgramFiles(x86)%\Steam\steamapps\shadercache"
   call :clean_path_all "%ProgramFiles(x86)%\Steam\steamapps\temp"
   call :clean_path_all "%LocalAppData%\Steam\htmlcache"

   REM Limpiar cache NVIDIA AMD INTEL
   REM NVIDIA
   echo %alert_log% Limpiando cache NVIDIA, AMD y INTEL ..
   REM Caché de DirectX usada por drivers NVIDIA
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\NVIDIA\DXCache"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\LocalLow\NVIDIA\DXCache"
   call :clean_path_all "%LocalAppData%\NVIDIA\DXCache"
   call :clean_path_all "%LocalAppData%\NVIDIA\GLCache"
   call :clean_path_all "%LocalAppData%\NVIDIA\NvBackend\Logs"
   REM call :clean_path_all "%LocalAppData%\NVIDIA"
   REM call :clean_path_all "%ProgramData%\NVIDIA"
   REM call :clean_path_all "%LocalAppData%\NVIDIA Corporation"
   call :clean_path_all "%AppData%\NVIDIA\ComputeCache"
   call :clean_path_all "%UserProfile%\AppData\LocalLow\NVIDIA\DXCache"
   call :clean_path_all "%LocalAppData%\NVIDIA Corporation\NV_Cache"
   call :clean_path_all "%ProgramData%\NVIDIA Corporation\NV_Cache"
   call :clean_path_all "%ProgramData%\NVIDIA Corporation\DisplayDriverRAS\NvTelemetry"
   call :clean_path_all "%ProgramData%\NVIDIA Corporation\GameSessionTelemetry"
   call :clean_path_all "%ProgramData%\NVIDIA Corporation\umdlogs"
   call :clean_path_all "%ProgramFiles%\NVIDIA Corporation\NV_Cache"
   call :clean_path_all "%ProgramFiles(x86)%\NVIDIA Corporation\NV_Cache"
   call :clean_path_all "%ProgramFiles%\NVIDIA Corporation\UMDLogs"
   
   REM AMD (Contains logs related to AMD graphics driver issues)
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\AMD\CN"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\LocalLow\AMD\CN"
   call :clean_path_all "%LocalAppData%\AMD\CN"
   call :clean_path_all "%ProgramData%\AMD\Adrenalin\Logs"
   call :clean_path_all "%ProgramData%\AMD\Drivers\Logs"
   call :clean_path_all "%LocalAppData%\AMD\Adrenalin\Logs"
   REM call :clean_path_all "%LocalAppData%\AMD"
   REM call :clean_path_all "%ProgramData%\AMD"
   REM call :clean_path_all "%AppData%\AMD"
   
   REM INTEL
   REM archivos de registro para registros de control de Intel® Arc (https://www.intel.com/content/www/us/en/support/articles/000095081/graphics.html)
   call :clean_path_all "%LocalAppData%\Intel\IGN\logs"
   REM archivos de registro para el Intel® Graphics Command Center (https://www.intel.com/content/www/us/en/support/articles/000056345/graphics.html) 
   call :clean_path_all "%LocalAppData%\Packages\AppUp.IntelGraphicsExperience_8j3eq9eme6ctt\LocalState\Intel\GCC"
   REM Log Files for Intel® Graphics Driver Installer (https://www.intel.com/content/www/us/en/support/articles/000091369/graphics.html)
   call :clean_path_all "%ProgramData%\Intel\GFXInstaller"
   call :clean_path_all "%ProgramData%\Intel\GFXTelemetry"
   call :clean_path_all "%ProgramData%\Intel\Logs"
   call :clean_path_all "%ProgramData%\Intel\iGPU\Logs"
   call :clean_path_all "%LocalAppData%\Intel\IntelGraphicsExperience\Logs"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\Intel\Logs"
   call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\LocalLow\Intel\Logs"

   REM Limpiar cache Discord
   echo %alert_log% Finalizando Discord ..
   taskkill /F /IM Discord.exe >nul 2>&1
   timeout /t 2 /nobreak >nul 2>&1
   echo %alert_log% Limpiando temporales Discord ..
   REM LOCAL APP DATA
   call :clean_path_all "%LocalAppData%\Discord\packages\SquirrelTemp"
   call :clean_path_all "%LocalAppData%\SquirrelTemp"
   REM ROAMING
   call :clean_path_all "%AppData%\discord\logs"
   REM call :clean_path_all "%AppData%\discord\Local Storage"
   call :clean_path_all "%AppData%\discord\GPUCache"
   call :clean_path_all "%AppData%\discord\Crashpad"
   call :clean_path_all "%AppData%\discord\DawnGraphiteCache"
   call :clean_path_all "%AppData%\discord\DawnWebGPUCache"
   call :clean_path_all "%AppData%\discord\Code Cache"
   call :clean_path_all "%AppData%\discord\Cache"
   call :clean_path_all "%AppData%\discord\blob_storage"
   call :clean_path_all "%AppData%\discord\module_data\crashlogs"
   call :clean_path_all "%AppData%\discord\Service Worker\CacheStorage"
   REM call :clean_path_all "%AppData%\discord\Session Storage"
   call :clean_path_all "%AppData%\discord\Shared Dictionary\cache"
   REM call :clean_path_all "%AppData%\discord\shared_proto_db"

   echo %alert_log% Iniciando explorador ..
   start "" explorer.exe >nul 2>&1
   
   echo %alert_log% Ejecutando limpiador de Windows ..
   start "" "%WinDir%\System32\cleanmgr.exe" /sagerun:64 >nul 2>&1
   if errorlevel 1 (
      echo %alert_error% No se pudo ejecutar cleanmgr.exe.
   )
   
   echo %alert_log% Ejecutando sensor de almacenamiento (StorageSense) ..
   powershell -NoProfile -Command "try{Start-StorageSense -Cleanup; exit 0}catch{exit 1}" >nul 2>&1
   if errorlevel 1 (
      echo %alert_error% No se pudo ejecutar StorageSense.
   )

   REM BLOQUE DOWNLOADS
   choice /c YN /n /m "%alert_question% Desea vaciar Descargas/Download? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      call :clean_path_all "%UserProfile%\Downloads"
   )

   REM BLOQUE DOCUMENTS
   choice /c YN /n /m "%alert_question% Desea vaciar Documentos/Documents? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      call :clean_path_all "%UserProfile%\Documents"
   )

   REM BLOQUE IMAGENES
   choice /c YN /n /m "%alert_question% Desea vaciar Imagenes/Images? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      call :clean_path_all "%UserProfile%\Pictures"
   )

   REM BLOQUE VIDEOS
   choice /c YN /n /m "%alert_question% Desea vaciar Videos? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      call :clean_path_all "%UserProfile%\Videos"
   ) 

   REM BLOQUE MUSICA
   choice /c YN /n /m "%alert_question% Desea vaciar Musica/Music? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      call :clean_path_all "%UserProfile%\Music"
   )

   REM BLOQUE CARPETAS DE USUARIO
   echo %alert_info% Estas carpetas no suelen ocuparse y son: Busquedas, Favoritos, Contactos, Objetos3d.. etc.
   choice /c YN /n /m "%alert_question% Desea vaciar las demas carpetas del usuario? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      REM Limpiar la carpeta de descargas, busquedas, favoritos, etc
      REM echo %alert_log% Limpiando carpetas de usuario como busquedas, favoritos, objetos 3d, etc ..
      set subfolders="Favorites" "Searches" "Contacts" "Links" "3D Objects" "Saved Games"
      for %%u in ( %subfolders% ) do ( call :clean_path_all "%UserProfile%\%%~u" )
   )

   REM BLOQUE INDEXER
   echo %alert_warning% Reconstruir el indexador significa que debera cargarse nuevamente
   echo lo cual puede generar una carga en el procesador, siga con precaucion.
   choice /c YN /n /m "%alert_question% Desea reconstruir el indexador "Busqueda/Searches"? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      sc stop "WSearch" >nul 2>&1
      timeout /t 2 /nobreak >nul 2>&1
      call :clean_file "%ProgramData%\Microsoft\Search\Data\Applications\Windows\Windows.edb"
      call :clean_folder "%ProgramData%\Microsoft\Search\Data"
      call :clean_folder "%UserProfile%\Searches"
      sc start "WSearch" >nul 2>&1
   )

   REM BLOQUE CREDENCIALES
   echo %alert_warning% Eliminar las credenciales significa que todas las sesiones del sistema se borraran, siga con precaucion.
   choice /c YN /n /m "%alert_question% Desea eliminar las credenciales de usuario? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      REM CREDENCIALES (Almacén seguro de credenciales - Archivos de credenciales cifradas)
      echo %alert_log% Deteniendo servicios y limpiando datos de credenciales ..
      for %%s in ( "VaultSvc" "SamSs" "UserManager" "LSM" ) do ( sc stop %%s >nul 2>&1 & timeout /t 2 /nobreak >nul 2>&1 )

      call :clean_path_all "%LocalAppData%\Microsoft\Credentials"
      call :clean_path_all "%ProgramData%\Microsoft\Credentials"
      call :clean_path_all "%AppData%\Microsoft\Credentials"
      call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Credentials"
      call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Roaming\Microsoft\Credentials"

      call :clean_path_all "%LocalAppData%\Microsoft\Vault"
      call :clean_path_all "%ProgramData%\Microsoft\Vault"
      call :clean_path_all "%AppData%\Microsoft\Vault"
      call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Vault"
      call :clean_path_all "%SystemRoot%\System32\config\systemprofile\AppData\Roaming\Microsoft\Vault"

      for %%s in ( "VaultSvc" "SamSs" "UserManager" "LSM" ) do ( sc start %%s >nul 2>&1 )
   )

   REM BLOQUE ONEDRIVE
   echo %alert_warning% Se eliminaran datos de sincronizacion OneDrive y se restablecera.
   choice /c YN /n /m "%alert_question% Desea seguir con esta accion? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (

      REM Limpiar archivos actividad onedrive
      echo %alert_log% Finalizando el proceso principal y servicio de sincronizacion ..
      taskkill /F /IM OneDrive.exe >nul 2>&1
      sc stop "CldFlt" >nul 2>&1
      timeout /t 2 /nobreak >nul 2>&1

      REM Detener tareas programadas relacionadas con OneDrive
      echo %alert_log% Deteniendo tareas relacionadas ..
      powershell -NoProfile -Command "Get-ScheduledTask -TaskPath '\Microsoft\OneDrive\OneDrive Standalone Update Task' -ErrorAction SilentlyContinue | Stop-ScheduledTask -ErrorAction SilentlyContinue" >nul 2>&1
      powershell -NoProfile -Command "Get-ScheduledTask -TaskPath '\Microsoft\OneDrive\OneDrive Reporting Task' -ErrorAction SilentlyContinue | Stop-ScheduledTask -ErrorAction SilentlyContinue" >nul 2>&1
      
      echo %alert_log% Limpiando actividad OneDrive ..
      call :clean_path_all "%WinDir%\System32\LogFiles\CloudFiles"
      call :clean_path_all "%LocalAppData%\Microsoft\OneDrive\logs"
      call :clean_path_all "%LocalAppData%\Microsoft\OneDrive\cache"
      call :clean_path_all "%LocalAppData%\Microsoft\OneDrive\syncEngine"
      call :clean_file "%UserProfile%\OneDrive\*.tmp"
      
      sc start "CldFlt" >nul 2>&1

      REM Detectar y ejecutar OneDrive reset
      if exist "%LocalAppData%\Microsoft\OneDrive\OneDrive.exe" (
        "%LocalAppData%\Microsoft\OneDrive\OneDrive.exe" /reset
      ) else if exist "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe" (
         "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe" /reset
      ) else if exist "%ProgramFiles(x86)%\Microsoft OneDrive\OneDrive.exe" (
         "%ProgramFiles(x86)%\Microsoft OneDrive\OneDrive.exe" /reset
      )
   )

   REM BLOQUE SHADOWCOPY
   echo %alert_warning% A continuacion podra elegir si borrar el mas antiguo o todos los puntos de restauracion.
   choice /c YN /n /m "%alert_question% Desea eliminar puntos de restauracion? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      echo %alert_question% Desea eliminar todos los puntos de restauracion o solo el mas antiguo?
      choice /c 123 /n /m "%alert_question% 1=Antiguo / 2=Todos / 3=Omitir"
      if errorlevel 3 goto recycle_bin
      if errorlevel 2 ( vssadmin delete shadows /for=%SystemDrive% /all /quiet >> "%log_file%" )
      if errorlevel 1 ( vssadmin delete shadows /for=%SystemDrive% /oldest /quiet >> "%log_file%" )
   )

   REM BLOQUE PAPELERA
   :recycle_bin
   choice /c YN /n /m "%alert_question% Desea vaciar la Papelera/Recycle bin? Y/N:"
   if errorlevel 2 (
      echo %alert_log% Se omitio la limpieza.
   ) else (
      powershell -NoProfile -Command "Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue"
      REM call :clean_path_all "%SystemDrive%\$Recycle.Bin"
   )

   echo %alert_log% Puedes revisar logs en el directorio de ejecucion del script.
   echo %alert_log% Algunos archivos/carpetas se crearan automaticamente luego del reinicio.
   echo %alert_success% Limpieza de Win completada, reinicia.
   pause

goto menu_cleaner

REM =============================================
REM FUNCTIONS
REM =============================================
REM GET TIMESTAMP
REM =============================================
:get_ts
   for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd-HH:mm:ss')"`) do set "ts=%%t"
goto :eof
REM =============================================
REM CLEAN FUNCTIONS
REM =============================================
REM Ejemplo de uso:
REM call :clean_path_all "%ProgramData%\Microsoft\Event Viewer"
REM call :clean_file "%SystemDrive%\*.swp"
REM call :clean_folder "%ProgramData%\Microsoft\DiagnosticLogCSP"
REM ============================================= 
REM DELETE FOLDERS AND FILES
REM =============================================
:clean_path_all
   if "%~1"=="" goto :eof
   set "target=%~1"

   if exist "%target%" (
      call :take_control "%target%"
      call :get_ts

      del /s /f /q "%target%\*" >nul 2>&1
      if !errorlevel! neq 0 (
         echo [!ts!]-[Clean-Error] Failed - "%target%" >> "%log_file%"
      ) else (
         echo [!ts!]-[Clean-Ok] Deleting - "%target%" >> "%log_file%"
      )

      for /d %%i in ("%target%\*") do (
         rd /s /q "%%i" >nul 2>&1
         if !errorlevel! neq 0 (
            echo [!ts!]-[Clean-Error] Failed - "%%i" >> "%log_file%"
         ) else (
            echo [!ts!]-[Clean-Ok] Deleting - "%%i" >> "%log_file%"
         )
      )
   ) else ( echo [!ts!]-[Clean-Error] Missing Path - "%target%" >> "%log_file%" )
goto :eof

REM ============================================= 
REM DELETE FOLDERS WITH SUFFIX (funciona pero las rutas inexistentes se muestran en consola, a mejorar)
REM =============================================
:clean_path_suffix
   if "%~1"=="" ( goto :eof )

   REM Recorrer todas las carpetas que coincidan
   for /d %%i in (%~1) do (
      if exist "%%i" (
         call :take_control "%%i"
         call :get_ts

         rd /s /q "%%i" >nul 2>&1
         if !errorlevel! neq 0 (
            echo [!ts!]-[Clean-Error] Failed - "%%i" >> "%log_file%"
         ) else (
            echo [!ts!]-[Clean-Ok] Deleted folder - "%%i" >> "%log_file%"
         )
      ) else ( echo [!ts!]-[Clean-Error] Missing folder - "%%i" >> "%log_file%" )
   )
goto :eof

REM ============================================= 
REM DELETE ONLY FOLDER
REM =============================================
:clean_folder
   if "%~1"=="" ( goto :eof )
   set "folder=%~1"

   if exist "%folder%" (

      call :take_control "%folder%"
      call :get_ts

      rd /s /q "%folder%" >nul 2>&1
      if !errorlevel! neq 0 (
         echo [!ts!]-[Clean-Error] Failed - "%folder%" >> "%log_file%"
      ) else ( echo [!ts!]-[Clean-Ok] Deleting - "%folder%" >> "%log_file%" )

   ) else ( echo [!ts!]-[Clean-Error] Missing Folder - "%folder%" >> "%log_file%" )
goto :eof

REM ============================================= 
REM DELETE BY FILETYPE
REM =============================================
:clean_file
   if "%~1"=="" ( goto :eof )
   set "filetype=%~1"
   if exist "%filetype%" (

      call :take_control "%filetype%"
      call :get_ts

      del /f /q /s "%filetype%" >nul 2>&1
      if !errorlevel! neq 0 (
         echo [!ts!]-[Clean-Error] Failed - "%filetype%" >> "%log_file%"
      ) else ( echo [!ts!]-[Clean-Ok] Deleting - "%filetype%" >> "%log_file%" )
   
   ) else ( echo [!ts!]-[Clean-Error] Missing Filetype - "%filetype%" >> "%log_file%" )
goto :eof

REM =============================================
REM TAKE CONTROL
REM =============================================
:take_control
   if "%~1"=="" ( goto :eof )

   REM Quitar atributos que puedan bloquear
   attrib -h -s -r "%~1" >nul 2>&1
   
   REM Verificar si el usuario actual ya tiene control total (silencioso)
   REM cmd /c "icacls \"%~1\" | findstr /i \"(F)\" | findstr /i \"%USERNAME%\"" >nul 2>&1

   REM Verificar si ya tiene control total (los parentesis encapsulan para evitar output en consola)
   ( icacls "%~1" | findstr /i "(F)" | findstr /i "%USERNAME%" ) >nul 2>&1
   if !errorlevel! equ 1 (
      REM Si no tiene control total, intentar tomar posesion y otorgar permisos   
      takeown /F "%~1" /R /A /D Y >nul 2>&1
      icacls "%~1" /grant Administrators:F /T /C >nul 2>&1
   )
goto :eof

REM =============================================
REM DELETE VALUE/KEY REGLOG
REM Uso para borrar valor: call :reg_del_log "HKEY_CURRENT_USER\Control Panel\Mouse" "MouseSensitivity"
REM Uso para borrar clave: call :reg_del_log "HKEY_CURRENT_USER\Control Panel\Mouse"
REM =============================================
:reg_del_log
   if "%~1"=="" ( goto :eof )
   set "key_path=%~1"
   set "value_name=%~2"
   call :get_ts

   if defined value_name (
      REM borrar valor concreto
      reg delete "!key_path!" /v "!value_name!" /f >nul 2>&1
      if !errorlevel! equ 0 (
         echo [!ts!]-[DeletedValue-Ok] !key_path! - !value_name! >> "%log_file%"
      ) else ( echo [!ts!]-[DeletedValue-Error] Missing !key_path! - !value_name! >> "%log_file%" )
   ) else (
      REM borrar clave completa
      reg delete "!key_path!" /f >nul 2>&1
      if !errorlevel! equ 0 (
         echo [!ts!]-[DeletedKey-Ok] !key_path! >> "%log_file%"
      ) else ( echo [!ts!]-[DeletedKey-Error] Missing !key_path! >> "%log_file%" )
   )
goto :eof

REM =============================================
REM END FUNCTIONS & SCRIPT
REM =============================================

endlocal
exit