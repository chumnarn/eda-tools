puts **************************************
puts "*** Define SCAN Architecture     ***"        
puts **************************************

# false: create one scan chain, true: create two scan chains
set twochains false  						

define_test_clock -name clk -pin clk
define_test_pin -pin Scan_Enable -scan 1 -create_port
define_test_pin -pin clr -scan_mode 1

if {$twochains} then { 						# two scan chains
	for {set i 1} {$i <= 2} {incr i} { 
		define_scan_chain -name C$i  -scan_in SI_$i -scan_out SO_$i -scan_enable Scan_Enable -create_port  -max_length 8
	}
} else { 									# single scan chains
	define_scan_chain -scan_in Scan_In -scan_out Scan_Out -scan_enable Scan_Enable -create_port
} 
#check_dft
#connect_scan_chains
#report_scan_chains -detail
