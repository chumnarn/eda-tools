@echo off
rem ==========================================================================
rem  LAB 04 : the WRONG way on purpose -- the cells are in another library
rem
rem  IMPORTANT : this script is EXPECTED to FAIL.
rem               The simulator refuses the design with
rem                 ** Error: (vsim-3033) Instantiation of 'sg13g2_...' failed.
rem                            The design unit was not found.
rem
rem  Exit code : 1 = the design could not be loaded (EXPECTED)
rem ==========================================================================
setlocal

call "%~dp0..\tools\pick_tool.cmd"
if not defined MT (
    echo [ERROR] no usable vsim.exe with a free licence was found.
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
echo  expect : FAIL on purpose (vsim-3033)
echo =====================================================================

if exist result.txt del result.txt

vsim -c -onfinish stop -do "do run_wrong_batch.do"
set RC=%ERRORLEVEL%

echo.
echo ---- the error that was expected ----
echo [RESULT] FAIL -- EXPECTED for run_wrong.cmd
exit /b 1
