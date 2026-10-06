# Parameterized INT8 MAC Accelerator: RTL to GDSII

> Open-source RTL-to-GDSII flow for a parameterized signed multiply-accumulate
> (MAC) unit with scan DFT, taken through synthesis, equivalence checking,
> place-and-route, parasitic extraction, post-route STA, DRC and LVS on the
> SkyWater SKY130 PDK. Two variants are carried through the full flow: a
> **baseline** and a **scan-inserted (DFT)** version.

<!-- Save a KLayout screenshot as docs/scan_layout.png (File > Save Layout Image) -->
![MAC layout (scan variant)](docs/scan_layout.png)

## Table of contents

- [Overview](#overview)
- [Key results](#key-results)
- [Toolchain](#toolchain)
- [Repo structure](#repo-structure)
- [Design specification](#design-specification)
- [Flow stages](#flow-stages)
- [Signoff metrics](#signoff-metrics)
- [DFT notes](#dft-notes)
- [Issues debugged](#issues-debugged)
- [Limitations](#limitations)
- [Learning outcomes](#learning-outcomes)

---

## Overview

This project takes a parameterized signed MAC (`acc += a * b`) through an
RTL-to-GDSII ASIC flow: RTL, self-checking verification with mutation testing,
synthesis, formal equivalence checking, static timing analysis, scan DFT
insertion, floorplan, power planning, placement, clock tree synthesis, routing,
RC extraction, post-route multi-corner STA, power and IR-drop analysis, GDS
generation, DRC and LVS. The tool stack is open source on `sky130_fd_sc_hd`.

The design is parameterized (`DW`, `ACC_W`) and implemented at **INT8** with a
24-bit accumulator. Only `DW = 8` was simulated, synthesized and timed.

Every unexpected result was investigated to a root cause. Several of my own
early hypotheses were tested and discarded (see
[Issues debugged](#issues-debugged)).

---

## Key results

| Metric | Baseline | Scan (DFT) |
|---|---|---|
| Clock | 15 ns (66.7 MHz) | 15 ns (66.7 MHz) |
| Synthesis area / cells | 4,443 um^2 / 666 cells (42 flops) | 4,706 um^2 (42 scan flops) |
| Final area incl. fillers and taps | 5,210 um^2, 60% utilization | 5,639 um^2, 61% utilization |
| Die | 102.27 x 102.27 um | 105.02 x 105.02 um |
| Post-route setup slack, slow corner (ss), real SPEF | **+1.90 ns** | +1.80 ns (functional mode) |
| Post-route hold slack, fast corner (ff), real SPEF | **+0.23 ns** | +0.17 ns (shift mode) |
| Clock tree | 5 x `clkbuf_8`, 2 levels, 42 sinks, 20 ps skew | same structure |
| Routed wirelength / vias | 9,289 um / 3,983 | 11,515 um / 4,398 |
| Routing DRC violations | 0 (175 -> 0 over 5 iterations) | 0 (388 -> 0 over 6 iterations) |
| Antenna violations | 0 | 0 |
| Magic DRC | **0** | **0** |
| LVS (Netgen) | **Clean**, 714 devices / 736 nets | **Clean**, 716 devices / 740 nets |
| Total power (tt, assumed activity) | 536 uW | 565 uW |
| Worst static IR drop | 0.27 mV | 0.20 mV |
| RTL simulation | 261,842 checks per seed, 5 seeds, 0 errors | scan tests: 13,350 checks, 0 errors |
| Post-layout gate-level simulation | 261,842 checks x 2 seeds, 0 errors | 261,842 checks x 2 seeds, 0 errors |
| Formal equivalence (RTL vs netlist) | 42 / 42 proven | 42 / 42 proven (`scan_enable = 0`) |

---

## Toolchain

| Tool | Version | Role |
|---|---|---|
| Verilator | system package | RTL lint (`--lint-only -Wall`) |
| Icarus Verilog | system package | RTL and gate-level simulation |
| GTKWave | 3.3.104 | Waveform viewing |
| Yosys + ABC | 0.9 | Synthesis, formal equivalence (`equiv_*`) |
| OpenSTA | Feb 2024 build (conda) | Static timing analysis |
| OpenROAD | 2.0-12381-g01bba3695 | DFT insertion, floorplan, PDN, placement, CTS, routing, OpenRCX extraction, power, IR drop |
| Magic | conda | GDS stream-out, DRC, layout extraction |
| Netgen | conda | LVS |
| KLayout | conda | GDS viewing |
| SKY130 PDK | `sky130A` via conda | Liberty, LEF, GDS, SPICE/CDL, Verilog cell models |

Host: WSL2 Ubuntu, conda `openroad` environment.

---

## Repo structure

Two sibling project folders share the same layout: `mac_rtl2gds/` (baseline)
and `mac_rtl2gds_scan/` (scan variant, a copy of the frozen baseline).

```
mac_rtl2gds/
├── rtl/          mac.v
├── tb/           mac_tb.sv (self-checking testbench), scan_tb.sv (scan flush/capture)
├── sim/          run.sh, mutants.sh, run_gls.sh, run_scan_sim.sh
├── constraints/  mac.sdc, postcts.tcl
├── syn/          run_synth.sh, make_clean_lib.py, sta_path.tcl, mac_netlist.v (+ variants A-F)
├── lec/          run_lec.sh, lec.ys
├── dft/          try_dft.tcl, scan_check.py, gen_vectors.py, sdfxtp_model.v,
│                 tie_scan.py, sta_mode.tcl
├── pnr/          floorplan.tcl, pdn.tcl, place.tcl, repair.tcl, cts.tcl, route.tcl,
│                 route_check.tcl, extract.tcl, sta_*.tcl, power.tcl, finish.tcl,
│                 gds.tcl, cdl3.tcl, lvs4.tcl, setRC.tcl, rcx_patterns.rules
├── results/      final netlists, CDL, layout SPICE, GDS
├── reports/      STA, DRC, LVS, congestion reports
├── logs/
└── README.md
```

---

## Design specification

| Parameter | Value | Rationale |
|---|---|---|
| Operand width | `DW = 8`, signed two's complement (INT8) | Dominant ML format, tractable timing closure |
| Accumulator width | `ACC_W = 2*DW + 8 = 24` | 16-bit product plus 8 guard bits (511 worst-case products fit) |
| Pipeline | 2 stages: input registers, then multiply-accumulate | Keeps input delay out of the multiplier path; 1 op per cycle |
| Reset | Synchronous, active-low `rst_n`, on all 42 flops | One clock and one reset, no recovery timing |
| Clear | Synchronous `clear`, takes priority over `en` | Deterministic behaviour when both are asserted |
| Overflow | Wraps modulo 2^24 | Kept simple; tested as specified behaviour |
| State | 42 flops: `a_r` 8, `b_r` 8, `en_r` 1, `clear_r` 1, `acc` 24 | Confirmed as 42 `dfxtp_1` after synthesis |
| DFT | Scan insertion with OpenROAD `insert_dft` | 42 `sdfxtp_1` scan flops, one chain, 3 added ports |
| Technology | `sky130_fd_sc_hd`, 1.8 V | Open PDK |

---

## Flow stages

| # | Stage | Tool | Result |
|---|---|---|---|
| 1 | RTL and lint | Verilator | `-Wall` clean |
| 2 | Functional verification | Icarus + GTKWave | Directed + constrained-random, 8 scenarios, reference model, assertions, coverage; 261,842 checks x 5 seeds, 0 errors, 0 holes; 8/8 injected bugs caught |
| 3 | SDC | OpenSTA | Clock, uncertainty, IO delays, load; dry-run validated against hand calculations |
| 4 | Synthesis | Yosys + ABC | Five netlists compared; smallest chosen: 666 cells, 4,443 um^2 |
| 5 | Pre-layout STA | OpenSTA | 3 corners; 10 ns clock failed at ss (up to -4.82 ns), so 15 ns chosen |
| 6 | Equivalence + gate-level sim | Yosys, Icarus | LEC 42/42 proven; PDK-model GLS 0 errors |
| 7 | DFT insertion | OpenROAD | 42 scan flops, 1 chain; structure 8/8, flush 5/5, capture 12,600 checks |
| 8 | Floorplan and PDN | OpenROAD | 50% target utilization, 34 rows, 108 tap cells, met4/met5 grid, 0 unconnected power pins |
| 9 | Placement | OpenROAD | Pin re-placement cut HPWL 34%; port buffering; 165 instances resized |
| 10 | Clock tree synthesis | OpenROAD | 5 buffers, 2 levels, 20 ps skew, no hold repair needed |
| 11 | Routing | OpenROAD | 0 DRC and 0 antenna violations |
| 12 | Extraction | OpenRCX | SPEF, 734 nets, 2,942 RC segments |
| 13 | Post-route STA, power, IR drop | OpenROAD | Setup and hold met at tt, ss, ff |
| 14 | Fillers, GDS, DRC | OpenROAD, Magic | 743 fillers; 0 Magic DRC violations |
| 15 | LVS | Netgen | Circuits match uniquely (both variants) |

---

## Signoff metrics

**Setup slack at the slow corner (ss), baseline, 15 ns clock:**

| Stage | Setup (ss) | Hold (ff) |
|---|---|---|
| Post-synthesis, ideal clock | +1.31 ns | +0.24 ns |
| Post-placement | +1.70 ns | +0.24 ns |
| Post-CTS, propagated clock | +1.82 ns | +0.23 ns |
| Post-route, extracted SPEF | **+1.90 ns** | **+0.23 ns** |

**Post-route timing, all corners (real wires):**

| Variant / mode | tt setup / hold | ss setup / hold | ff setup / hold |
|---|---|---|---|
| Baseline | 7.91 / 0.36 | 1.90 / 0.32 | 8.25 / 0.23 |
| Scan, functional | 7.90 / 0.41 | 1.80 / 0.42 | 8.24 / 0.28 |
| Scan, shift | 7.90 / 0.31 | 7.04 / 0.29 | 8.24 / 0.17 |

**Power (typical corner, 66.7 MHz, assumed 20% input toggle rate):**

| Group | Baseline | Scan |
|---|---|---|
| Sequential | 145 uW (27.1%) | 154 uW (27.3%) |
| Combinational | 324 uW (60.5%) | 342 uW (60.5%) |
| Clock | 66 uW (12.4%) | 69 uW (12.2%) |
| **Total** | **536 uW** | **565 uW** |

**Synthesis optimization ladder (10 ns, slow-corner minimum period):**

| Netlist | Area | Min period at ss |
|---|---|---|
| A (chosen) | 4,443 um^2 | 13.69 ns |
| C | 5,662 um^2 | 11.87 ns |
| B | 6,284 um^2 | 10.97 ns |
| D | 8,308 um^2 | 10.81 ns |
| F (default flow) | 5,739 um^2 | 14.82 ns |

---

## DFT notes

Scan was inserted with OpenROAD's `insert_dft` into a separate copy of the
frozen baseline. Each of the 42 `dfxtp_1` flops became an `sdfxtp_1` scan flop,
chained into one scan chain with ports `scan_enable_1`, `scan_in_1` and
`scan_out_1`.

- **Cost:** +263 um^2 (+5.9%) at synthesis; +429 um^2 (+8.2%) after fillers
  and buffering.
- **Verification:** scan structure check 8/8, flush test 5/5, capture test with
  300 vectors (12,600 checks), and the full functional regression on the scan
  netlist, all 0 errors. Functional-mode equivalence passes (42/42); shift mode
  fails equivalence by design (21 unproven), which shows the check is not
  vacuous.
- **Timing:** the scan variant initially lost 0.97 ns of setup slack at ss. The
  cause was a 50 fF output-port load on `b_r[0]`, which doubles as the
  `scan_out_1` net. It was diagnosed from the library data, predicted to
  recover to +1.10 ns when unloaded, and measured at exactly +1.10 ns.
  Port buffering during placement fixed it in the real flow.
- **Not done:** ATPG and fault coverage (no fault tool available in this
  toolchain). The flush and capture tests prove scan access, not coverage.

---

## Issues debugged

| Issue | Root cause | Fix |
|---|---|---|
| ABC picked power-gating isolation cells | `lpflow_*` cells are in the Liberty file | Made a cleaned copy of the library without 36 don't-use cells |
| 10 ns clock passed at tt but failed at ss | A single typical-corner check hides slow-corner failures | Re-ran 3 corners; chose smallest netlist at a 15 ns clock |
| OpenSTA error `invalid command name` | Build lacks `remove_from_collection` | Listed data inputs explicitly in the SDC |
| Scan variant lost 0.97 ns of setup at ss | Output port load on a datapath flop slowed its edge 3.6x | Confirmed with a one-line experiment; port buffering removes it |
| LVS: 736 vs 928 nets | 48 tool-inserted buffers had unconnected power pins (48 x 4 = 192 nets) | `global_connect` before exporting the CDL |
| Scan LVS: top-level pin matching failed | Output net kept the name `b_r[0]` instead of `scan_out_1` | Renamed the net to match its port, regenerated GDS, DRC and LVS |
| Weak mutation tests | Two early mutants were equivalent or ineffective | Replaced them with real bugs; documented the equivalent mutant |

My first two LVS hypotheses (cell-library CDL vs SPICE, and filler-cell nets)
were tested and ruled out before the real cause was found.

---

## Limitations

- **DRC and LVS are Magic and Netgen only.** The foundry's full signoff deck and
  metal-density checks were not run. This is not a tapeout-ready claim.
- **Power is an estimate.** It uses an assumed 20% input toggle rate, not
  activity from simulation.
- **Extraction rules** (`rcx_patterns.rules`) come from OpenROAD's SKY130 platform
  files, not from a foundry-calibrated deck.
- **SDC values are educational choices** (uncertainty, 40% IO budgets, 50 fF load).
- No ATPG or fault coverage, no SDF timing-annotated simulation, no dynamic IR
  drop or electromigration analysis.
- Only `DW = 8` was verified; other widths are parameterized by construction
  but were not simulated or synthesized.

---

## Learning outcomes

- Carried a design through the **entire RTL-to-GDSII flow**, including the
  loop-backs: a clock change after slow-corner STA, a rerun after global power
  connection, a GDS and LVS rerun after a net rename.
- Learned that **timing slack moves at every stage** as wire models improve: the
  ss setup slack went +1.31, +1.70, +1.82, +1.90 ns from synthesis to post-route.
- Understood **why DFT exists** and measured what it costs: +8.2% area and about
  0.1 ns of setup at ss after port buffering.
- Debugged by **stating a prediction, running a small test and comparing**: the
  scan setup loss and the LVS net mismatch were both resolved this way.
- Treated discarded hypotheses as part of the record rather than hiding them.
- Verified a design with **mutation testing** to prove the testbench can fail.
