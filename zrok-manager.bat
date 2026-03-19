@echo off
chcp 65001 >nul 2>&1
setlocal EnableDelayedExpansion
mode con: cols=70 lines=30
title  ZROK MANAGER

:MENU
cls
color 0B
echo.
echo  +==============================================================+
echo  ^|                                                              ^|
echo  ^|        ______  ______  ______  __  __                      ^|
echo  ^|       /___  / /\  == \/\  __ \/\ \/ /                      ^|
echo  ^|          / /  \ \  __^< \ \ \/\ \ \  _-.                    ^|
echo  ^|         / /    \ \_\ \_\\ \_____\ \_\ \_\                  ^|
echo  ^|        /_/      \/_/ /_/ \/_____/\/_/\/_/                  ^|
echo  ^|                                                              ^|
echo  ^|            M A N A G E R   v 2 . 3                         ^|
echo  ^|           Gestor de zrok para Windows                      ^|
echo  +==============================================================+
echo.

set "V1=No instalado"
if exist "C:\zrok\zrok.exe"  set "V1=v1 Instalado [C:\zrok]"
if exist "C:\zrok\zrok2.exe" set "V1=v2 Instalado [C:\zrok]"

echo  +--------------------------------------------------------------+
echo  ^|  zrok local :  !V1!
echo  +--------------------------------------------------------------+
echo.
echo  +==============================================================+
echo  ^|                   O P C I O N E S                           ^|
echo  +--------------------------------------------------------------+
echo  ^|                                                              ^|
echo  ^|   [1]  INSTALAR    zrok (ultima version)                    ^|
echo  ^|   [2]  ACTUALIZAR  zrok a la ultima version                 ^|
echo  ^|   [0]  OFFLINE     instalar desde archivo local             ^|
echo  ^|   [3]  DESINSTALAR zrok                                     ^|
echo  ^|   [4]  COMPROBAR   estado del servicio                      ^|
echo  ^|   [P]  VERIFICAR   PATH (el "patch" de sistema)             ^|
echo  ^|   [R]  REPARAR     PATH (forzar variable de entorno)        ^|
echo  ^|   [C]  ABRIR       CMD (Consola de comandos)                ^|
echo  ^|   [5]  SALIR                                                ^|
echo  ^|                                                              ^|
echo  +==============================================================+
echo.

set "OPT="
set /p "OPT=     Selecciona una opcion:  "

 if "!OPT!"=="1" goto DO_ACTION
 if "!OPT!"=="2" goto DO_ACTION
 if /i "!OPT!"=="O" goto DO_ACTION
 if "!OPT!"=="0" goto DO_ACTION
 if "!OPT!"=="3" goto DO_ACTION
 if "!OPT!"=="4" goto DO_ACTION
 if /i "!OPT!"=="P" goto DO_ACTION
 if /i "!OPT!"=="R" goto DO_ACTION
 if /i "!OPT!"=="5" goto EXIT_NOW
 if /i "!OPT!"=="C" goto OPEN_CMD
 if /i "!OPT!"=="cmd" goto OPEN_CMD
 
 echo.
 echo  [!] Opcion invalida. Elige entre las opciones del menu.

timeout /t 2 >nul
goto MENU

:OPEN_CMD
echo.
echo  [>] Abriendo consola CMD...
start cmd
goto MENU

:DO_ACTION
set "PS1_PATH=%~dp0zrok-worker.ps1"
if not exist "!PS1_PATH!" (
    echo.
    echo  [ERROR] No se encontro zrok-worker.ps1
    echo  Coloca ambos archivos en la misma carpeta.
    pause
    goto MENU
)
cls
color 0B
echo.
echo  +==============================================================+
echo  ^|  Ejecutando opcion !OPT! ...                                ^|
echo  +==============================================================+
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!PS1_PATH!" -Action !OPT!
echo.
echo  +--------------------------------------------------------------+
echo  ^|  Presiona cualquier tecla para volver al menu...            ^|
echo  +--------------------------------------------------------------+
pause >nul
goto MENU

:EXIT_NOW
cls
color 0B
echo.
echo  +==============================================================+
echo  ^|                    Hasta luego!                             ^|
echo  +==============================================================+
echo.
timeout /t 2 >nul
exit