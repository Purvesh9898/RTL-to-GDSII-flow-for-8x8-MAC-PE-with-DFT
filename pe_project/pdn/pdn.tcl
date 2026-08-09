read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ../floorplan/pe_floorplan.v
link_design pe

read_def ../floorplan/pe_floorplan.def -floorplan_initialize

read_sdc ../constraints/pe.sdc

add_global_connection -net VDD -pin_pattern "^VPWR$" -power
add_global_connection -net VSS -pin_pattern "^VGND$" -power
add_global_connection -net VDD -pin_pattern "^VPB$"  -power
add_global_connection -net VSS -pin_pattern "^VNB$"  -power

global_connect

set_voltage_domain -power VDD -ground VSS

define_pdn_grid -name "core_grid" -voltage_domains {CORE}

add_pdn_ring -grid "core_grid"   -layers {met4 met5}   -widths {2.0 3.2}   -spacings {2.0 2.0}   -core_offsets {2.0 2.0}

add_pdn_stripe -grid "core_grid"   -layer met4   -width 1.6   -pitch 27.0   -offset 5.0

add_pdn_stripe -grid "core_grid"   -layer met5   -width 3.2   -pitch 27.0   -offset 5.0

add_pdn_connect -grid "core_grid" -layers {met4 met5}
add_pdn_connect -grid "core_grid" -layers {met1 met4}

pdngen

write_def pe_pdn.def
write_verilog pe_pdn.v
