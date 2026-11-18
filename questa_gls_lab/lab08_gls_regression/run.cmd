@echo off
rem ==========================================================================
rem  LAB 08 : RTL against gate level for three more designs
rem  Exit code : 0 = PASS, 1 = FAIL, 2 = wrong folder / tool not found
rem
rem  Every design needs TWO simulator processes : one for the RTL level
rem  and one for the gate level.  A ModelSim session cannot do two
rem  simulations in a row when the testbench ends with $finish.
rem ==========================================================================
setlocal enabledelayedexpansion

call "%~dp0..\tools\pick_tool.cmd"
if not defined MT (
    echo [ERROR] no usable vsim.exe with a free licence was found.
    echo         Close any running ModelSim/QuestaSim GUI, or set
    echo         QUESTASIM_HOME / MODELSIM_HOME to a valid installation.
    exit /b 2
)
set "PATH=%MT%;%PATH%"
cd /d "%~dp0"
if not exist "run_rtl.do" (
    echo [ERROR] run_rtl.do not found in %CD%
    exit /b 2
)
if not exist "results" mkdir "results"

echo =====================================================================
echo  LAB 08 : RTL against gate level, three more designs
echo  cwd    : %CD%
echo  tool   : %MT%
echo  expect : PASS -- RTL and gate level give the same trace
echo =====================================================================

if exist result.txt del result.txt

set FAILED=0
set PASSED=0
set TOTAL=0

for %%D in (alu4 fsm_light sr16) do (
    echo [DESIGN] %%D
    echo   ---- the RTL level run ----
    vsim -c -onfinish stop +TOP=%%D -do "do run_rtl.do"
    echo   ---- the gate level run ----
    vsim -c -onfinish stop +TOP=%%D -do "do run_gls.do"
    set /a TOTAL+=1
    rem  CAREFUL : a "<" redirection does NOT work inside a for block,
    rem  the verdict is read with "for /f" instead.
    set "R="
    for /f "usebackq delims=" %%V in ("results\%%D_verdict.txt") do set "R=%%V"
    if /i "!R!"=="PASS" (
        echo   [PASS] %%D
        set /a PASSED+=1
    ) else (
        echo   [FAIL] %%D
        set /a FAILED+=1
    )
)

echo.
echo =====================================================================
echo  total = !TOTAL!   passed = !PASSED!   failed = !FAILED!
echo =====================================================================

if "!FAILED!"=="0" (
    echo [RESULT] PASS
    echo PASS > result.txt
    exit /b 0
)
echo [RESULT] FAIL
echo FAIL > result.txt
exit /b 1
