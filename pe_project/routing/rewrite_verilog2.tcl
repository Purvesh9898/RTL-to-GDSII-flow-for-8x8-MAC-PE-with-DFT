read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog pe_filled.v
link_design pe
read_def pe_filled.def -floorplan_initialize

add_global_connection -net VDD -pin_pattern "^VPWR$" -power
add_global_connection -net VSS -pin_pattern "^VGND$" -power
add_global_connection -net VDD -pin_pattern "^VPB$"  -power
add_global_connection -net VSS -pin_pattern "^VNB$"  -power
global_connect

write_verilog -include_pwr_gnd pe_filled_pwr2.v
