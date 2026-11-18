@echo off
rem ==========================================================================
rem  LAB 09 : PSL assertions in VHDL -- the buggy variant compiled with
rem            "vcom -2008 -nopsl"  (embedded PSL parsing switched off)
rem
rem  Expect : the simulation runs, but NO PSL assertion message appears.
rem  Exit code : 0 = PASS, 1 = FAIL, 2 = wrong folder / tool missing
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
echo  LAB 09 : scenario BUGGY without PSL -- vcom -2008 -nopsl
echo  cwd    : %CD%
echo  tool   : %MT%
echo =====================================================================

if exist result.txt del result.txt

vsim -c -onfinish stop -do "do run_nopsl_batch.do"
set RC=%ERRORLEVEL%

if not exist "result.txt" (
    echo [RESULT] FAIL -- the simulator did not finish
    exit /b 1
)

set /p RESULT=<result.txt
if /i "%RESULT%"=="PASS" (
    echo [RESULT] PASS
    exit /b 0
)
echo [RESULT] FAIL
exit /b 1
