@echo off
rem ==========================================================================
rem  tools\pick_tool.cmd
rem    Chooses a ModelSim / QuestaSim installation whose licence is free.
rem
rem    Sets the variable MT to the folder that holds vsim.exe.
rem    Leaves MT undefined when no installation can check out a licence.
rem
rem    WHY THIS FILE EXISTS
rem      The licence of this machine is a single-session node-locked licence.
rem      When a QuestaSim GUI is open it owns the seat and every command line
rem      session of that product is refused with
rem          "License checkout has been disallowed because ..."
rem      A licence is only checked out when a design is really loaded, so the
rem      probe compiles a tiny design and loads it.
rem
rem    USAGE
rem      call "%~dp0..\tools\pick_tool.cmd"
rem      if not defined MT ( echo [ERROR] no licence & exit /b 2 )
rem      set "PATH=%MT%;%PATH%"
rem ==========================================================================
set "PROBEDIR=%TEMP%\questa_lic_probe"
if not exist "%PROBEDIR%" mkdir "%PROBEDIR%"
set "PROBEFS=%PROBEDIR:\=/%"
if not exist "%PROBEDIR%\probe_top.vhd" (
    if exist "%~dp0probe\probe_top.vhd" (
        copy /Y "%~dp0probe\probe_top.vhd" "%PROBEDIR%\probe_top.vhd" >nul
    )
)

set "MT="
call :try_tool "%QUESTASIM_HOME%\win64"
if not defined MT call :try_tool "%MODELSIM_HOME%\win64pe"
if not defined MT call :try_tool "C:\Siemens\questasim64_2026.1\win64"
if not defined MT call :try_tool "C:\Siemens\modelsim_dlx64_2026.1\win64pe"
goto :eof

rem ---------------------------------------------------------------------
rem  :try_tool  --  use this installation only if it can check out a licence
rem ---------------------------------------------------------------------
:try_tool
if exist "%~1\vsim.exe" (
    "%~1\vlib.exe" "%PROBEDIR%\w" >nul 2>&1
    "%~1\vcom.exe" -2008 -work "%PROBEDIR%\w" "%PROBEDIR%\probe_top.vhd" >nul 2>&1
    "%~1\vsim.exe" -c -do "vsim %PROBEFS%/w.probe_top; quit -f" > "%PROBEDIR%\out.txt" 2>&1
    findstr /C:"License checkout has been disallowed" "%PROBEDIR%\out.txt" >nul
    if errorlevel 1 set "MT=%~1"
)
goto :eof
