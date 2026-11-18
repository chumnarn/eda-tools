@echo off
rem ==========================================================================
rem  LAB 09 : PSL assertions in VHDL -- the DELIBERATELY BUGGY variant
rem
rem  IMPORTANT : this script is EXPECTED TO FAIL.
rem               The embedded PSL property req_ack must fire and the
rem               script returns a NON ZERO exit code on purpose.
rem
rem  Exit code : 1 = the PSL assertion fired as designed  (EXPECTED)
rem               2 = the PSL assertion did NOT fire      (something is
rem                                                         broken in the lab)
rem ==========================================================================
setlocal

call "%~dp0..\tools\pick_tool.cmd"
if not defined MT (
    echo [ERROR] no usable vsim.exe with a free licence was found.
    echo         Close any running ModelSim/QuestaSim GUI, or set
    echo         QUESTASIM_HOME / MODELSIM_HOME to a valid installation.
    exit /b 2
)
set "PATH=%MT%;%PATH%"

cd /d "%~dp0"

echo =====================================================================
echo  LAB 09 : scenario BUGGY -- this run is EXPECTED TO FAIL
echo  cwd    : %CD%
echo  tool   : %MT%
echo =====================================================================

if exist result.txt del result.txt

vsim -c -onfinish stop -do "do run_fail_batch.do"
set RC=%ERRORLEVEL%

if not exist "result.txt" (
    echo [ERROR] the simulator did not finish
    exit /b 2
)

set /p RESULT=<result.txt
if /i "%RESULT%"=="PASS" goto not_caught
if not exist "results\psl_check.txt" goto no_check

set /p PSLCHECK=<results\psl_check.txt
if /i "%PSLCHECK%"=="DETECTED" goto detected
goto not_detected

:not_caught
echo [ERROR] the buggy design was NOT caught -- this scenario must fail
exit /b 2

:no_check
echo [ERROR] results\psl_check.txt is missing
exit /b 2

:detected
echo.
echo ---- the embedded PSL assertion fired like this ----
if exist "results\psl_failure.txt" type results\psl_failure.txt
echo ---------------------------------------------------
echo [RESULT] FAIL -- EXPECTED for run_fail.cmd
exit /b 1

:not_detected
echo [ERROR] the PSL assertion did NOT fire -- the lab is broken
exit /b 2
