@echo off
rem ==========================================================================
rem  LAB 03 : self-checking testbench  --  FAIL case on purpose
rem  This script is EXPECTED to report [RESULT] FAIL and exit with code 1.
rem  It shows what a severity failure looks like in the transcript.
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
echo  LAB 03 : FAIL case on purpose -- INJECT_ERROR = true
echo  Expected result: [RESULT] FAIL
echo  tool   : %MT%
echo =====================================================================

if exist result.txt del result.txt

vsim -c -onfinish stop -do "set FAILMODE 1; do run_batch.do"
set RC=%ERRORLEVEL%

if not exist "result.txt" (
    echo [RESULT] FAIL -- the simulator did not finish
    exit /b 1
)

set /p RESULT=<result.txt
if /i "%RESULT%"=="PASS" (
    echo [RESULT] PASS -- unexpected for the fail case
    exit /b 1
)
echo [RESULT] FAIL as expected -- exit=%RC%
exit /b 1
