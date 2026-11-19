@echo off
rem ==========================================================================
rem  Regression for the TDI labs.
rem
rem  Runs every lab in order and prints a summary.
rem
rem  Exit code : 0 = every lab PASS, 1 = at least one lab FAIL
rem
rem  RULES for .cmd files on Windows:
rem    * Keep the file pure ASCII.
rem    * Do not put "(" or ")" in an echo line that sits inside an if-block.
rem    * "echo > file" writes the text "ECHO is off." -- use "type nul >".
rem    * A lab runner changes the current directory, so the path of the next
rem      lab has to be absolute or the directory has to be restored.
rem ==========================================================================
setlocal

set "ROOT=%~dp0.."
set "REPORT=%~dp0results\regression.txt"

if not exist "%~dp0results" mkdir "%~dp0results"

set LABS=lab01_rtl_ports lab02_def_boundary lab03_tech_libs lab04_timing lab05_scan lab06_settings
set PASSED=0
set FAILED=0

type nul > "%REPORT%"
echo ===================================================================== >> "%REPORT%"
echo  TDI lab regression >> "%REPORT%"
echo  %DATE% %TIME% >> "%REPORT%"
echo ===================================================================== >> "%REPORT%"

for %%L in (%LABS%) do (
    echo.
    echo ---------------------------------------------------------------------
    echo  running %%L
    echo ---------------------------------------------------------------------
    call "%ROOT%\%%L\run.cmd"
    if errorlevel 1 (
        set /a FAILED+=1
        echo  %%L : FAIL >> "%REPORT%"
    ) else (
        set /a PASSED+=1
        echo  %%L : PASS >> "%REPORT%"
    )
)

echo.
echo =====================================================================
echo  SUMMARY
echo =====================================================================
type "%REPORT%"
echo.
echo   passed : %PASSED%
echo   failed : %FAILED%
echo =====================================================================

if %FAILED% GTR 0 (
    echo [RESULT] FAIL -- %FAILED% labs did not pass
    exit /b 1
)
echo [RESULT] PASS -- %PASSED% labs
exit /b 0
