@echo off
rem ==========================================================================
rem  LAB 10 : code coverage for VHDL -- batch runner
rem  Exit code : 0 = PASS, 1 = FAIL, 2 = wrong folder / tool missing
rem  NOTE      : this file is ASCII-only on purpose.
rem              Thai text in a .cmd file breaks cmd.exe code-page handling.
rem  RULE      : never put an unescaped "(" or ")" inside an echo line that
rem              sits inside an if-block -- cmd.exe reports a syntax error
rem              and aborts the whole script without any message.
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
echo  LAB 10 : code coverage for VHDL
echo  cwd    : %CD%
echo  tool   : %MT%
echo  expect : PASS
echo =====================================================================

if exist result.txt del result.txt

rem --- STEP 1 : compile the DUT with coverage, the testbench without ----
echo [STEP 1] compile
vsim -c -onfinish stop -do "do compile.do; quit -f"
if errorlevel 1 goto tool_error

rem --- STEP 2..4 : the three tests, one simulator session each ---------
echo [STEP 2] test basic
vsim -c -onfinish stop -do "do test_basic.do; quit -f"
if errorlevel 1 goto tool_error

echo [STEP 3] test extra
vsim -c -onfinish stop -do "do test_extra.do; quit -f"
if errorlevel 1 goto tool_error

echo [STEP 4] test edge
vsim -c -onfinish stop -do "do test_edge.do; quit -f"
if errorlevel 1 goto tool_error

rem --- STEP 5 : merge the three UCDB files ------------------------------
echo [STEP 5] merge
vsim -c -onfinish stop -do "do merge.do; quit -f"
if errorlevel 1 goto tool_error

rem --- STEP 6 : the reports --------------------------------------------
echo [STEP 6] report
vsim -c -onfinish stop -do "do report.do; quit -f"
if errorlevel 1 goto tool_error

rem --- STEP 7 : PITFALL 1, the default spec of +cover -------------------
echo [STEP 7] pitfall 1 -- the default spec of +cover
vsim -c -onfinish stop -do "do pitfall_a_cover_spec.do; quit -f"
if errorlevel 1 goto tool_error

rem --- STEP 8 : PITFALL 3, coverage goal outside the Coverage View -----
echo [STEP 8] pitfall 3 -- coverage goal
vsim -c -onfinish stop -do "do pitfall_c_goal.do; quit -f"
if errorlevel 1 goto tool_error

rem --- STEP 9 : PITFALL 4, two different instance paths -----------------
echo [STEP 9] pitfall 4 -- two instance paths
vsim -c -onfinish stop -do "do pitfall_d_instance.do; quit -f"
if errorlevel 1 goto tool_error

rem --- STEP 10 : PITFALL 2, std.env.finish WITHOUT -onfinish stop -------
rem     The session dies inside std.env.finish, "coverage save" never runs
rem     and no UCDB file is produced.
echo [STEP 10] pitfall 2 -- std.env.finish without -onfinish stop
if exist "results\pitfall_finish_nostop.ucdb" del "results\pitfall_finish_nostop.ucdb"
vsim -c -coverage work.tb_alu_fsm_finish -do "run -all; coverage save results/pitfall_finish_nostop.ucdb -codeAll -testname nostop; quit -f"

rem --- STEP 11 : PITFALL 2, the same run WITH -onfinish stop -----------
rem     Now the simulation only stops, the session stays alive and the
rem     UCDB file is really written.
echo [STEP 11] pitfall 2 -- std.env.finish with -onfinish stop
if exist "results\pitfall_finish_stop.ucdb" del "results\pitfall_finish_stop.ucdb"
vsim -c -onfinish stop -coverage work.tb_alu_fsm_finish -do "run -all; coverage save results/pitfall_finish_stop.ucdb -codeAll -testname stop; quit -f"

rem --- STEP 12 : PITFALL 3, coverage goal inside the Coverage View -----
echo [STEP 12] pitfall 3 -- coverage goal in the Coverage View
vsim -c -viewcov results/merged.ucdb -do "coverage goal; quit -f" > results\pitfall_goal_viewcov.txt 2>&1

rem --- STEP 13 : collect every pitfall in one file --------------------
echo [STEP 13] pitfall summary
vsim -c -onfinish stop -do "do pitfall_summary.do; quit -f"
if errorlevel 1 goto tool_error

rem --- STEP 14 : the verdict -------------------------------------------
echo [STEP 14] verdict
vsim -c -onfinish stop -do "do run_batch.do; quit -f"

set RC=%ERRORLEVEL%

rem  vsim returns 0 even when it cannot open the .do file, so never trust
rem  the exit code alone -- check the result file written by run_batch.do
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

:tool_error
echo [ERROR] a step of the coverage flow failed
exit /b 1