read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ../cts/pe_cts.v
link_design pe

read_def ../cts/pe_cts.def -floorplan_initialize

read_sdc ../constraints/pe.sdc

set_wire_rc -layer met1
estimate_parasitics -placement
set_propagated_clock [get_clocks clk]

# ============================================================
# Global Routing
# ============================================================
# -guide_file: writes out the coarse routing plan (used by
#   detailed routing next)
# Layer range: met1 (lowest signal layer) through met5
set_routing_layers -signal met1-met5

global_route -guide_file pe_route.guide

# Report congestion before committing to detailed routing -
# catching congestion here is much cheaper than discovering
# a detailed-route failure later
report_design_area

# ============================================================
# Detailed Routing
# ============================================================
detailed_route   -output_guide pe_route_detailed.guide   -output_drc pe_route.drc   -bottom_routing_layer met1   -top_routing_layer met5

write_def pe_routed.def
write_verilog pe_routed.v
