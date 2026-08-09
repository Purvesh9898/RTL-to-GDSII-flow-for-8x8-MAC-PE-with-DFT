read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

read_verilog ../placement/pe_placement.v
link_design pe

read_def ../placement/pe_placement.def -floorplan_initialize

read_sdc ../constraints/pe.sdc

set_wire_rc -layer met1
estimate_parasitics -placement

# ============================================================
# Clock Tree Synthesis
# ============================================================
# -buf_list: which real standard cells TritonCTS is allowed to
#   insert as clock tree buffers, in increasing drive strength
# -sink_clustering_enable: groups nearby flip-flops together
#   before building buffer stages, reducing tree depth/skew
clock_tree_synthesis   -root_buf sky130_fd_sc_hd__clkbuf_4   -buf_list {sky130_fd_sc_hd__clkbuf_1 sky130_fd_sc_hd__clkbuf_2              sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8}   -sink_clustering_enable   -sink_clustering_size 10   -sink_clustering_max_diameter 50

# Legalize placement again - CTS just inserted new buffer cells
# that need real, legal positions in the rows
detailed_placement

# Re-estimate parasitics now that real clock buffers/wires exist
estimate_parasitics -placement

# Report actual clock tree metrics: skew, latency, buffer count
report_clock_skew
report_cts

# Full timing check with the REAL clock network now, not ideal
report_checks -path_delay max -digits 4
report_checks -path_delay min -digits 4
report_worst_slack -max
report_worst_slack -min

write_def pe_cts.def
write_verilog pe_cts.v
