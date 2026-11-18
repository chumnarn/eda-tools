@echo off
REM =====================================================================
REM  run_vhdl.cmd  --  the same lab, in VHDL (see appendix D of the guide)
REM ---------------------------------------------------------------------
REM  Usage (from the lab root):
REM      run_vhdl.cmd
REM
REM  The VHDL design is compiled into its own library (vhdl_work) so that
REM  it does not collide with the Verilog design unit of the same name.
REM =====================================================================
setlocal

cd /d "%~dp0.."
echo =====================================================================
echo  STEP 0 : compile VHDL (RTL instrumented with +cover=bcesft)
echo =====================================================================
if not exist vhdl_work mkdir vhdl_work
call vmap vhdl_work vhdl_work
call vcom -2008 -work vhdl_work vhdl/cmd_fsm.vhd +cover=bcesft
call vcom -2008 -work vhdl_work vhdl/tb_cmd_fsm.vhd
if not exist results mkdir results

echo.
echo =====================================================================
echo  STEP 1 : test 'basic'  ->  results/vhdl_basic.ucdb
echo =====================================================================
call vsim -c -coverage -onfinish stop vhdl_work.tb_cmd_fsm -gTEST=basic ^
    -do "run -all; coverage report -summary -codeAll; coverage save results/vhdl_basic.ucdb -codeAll -testname vbasic; quit -f"

echo.
echo =====================================================================
echo  STEP 2 : test 'extra'  ->  results/vhdl_extra.ucdb
echo =====================================================================
call vsim -c -coverage -onfinish stop vhdl_work.tb_cmd_fsm -gTEST=extra ^
    -do "run -all; coverage report -summary -codeAll; coverage save results/vhdl_extra.ucdb -codeAll -testname vextra; quit -f"

echo.
echo =====================================================================
echo  STEP 3 : test 'edge'  ->  results/vhdl_edge.ucdb
echo =====================================================================
call vsim -c -coverage -onfinish stop vhdl_work.tb_cmd_fsm -gTEST=edge ^
    -do "run -all; coverage report -summary -codeAll; coverage save results/vhdl_edge.ucdb -codeAll -testname vedge; quit -f"

echo.
echo =====================================================================
echo  STEP 4 : merge  ->  results/vhdl_merged.ucdb
echo =====================================================================
if exist results\vhdl_merged.ucdb del results\vhdl_merged.ucdb
call vcover merge results/vhdl_merged.ucdb results/vhdl_basic.ucdb results/vhdl_extra.ucdb results/vhdl_edge.ucdb

echo.
echo =====================================================================
echo  STEP 5 : report
echo =====================================================================
call vcover report -summary -codeAll results/vhdl_merged.ucdb
call vcover report -details -codeAll -output results/vhdl_merged_detail.txt results/vhdl_merged.ucdb
if exist results\vhdl_html rmdir /s /q results\vhdl_html
call vcover report -html -codeAll -output results/vhdl_html results/vhdl_merged.ucdb

echo.
echo =====================================================================
echo  DONE.  Open results\vhdl_html\index.html in a browser.
echo =====================================================================
endlocal
