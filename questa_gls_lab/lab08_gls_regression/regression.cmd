@echo off
rem ==========================================================================
rem  LAB 08 : regression of every GLS lab  --  run them all and summarise
rem  Exit code : 0 = all green, 1 = at least one lab failed
rem
rem  IMPORTANT RULES for .cmd files on Windows (all verified here) :
rem    * Keep every .cmd file pure ASCII. Thai/UTF-8 text inside a .cmd
rem      makes cmd.exe mis-read the line structure (a comment line can
rem      eat the first character of the next line: "echo" -> "cho").
rem    * Never leave an unescaped "(" or ")" inside an echo line that
rem      sits inside an if-block -- cmd.exe aborts the script silently.
rem    * In "for %%V in (...)" the "=" character is parsed as the
rem      var=value separator, so do not use it as a data delimiter.
rem    * Every lab picks its own simulator with tools\pick_tool.cmd, so
rem      this script does NOT set a PATH of its own.
rem ==========================================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "ROOT=%CD%\.."
set "LOGDIR=%CD%\results"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

set "SUMMARY=%LOGDIR%\regression_summary.txt"
if exist "%SUMMARY%" del "%SUMMARY%"

echo =====================================================================
echo  LAB 08 : GLS regression -- running every gate level lab
echo  root    : %ROOT%
echo =====================================================================

set TOTAL=0
set PASSED=0
set FAILED=0

rem ---------------------------------------------------------------------
rem  run one lab at a time, keep a separate log, collect the result
rem ---------------------------------------------------------------------
for %%L in (lab01_rtl_baseline lab02_synth_netlist lab03_cell_library lab04_gls_first lab05_rtl_vs_gate lab06_x_propagation lab07_netlist_bug) do (
    if exist "%ROOT%\%%L\run.cmd" (
        set /a TOTAL+=1
        call "%ROOT%\%%L\run.cmd" > "%LOGDIR%\%%L.log" 2>&1
        set "RC=!ERRORLEVEL!"
        cd /d "%~dp0"
        if "!RC!"=="0" (
            set /a PASSED+=1
            echo [PASS] %%L
            echo PASS  %%L  >> "%SUMMARY%"
        ) else (
            set /a FAILED+=1
            echo [FAIL] %%L  exit=!RC!
            echo FAIL  %%L  exit=!RC!  >> "%SUMMARY%"
        )
    ) else (
        echo [SKIP] %%L -- script not found
        echo SKIP  %%L  >> "%SUMMARY%"
    )
)

rem ---------------------------------------------------------------------
rem  the multi design comparison of this lab
rem ---------------------------------------------------------------------
if exist "%ROOT%\lab08_gls_regression\run.cmd" (
    set /a TOTAL+=1
    call "%ROOT%\lab08_gls_regression\run.cmd" > "%LOGDIR%\lab08_multi_design.log" 2>&1
    set "RC=!ERRORLEVEL!"
    cd /d "%~dp0"
    if "!RC!"=="0" (
        set /a PASSED+=1
        echo [PASS] lab08_multi_design
        echo PASS  lab08_multi_design  >> "%SUMMARY%"
    ) else (
        set /a FAILED+=1
        echo [FAIL] lab08_multi_design  exit=!RC!
        echo FAIL  lab08_multi_design  exit=!RC!  >> "%SUMMARY%"
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
