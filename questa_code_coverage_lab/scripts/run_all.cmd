@echo off
REM =====================================================================
REM  run_all.cmd  --  reproduce the whole code-coverage lab from scratch
REM ---------------------------------------------------------------------
REM  Usage (from the lab root):
REM      run_all.cmd
REM
REM  Needs ModelSim / QuestaSim on the PATH, e.g.
REM      set PATH=C:\Siemens\modelsim_dlx64_2026.1\win64pe;%PATH%
REM =====================================================================
setlocal

cd /d "%~dp0.."
echo =====================================================================
echo  STEP 0 : compile (RTL instrumented with +cover=bcesft)
echo =====================================================================
if not exist work mkdir work
call vmap work work
call vlog -work work rtl/cmd_fsm.v +cover=bcesft
call vlog -work work tb/tb_cmd_fsm.v
call vlog -work work tb/pitfall/tb_cmd_fsm_basic.v
call vlog -work work tb/pitfall/tb_cmd_fsm_extra.v
if not exist results mkdir results

echo.
echo =====================================================================
echo  STEP 1 : test 'basic'  ->  results/basic.ucdb
echo =====================================================================
call vsim -c -coverage -onfinish stop work.tb_cmd_fsm +TEST=basic ^
    -do "run -all; coverage report -summary -codeAll; coverage save results/basic.ucdb -codeAll -testname basic; quit -f"

echo.
echo =====================================================================
echo  STEP 2 : test 'extra'  ->  results/extra.ucdb
echo =====================================================================
call vsim -c -coverage -onfinish stop work.tb_cmd_fsm +TEST=extra ^
    -do "run -all; coverage report -summary -codeAll; coverage save results/extra.ucdb -codeAll -testname extra; quit -f"

echo.
echo =====================================================================
echo  STEP 3 : test 'edge'  ->  results/edge.ucdb
echo =====================================================================
call vsim -c -coverage -onfinish stop work.tb_cmd_fsm +TEST=edge ^
    -do "run -all; coverage report -summary -codeAll; coverage save results/edge.ucdb -codeAll -testname edge; quit -f"

echo.
echo =====================================================================
echo  STEP 4 : merge  ->  results/merged.ucdb
echo =====================================================================
if exist results\merged.ucdb del results\merged.ucdb
call vcover merge results/merged.ucdb results/basic.ucdb results/extra.ucdb results/edge.ucdb

echo.
echo =====================================================================
echo  STEP 5 : reports
echo =====================================================================
call vcover report -summary -codeAll -instance=/tb_cmd_fsm/dut results/merged.ucdb
call vcover report -details -codeAll -output results/merged_detail.txt results/merged.ucdb
if exist results\html_report rmdir /s /q results\html_report
call vcover report -html -codeAll -output results/html_report results/merged.ucdb

echo.
echo =====================================================================
echo  STEP 6 : pitfall demo - two DIFFERENT testbench names
echo             (shows why the instance path must stay the same)
echo =====================================================================
call vsim -c -coverage -onfinish stop work.tb_cmd_fsm_basic ^
    -do "run -all; coverage save results/pit_basic.ucdb -codeAll -testname pit_basic; quit -f"
call vsim -c -coverage -onfinish stop work.tb_cmd_fsm_extra ^
    -do "run -all; coverage save results/pit_extra.ucdb -codeAll -testname pit_extra; quit -f"
if exist results\pit_merged.ucdb del results\pit_merged.ucdb
if exist results\pit_merged_du.ucdb del results\pit_merged_du.ucdb
call vcover merge results/pit_merged.ucdb results/pit_basic.ucdb results/pit_extra.ucdb
echo ---- WRONG : two different instance paths -> bins are added, not merged ----
call vcover report -summary -codeAll results/pit_merged.ucdb
call vcover merge -du work.cmd_fsm results/pit_merged_du.ucdb results/pit_basic.ucdb results/pit_extra.ucdb
echo ---- FIXED : merge by design unit ----
call vcover report -summary -codeAll results/pit_merged_du.ucdb

echo.
echo =====================================================================
echo  DONE.
echo    results\merged.ucdb            -> 100.00%% (3 tests)
echo    results\html_report\index.html -> open in a browser
echo =====================================================================
endlocal
