read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog pe_routed.v
link_design pe

read_def pe_routed.def -floorplan_initialize

# Insert filler cells into every gap in every standard cell row,
# using progressively smaller filler widths to minimize leftover gaps
filler_placement {sky130_fd_sc_hd__fill_8 sky130_fd_sc_hd__fill_4                    sky130_fd_sc_hd__fill_2 sky130_fd_sc_hd__fill_1}

write_def pe_filled.def
write_verilog pe_filled.v
