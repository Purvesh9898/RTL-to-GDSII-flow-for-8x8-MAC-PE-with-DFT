addpath /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/mag
load sky130_fd_sc_hd__xor3_1
puts "Cell loaded, checking if abstract:"
puts [cellname list self]
quit -noprompt
