# PE Project — 8-bit MAC Processing Element (RTL to GDSII)

> Open-source RTL-to-GDSII physical design flow for an 8-bit MAC processing
> element with DFT, taken through real synthesis, place-and-route, and
> signoff verification on the SkyWater sky130 PDK.

![Status: Timing Closed](https://img.shields.io/badge/timing-closed-brightgreen)
![Status: DRC Clean](https://img.shields.io/badge/DRC-0_violations-brightgreen)
![Status: LVS Matched](https://img.shields.io/badge/LVS-363%2F363_matched-brightgreen)
![PDK: sky130](https://img.shields.io/badge/PDK-sky130-blue)

![PE layout](docs/pe_layout.png)

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
- [Learning outcomes](#learning-outcomes)
- [License](#license)

---

## Overview

This project carries an 8-bit multiply-accumulate (MAC) Processing Element
through a complete, industrial-style RTL-to-GDSII ASIC flow — RTL,
verification, synthesis, floorplanning, power planning, placement, clock
tree synthesis, routing, extraction, signoff STA, DRC, LVS, and GDSII
generation — using a fully open-source EDA stack on the sky130A PDK
(`sky130_fd_sc_hd`).

Unlike a simplified tutorial run, every stage here reached a genuine,
tool-verified signoff, and every tool/design issue encountered along the
way was root-caused and documented rather than worked around.

---

## Key results

| Metric | Result |
|---|---|
| Target clock frequency | 100 MHz (10 ns period) |
| Final setup / hold slack (post-route, real SPEF) | +0.5029 ns / +0.2864 ns — **MET** |
| Total cells | 363 logic + 619 filler = 982 |
| Die size / utilization | 95.32 µm x 95.32 µm / 46% |
| Routed wirelength | 8464 µm |
| DRC violations | 0 |
| LVS device match | 363 / 363 — perfect |
| Total power (100MHz, 0.2 activity) | 773 µW |
| Final GDSII | `pe_layout.gds` — 39 unique cells, 29 layers |

---

## Toolchain

| Tool | Version | Role |
|---|---|---|
| Icarus Verilog | 11.0 | RTL / testbench simulation |
| Verilator | 4.038 | Lint / simulation |
| GTKWave | 3.3.104 | Waveform viewing |
| Verible | v0.0-4121 | RTL style lint |
| Yosys | 0.9 | Synthesis |
| SymbiYosys | — | Formal verification |
| OpenSTA | 3.1.0 | Static timing analysis |
| OpenROAD | 2.0-12381 | Floorplan, PDN, placement, CTS, routing, extraction (OpenRCX) |
| Magic | 8.3.464 | DRC, layout extraction, GDS generation |
| Netgen | 1.5.272 | LVS |
| KLayout | 0.28.12 | GDS inspection / viewing |
| sky130 PDK | open_pdks 1.0.471 | Process design kit |

---

## Repo structure

```
pe_project/
├── rtl/          pe.v, tb_pe.sv
├── synth/        synth.ys, pe_synth.v
├── constraints/  pe.sdc
├── sta/          run_sta.tcl, final_sta.tcl
├── floorplan/    floorplan.tcl, report_fp.tcl
├── pdn/          pdn.tcl
├── placement/    placement.tcl, report_placement_sta.tcl
├── cts/          cts.tcl, report_cts_sta.tcl
├── routing/      routing.tcl
├── extract/      extract.tcl
├── drc/          gen_gds.tcl, fillers.tcl, pe_layout.gds
├── lvs/          extract_netlist.tcl, rewrite_verilog.tcl
├── docs/         pe_layout.png
├── .gitignore
└── README.md
```

---

## Design specification

| Parameter | Value | Rationale |
|---|---|---|
| Operand width | 8 bits (a, b) | Real multiplier hardware, tractable first-pass timing closure |
| Accumulator width | 20 bits | 16-bit product + 4 guard bits for headroom |
| Reset | Asynchronous, active-low (`rst_n`) | Standard ASIC convention |
| Clear | Synchronous (`clear_acc`) | Separate operational control, not chip-wide reset |
| Enable | `en` | Gates accumulation |
| DFT | Custom RTL-level scan mux (`scan_en`, `scan_in`, `scan_out`) | Full shift-chain controllability/observability of the accumulator |

---

## Flow stages

| # | Stage | Tool | Result |
|---|---|---|---|
| 1 | RTL design | — | 8-bit MAC PE + DFT scan chain; lint-clean |
| 2 | Functional simulation | Icarus + GTKWave | 9/9 self-checking tests passed |
| 3 | Synthesis | Yosys | 363 logic cells, 3275.64 µm² |
| 4 | Constraint writing | SDC | 100MHz target, real false-path/uncertainty budgeting |
| 5 | STA (pre-layout) | OpenSTA | +0.3912ns setup / +0.2622ns hold (ideal clock) |
| 6 | Floorplanning | OpenROAD | 95.32µm x 95.32µm die, 46% utilization |
| 7 | Power planning (PDN) | OpenROAD | Via-enclosure-verified ring + strap PDN |
| 8 | Placement | OpenROAD | Legal, zero violations, real wire-RC STA re-check |
| 9 | Clock tree synthesis | OpenROAD | 3 buffers, 0.2537ns latency, -0.01ns skew |
| 10 | Routing | OpenROAD | 8464µm wirelength, 0 DRC violations (6-iteration convergence) |
| 11 | Parasitic extraction | OpenRCX | Real SPEF, 1522 RC segments, 383 nets |
| 12 | Post-route STA + power | OpenSTA | +0.5029ns setup / +0.2864ns hold; 773µW total power |
| 13 | DRC | Magic | 0 violations (after filler-cell root-cause fix) |
| 14 | LVS | Netgen | 363/363 devices matched; net gap fully traced |
| 15 | GDSII generation | Magic / KLayout | `pe_layout.gds`, 95.32µm x 95.32µm, 39 unique cells, 29 layers |

---

## Signoff metrics

**Timing progression across the flow:**

| Stage | Setup slack |
|---|---|
| Post-synthesis, ideal clock, no DFT | +0.4967 ns |
| Post-synthesis, ideal clock, + DFT | +0.3912 ns |
| Post-placement, real wire RC estimate | +0.2115 ns |
| Post-CTS, propagated clock | +0.4828 ns |
| Post-route, real extracted SPEF (final) | +0.5029 ns |

**Power breakdown (post-route):**

| Group | Total (W) | % of design |
|---|---|---|
| Sequential | 1.59e-04 | 20.6% |
| Combinational | 5.80e-04 | 75.1% |
| Clock | 3.36e-05 | 4.3% |
| **Total** | **7.73e-04** | **100%** |

---

## DFT notes

DFT was implemented as a custom RTL-level scan mux rather than library scan
cells, because the Yosys version used in this flow could not reliably
characterize sky130's dedicated scan-cell timing arcs. This gives full
shift-chain controllability/observability of the accumulator at a 4.3% area
cost (355 → 363 cells).

The LVS net-count discrepancy (379 vs 387 nets, devices matching 363/363
exactly) was traced to the intentional `scan_out = out[19]` aliasing this
design introduces, and is documented as safe to carry forward rather than
an unexplained pass.

---

## Issues debugged

23 real tool/environment issues were root-caused during this flow. A
representative sample:

| Issue | Root cause | Fix |
|---|---|---|
| OpenSTA build failed on missing CUDD | Not an apt package | Built OpenROAD-maintained CUDD fork from source |
| PDN via insertion failed (20/20) | met4 too narrow for via4 enclosure rule | Widened strap to 1.6µm per LEF minimum |
| Magic: 8000+ layer parse errors, segfault | Wrong tech file loaded manually | Used `magic -rcfile $MAGICRC` with correct sky130A.tech |
| DRC: N-well spacing/width violations | No filler cells at 46% utilization broke N-well continuity | Filler placement in OpenROAD, 619 cells inserted |
| LVS: 379 vs 1841 nets | Power/ground pins unconnected in exported Verilog | Re-ran global power/ground connection before netlist export |

---

## Learning outcomes

- Carried a design through the **entire RTL-to-GDSII flow** end to end,
  including the loop-backs each signoff failure caused (e.g. re-running STA
  after CTS, re-running DRC after adding filler cells).
- Understood **why DFT exists**: without scan chains, a fabricated chip has
  no economical way to be tested for manufacturing defects post-silicon.
- Learned that **timing slack is not static** — it changed at nearly every
  stage as wire delay models became more accurate, which is why signoff STA
  is always run post-route, not just once early in the flow.
- Debugged real tool failures independently (PDN via rules, DRC tech-file
  loading, missing filler cells, LVS netlist export) rather than working
  around them.
- Treated an LVS mismatch as a **finding to investigate and explain**, not a
  failure to hide.
- Built and debugged a full open-source EDA environment from source and
  conda packages, including dependency, networking, and PDK path issues.
