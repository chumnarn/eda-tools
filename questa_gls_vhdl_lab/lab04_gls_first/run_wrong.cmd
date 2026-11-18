@echo off
rem ==========================================================================
rem  LAB 04 : the WRONG way on purpose -- the cells are in another library
rem
rem  WHAT THIS SCRIPT DEMONSTRATES
rem    The netlist is compiled into "work" but the cell models are
rem    compiled into a different library ("cells_lib").  The simulator
rem    then refuses the design :
rem
rem      ** Error: (vsim-3033) Instantiation of 'sg13g2_...' failed.
rem                 The design unit was not found.
rem      Error loading design
rem
rem  WHY THE VERDICT IS DECIDED HERE AND NOT IN THE .do FILE
rem    A failed design load is FATAL : the ModelSim session ends on the
rem    spot, so no Tcl command after the "vsim" call is reached and no
rem    result file can be written from inside the session.  The verdict
rem    is therefore taken from the transcript file, after the simulator
rem    has exited -- exactly the way a CI system would see it.
rem
rem  Exit code : 0 = the expected mistake happened (the point of this lab)
rem              1 = the mistake did NOT happen (the script itself failed)
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
if not exist "run_wrong_batch.do" (
    echo [ERROR] run_wrong_batch.do not found in %CD%
    exit /b 2
)

echo =====================================================================
echo  LAB 04 : the WRONG way -- the cells are in another library
echo  cwd    : %CD%
echo  tool   : %MT%
echo  expect : the simulator REFUSES the design (vsim-3033)
echo =====================================================================

if exist result.txt del result.txt

vsim -c -onfinish stop -do "do run_wrong_batch.do"
set RC=%ERRORLEVEL%

echo.
echo ---- the error that was expected ----

set "NCNT=0"
for /f %%N in ('findstr /C:"vsim-3033" transcript ^| find /c /v ""') do set "NCNT=%%N"

if "%NCNT%"=="0" (
    echo [RESULT] FAILED -- the expected mistake did NOT happen
    exit /b 1
)

echo   the transcript contains %NCNT% line(s) with "vsim-3033"
echo   (one line per instance of a cell that could not be found)
echo   the exit code of vsim itself was %RC%
echo   NOTE : a .do file that cannot be opened gives exit code 0 too
echo          (measured on this machine).  A build system that only
echo          looks at the exit code will NOT notice that failure --
echo          always read the transcript.
echo.
echo [RESULT] AS EXPECTED -- the simulator refused the design
exit /b 0
