read_liberty /home/purvesh98/miniconda3/envs/openroad/share/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog ../synth/pe_synth.v
link_design pe
read_sdc ../constraints/pe.sdc

# Full timing report, worst setup path
report_checks -path_delay max -fields {slew cap input nets fanout} -digits 4

# Full timing report, worst hold path
report_checks -path_delay min -fields {slew cap input nets fanout} -digits 4

# Summary: worst slack across the whole design, both checks
report_worst_slack -max
report_worst_slack -min

# Check for any unconstrained/missing timing endpoints
report_checks -unconstrained
