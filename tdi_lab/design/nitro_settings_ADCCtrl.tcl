# =============================================================================
#  nitro_settings.tcl  --  a hand written example of the TDI setup file
#
#  This file reproduces, by hand, what the "Setup TDI" dialog of L-Edit
#  writes when the ADC8 / ADCCtrl block is configured.  It exists so that
#  the contract between the dialog and the flow can be read, checked and
#  taught without a run.
#
#  Every variable below is read by scripts that ship with Custom IC:
#
#     tanner_oasys.tcl        the synthesis step
#     ap_ref_flows/*.tcl      the place and route steps
#
#  The paths are relative to the run directory on the Linux machine that
#  runs Nitro.  TDI copies this folder to /tmp/<user>_nitro_data.
# =============================================================================


# --- 1. Run control --------------------------------------------------------
# synpnr = synthesis and place and route in one go
# syn    = synthesis only
# pnr    = place and route only
set ams_run_control "synpnr"


# --- 2. Technology and libraries -------------------------------------------
# The technology LEF has to come FIRST: it defines the layers and the vias
# that the standard cell LEF refers to.
set lef_file_list [list \
    "files/Generic250nm_tech.lef" \
    "files/Generic250nm_StdCells.lef" ]

# The same two files, but under the names that the place and route stages
# use.  The synthesis step reads lef_file_list, the flow reads these two.
set tech_file_list [list \
    "files/Generic250nm_tech.lef" ]
set cell_lef_file_list [list \
    "files/Generic250nm_StdCells.lef" ]

# The Liberty file of the corner that is used for optimisation.
set lib_file_list [list \
    "files/Generic250nm_TT_2P50V_25C.lib" ]

# The corners that the flow knows about.
set corner_list [list "nominal"]

# RLC (resistance / capacitance / inductance) model files.  An empty list
# is fine when the PTF already carries the parasitics.
set rlc_file_list [list]

# The PTF gives Nitro the parasitic resistance and capacitance per layer.
# One entry per file in ptf_file_list.
set ptf_file_list [list \
    "files/Generic250nm_typ.ptf" ]
set tanner_ptf_file_corner_list [list "nominal"]


# --- 3. Design -------------------------------------------------------------
set top_cell    "ADCCtrl"
set tanner_cell "ADCCtrl"

set verilog_file_list [list "files/ADCCtrl_rtl.v"]
set is_list_file 0
set is_Verilog 1
set list_file ""

# The same switch, under the name that the data preparation stage uses.
set use_list_file 0

# Turn the scan mapping on or off.
set enable_scan 1

# Where the synthesis step writes the gate level netlist.
set syn_netlist "results/ADCCtrl_syn.v"


# --- 4. Timing -------------------------------------------------------------
# "clocks"  - quick setup, no real delay / load information
# "sdc"     - the production route
set tanner_timing_mode "sdc"

# One analysis mode per corner that is set up.
set MGC_modes [list "nominal"]

# The SDC file of each mode.
set oasys_importConstraintsFile(nominal) [list "files/timing_constraints.sdc"]


# --- 5. Floorplan ----------------------------------------------------------
# "block"  - give the die area and the row margins by hand
# "layout" - take the boundary and the pins from the L-Edit layout
# "def"    - take them from a DEF file
set floorplan_mode "layout"

# Used when floorplan_mode is "def".
set def_floorplan_file "from_ledit.def"

# Die area, in the database units of the technology LEF (1000 DBU = 1 um).
set chip_origin_x 0
set chip_origin_y 0
set chip_width  177800
set chip_height 53000

# The standard cell row site of the library.
set core_site "CORE"

# Row margins, in um.  These are the distance between the power ring and
# the first row of standard cells, NOT the distance to the die edge: the
# flow adds the ring width to them by itself.
set core_yb_spacing 2.0
set core_xl_spacing 2.0
set core_yt_spacing 2.0
set core_xr_spacing 2.0

# Do not route above this layer.
set highest_routing_layer "Metal4"

# Target utilisation and the aspect ratio of the block.
set fp_utilization 45
set fp_aspect_ratio 3.35


# --- 6. Power plan ---------------------------------------------------------
# The first entry of each list is the main supply and the main ground.
set power_nets  [list "Vdd"]
set ground_nets [list "Gnd"]

set enable_pg_ring 1
set enable_pg_stripe 0

# Vertical ring wires on Metal4, horizontal ring wires on Metal3.
set pg_ring_vlayer "Metal4"
set pg_ring_hlayer "Metal3"

# Outermost ring first: Vdd outside, Gnd inside.
set pg_ring_net_order [list "Vdd" "Gnd"]

# One width per net in the net order, in um.
set pg_ring_widths [list 2.0 1.5]

# ONE spacing for the interval between the two rings.  The flow accepts
# either a single spacing or (number of supplies - 1) spacings; with two
# supplies a list of two spacings stops the run with a FLOW-ERROR.
set pg_ring_spacing [list 0.6]

# Extra distance between the ring and the die edge, in um.
set pg_ring_offset_top    0.0
set pg_ring_offset_right  0.0
set pg_ring_offset_bottom 0.0
set pg_ring_offset_left   0.0

set pg_stripe_list {}
set num_of_stripes 0


# --- 7. Scan ---------------------------------------------------------------
# When this is not empty the synthesis step maps the design to scan and
# writes results/<top_cell>_scan.def.
set tanner_scan_configuration_file "scanchain.tcl"
