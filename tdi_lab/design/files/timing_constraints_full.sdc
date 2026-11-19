# =============================================================================
#  timing_constraints_full.sdc
#
#  A complete version of the constraint of the ADC8 example.
#
#  The file that ships with the example (timing_constraints.sdc) only has
#  one line:
#
#      create_clock -name clk -period 10000 -waveform {0 5000} [get_ports clk]
#
#  That is enough to place and route a block, but it leaves the interface
#  completely unconstrained: the flow does not know how long the inputs
#  may take to arrive, and it does not know how much time the outputs
#  have.  For a production run the interface has to be constrained too.
#
#  The numbers below are taken from the design itself:
#      clock period 10000 ns, clock edge at 0 and 5000 ns
#      8 bit data bus on the output, 4 control inputs
# =============================================================================

# --- the clock -------------------------------------------------------------
# The period is in ns: 10000 ns = 10 us.
create_clock -name clk -period 10000 -waveform {0 5000} [get_ports clk]

# --- input delays ----------------------------------------------------------
# The inputs are driven by the analog part of the ADC8, which is placed in
# the neighbouring cell.  A quarter of the period is a reasonable budget
# for a block to block connection.
set_input_delay  -clock clk 2500 [get_ports {clr Compare Start}]

# --- output delays ---------------------------------------------------------
# The outputs go to the next level of the hierarchy.
set_output_delay -clock clk 2500 [get_ports {LoadReg DataMark SerialOutput B[*]}]

# --- what must not be timed ------------------------------------------------
# The asynchronous clear is not timed against the clock.
set_false_path -from [get_ports clr]
