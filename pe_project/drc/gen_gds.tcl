# Load ALL real standard cell geometry first, so every cell name
# is already resident with full geometry before DEF references them
gds read /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds

# Now read LEF (for tech layer/via rules) and DEF (our design)
lef read /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
def read ../routing/pe_routed.def

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
