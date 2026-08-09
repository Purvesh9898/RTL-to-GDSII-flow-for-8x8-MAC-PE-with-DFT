read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog pe_placement.v
link_design pe

read_def pe_placement.def -floorplan_initialize

read_sdc ../constraints/pe.sdc

# Use met1's real RC properties (from the tech LEF) as our representative
# wire model for parasitic estimation - met1 is a reasonable choice since
# it's commonly used for short, local, low-level signal routing
set_wire_rc -layer met1

estimate_parasitics -placement

report_checks -path_delay max -digits 4
report_checks -path_delay min -digits 4
report_worst_slack -max
report_worst_slack -min
