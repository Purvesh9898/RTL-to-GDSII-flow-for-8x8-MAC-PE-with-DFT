read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ../synth/pe_synth.v
link_design pe

read_sdc ../constraints/pe.sdc

initialize_floorplan   -utilization 45   -aspect_ratio 1.0   -core_space 5   -site unithd

# Generate routing tracks for every metal layer, using the pitch/offset
# rules already defined in the tech LEF (this tech LEF only declares
# layer properties, not the actual routing grid - we build that here)
make_tracks

place_pins -random -hor_layers met3 -ver_layers met2

write_def pe_floorplan.def
write_verilog pe_floorplan.v
