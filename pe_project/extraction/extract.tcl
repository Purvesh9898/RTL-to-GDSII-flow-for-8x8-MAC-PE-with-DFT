read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ../routing/pe_routed.v
link_design pe

read_def ../routing/pe_routed.def -floorplan_initialize

define_process_corner -ext_model_index 0 X
extract_parasitics -ext_model_file /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.tech/openlane/rules.openrcx.sky130A.nom.spef_extractor

write_spef pe_extracted.spef
