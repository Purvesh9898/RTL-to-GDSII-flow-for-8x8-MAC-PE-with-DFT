gds read /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds
lef read /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
def read ../routing/pe_filled.def

load pe
select top cell

extract do local
extract no all
extract unique
extract

ext2spice lvs
ext2spice cthresh 0
ext2spice -o pe_extracted.spice

quit -noprompt
