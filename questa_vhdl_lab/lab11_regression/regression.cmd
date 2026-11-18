@echo off
rem ==========================================================================
rem  LAB 11 : regression automation  --  run every lab and summarise
rem  Exit code : 0 = all green, 1 = at least one lab failed
rem
rem  Every lab picks its own simulator with tools\pick_tool.cmd, so this
rem  script does NOT set a PATH of its own.
rem
rem  IMPORTANT RULES for .cmd files on Windows (all verified here) :
rem    * Keep every .cmd file pure ASCII. Thai/UTF-8 text inside a .cmd
rem      makes cmd.exe mis-read the line structure (a comment line can
rem      eat the first character of the next line: "echo" -> "cho").
rem    * Never leave an unescaped "(" or ")" inside an echo line that
rem      sits inside an if-block -- cmd.exe aborts the script silently.
rem    * In "for %%V in (...)" the "=" character is parsed as the
rem      var=value separator, so do not use it as a data delimiter.
rem    * lab05 uses run_debug.cmd because lab05\run.cmd is the
rem      negative test (the DUT really has a bug) and must stay red.
rem ==========================================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "ROOT=%CD%\.."
set "LOGDIR=%CD%\results"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

set "SUMMARY=%LOGDIR%\regression_summary.txt"
if exist "%SUMMARY%" del "%SUMMARY%"

echo =====================================================================
echo  LAB 11 : regression -- running every lab
echo  root    : %ROOT%
echo =====================================================================

set TOTAL=0
set PASSED=0
set FAILED=0

rem ---------------------------------------------------------------------
rem  run one lab at a time, keep a separate log, collect the result
rem ---------------------------------------------------------------------
for %%L in (lab01_first_simulation lab02_libraries lab03_selfchecking_tb lab04_waveform lab05_debugging lab06_dataflow lab07_memory lab08_stimulus lab09_psl lab10_coverage) do (
    set "LABSCRIPT=run.cmd"
    if /i "%%L"=="lab05_debugging" set "LABSCRIPT=run_debug.cmd"

    if exist "%ROOT%\%%L\!LABSCRIPT!" (
        set /a TOTAL+=1
        call "%ROOT%\%%L\!LABSCRIPT!" > "%LOGDIR%\%%L.log" 2>&1
        set "RC=!ERRORLEVEL!"
        cd /d "%~dp0"
        if "!RC!"=="0" (
            set /a PASSED+=1
            echo [PASS] %%L
            echo PASS  %%L  script=!LABSCRIPT!  >> "%SUMMARY%"
        ) else (
            set /a FAILED+=1
            echo [FAIL] %%L  exit=!RC!
            echo FAIL  %%L  script=!LABSCRIPT!  exit=!RC!  >> "%SUMMARY%"
        )
    ) else (
        echo [SKIP] %%L -- script not found
        echo SKIP  %%L  script=!LABSCRIPT!  >> "%SUMMARY%"
    )
)

rem ---------------------------------------------------------------------
rem  summary
rem ---------------------------------------------------------------------
echo.
echo =====================================================================
echo  REGRESSION SUMMARY
echo  total = !TOTAL!   passed = !PASSED!   failed = !FAILED!
echo  summary file : %SUMMARY%
echo =====================================================================
type "%SUMMARY%"

if "!FAILED!"=="0" (
    echo [REGRESSION] ALL GREEN
    exit /b 0
)
echo [REGRESSION] FAILED -- !FAILED! lab(s) did not pass
exit /b 1
