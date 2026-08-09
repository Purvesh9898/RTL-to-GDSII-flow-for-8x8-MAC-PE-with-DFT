read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ../pdn/pe_pdn.v
link_design pe

read_def ../pdn/pe_pdn.def -floorplan_initialize

read_sdc ../constraints/pe.sdc

global_placement -density 0.55 -init_density_penalty 0.01

detailed_placement

check_placement -verbose

report_design_area
report_checks -path_delay max -digits 4

write_def pe_placement.def
write_verilog pe_placement.v
