# ============================================================
# Clock definition
# ============================================================
# create_clock: declares a clock waveform on a specific port/pin.
# -period: the clock period in nanoseconds (20ns = 50MHz)
# -name: a readable label for this clock, used in reports
# -waveform: explicitly states rising edge at 0ns, falling edge at
#            half the period (a standard 50% duty cycle clock)
create_clock -name clk -period 10 -waveform {0 5} [get_ports clk]

# ============================================================
# Input delay
# ============================================================
# Tells STA: "signals arriving at these input ports already took
# 3ns to get here from whatever external logic/register drove them."
# Without this, STA assumes inputs arrive instantly at time 0,
# which is unrealistic and hides real timing problems that would
# appear once this PE is instantiated inside a larger array where
# inputs travel from other flip-flops through real wire delay first.
set_input_delay -clock clk 3 [get_ports {a b en clear_acc}]

# ============================================================
# Output delay
# ============================================================
# Tells STA: "whatever consumes 'out' needs it to be stable at least
# 3ns before the *next* clock edge" - modeling a downstream register
# in the eventual array that this PE's output will feed.
set_output_delay -clock clk 3 [get_ports out]

# ============================================================
# Clock uncertainty
# ============================================================
# Reserves margin for real-world clock skew + jitter (concepts we
# covered in the intro) that we can't know exactly until CTS (Stage 9)
# actually builds the real clock tree. 0.25ns is a common starting
# estimate for a small design at this process node.
set_clock_uncertainty 0.25 [get_clocks clk]

# ============================================================
# rst_n: NOT clocked, so we explicitly tell STA to ignore timing
# analysis on it entirely (it's an asynchronous, slow-changing
# control signal, not part of any synchronous timing path)
# ============================================================
set_false_path -from [get_ports rst_n]
