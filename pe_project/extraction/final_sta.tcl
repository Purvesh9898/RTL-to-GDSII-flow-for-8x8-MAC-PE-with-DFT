read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ../routing/pe_routed.v
link_design pe

read_def ../routing/pe_routed.def -floorplan_initialize

read_sdc ../constraints/pe.sdc

# Use the REAL extracted SPEF instead of any estimate
read_spef pe_extracted.spef

set_propagated_clock [get_clocks clk]

report_checks -path_delay max -digits 4
report_checks -path_delay min -digits 4
report_worst_slack -max
report_worst_slack -min
