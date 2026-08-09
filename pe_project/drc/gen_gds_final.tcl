gds read /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds

lef read /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
def read ../routing/pe_filled.def

load pe
select top cell
expand

gds write pe_layout.gds

drc check
drc catchup
set drc_errors [drc listall why]
puts "DRC violations found:"
puts $drc_errors

quit -noprompt
