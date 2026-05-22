# SYNTHESIS SIGN-OFF BLUEPRINT — `spadmic_position_block` (Phase 11 Baseline)

## Section 1: Synthesis QoR Scorecard

### 1.1 Phase 9.1 Failure vs Phase 11 Baseline

| Metric | Phase 9.1 (failure) | Phase 11 baseline (current frozen RTL) | Status |
|---|---:|---:|---|
| Setup WNS | ~-45 ns class failure (diagnostic runs also showed ~-48.55 ns path) | +0.7 ps to +1 ps | Closed, but razor-thin |
| TNS | Large negative (multi-path collapse) | 0.0 | Clean |
| Violating paths | Thousands (catastrophic) | 0 | Clean |
| Worst path nature | Deep scanner ripple/unrolled recurrence | Localized scanner chunk path near threshold logic | Greatly improved |
| Elaboration behavior | Hang/infinite-unroll symptoms in failing architecture | Completes normally | Fixed |
| Clocking sanity | Prior run had `worst_clk_period` ambiguity symptoms (`-1.0000`) in failure context | `clk_sys` clean at 6.25 ns, setup view valid | Fixed for baseline |
| Interconnect model | Non-physical optimism in failing and baseline OOC context | `Interconnect mode: global` (no placed RC) | Risk remains |

### 1.2 Phase 11 Physical Footprint and Mapping Profile

- **Total Area (Cell + Net):** `991272.376 µm²` (~**0.991 mm²**)
- **Mapped Cell Area:** `639668.736 µm²`
- **Net Area:** `351603.640 µm²`
- **Leaf instances:** `26189` (`6919` sequential / `19270` combinational)
- **Max fanout:** `6919 (clk_sys)`

### 1.3 Dominant Area Driver

- `u_frame_fifo` (`mptdc_sync_fifo_WIDTH290_DEPTH16`) area:
  - **Total:** `593832.840 µm²`
  - **Cell:** `379026.995 µm²`
  - **Net:** `214805.845 µm²`
- This is roughly **60% of full block total area** (`593832.840 / 991272.376`).

### 1.4 Performance Boundary Evidence

Critical timing reports include aggressive drive usage in the top paths (examples):
- `BUHDX12`
- `INHDX12`
- `INHDX8`
- `BUHDX8`

This confirms Genus is operating near a **local performance edge** for this architecture/corner/constraint set.

---

## Section 2: Script Debt & CDC Risk Warnings

### 2.1 Script/Report Debt Identified

1. **Hierarchical area command mismatch**
   - Observed failure artifact: `report_area_hierarchy*.rpt` contains:
     - `Command failed: report_area -hierarchy`
   - Corrective action:
     - Use Genus-supported form `report_area -hierarchical`

2. **Pre-synth message debt present in baseline logs**
   - Error/warning families observed during run setup include:
     - `SDC-202`, `SDC-209`, `SDC-248`
     - `TUI-24`, `TUI-182`, `TUI-183`, `TUI-204`, `TUI-210`
   - Baseline still converged to timing closure, but this debt must be removed for production-grade sign-off hygiene.

### 2.2 CDC Preservation Warning (High Severity)

`check_design_post_elab.rpt` reports:
- `No preserved sequential instance(s) in design 'spadmic_position_block'`

**Physical risk in Innovus:**
- The async capture chain (`ff1/ff2/ff3`) may be remapped, merged, or physically spread if not explicitly protected.
- That can degrade synchronizer MTBF and can induce metastability propagation behavior at the detector front-end.
- For final sign-off, synchronizers must be both **logic-protected** and **physically clustered** near async entry boundaries.

---

## Section 3: Production Sign-off Optimization Plan (Future Hardening)

> These are **future hardening overrides** for production sign-off.  
> Baseline prototype RTL and latency remain frozen for current exploratory P&R.

### 3.1 Clock Over-Constraining (Physical Margin Injection)

#### Strategy A — SDC Over-Constraining (period tightening during synthesis only)

```tcl
# In position/syn/inputs/spadmic_position.sdc (production hardening pass only)
set POS_CLK_SYS_PERIOD_NS 5.500
```

#### Strategy B — Uncertainty Padding (consume slack without changing RTL)

```tcl
# In position/syn/inputs/spadmic_position.sdc (production hardening pass only)
set POS_CLK_UNCERTAINTY_NS 0.600
```

### 3.2 Turnkey Synchronizer Protection Script (post-mapping guard)

```tcl
set sync_regs [get_cells -quiet -hierarchical *sync_ff*_reg*]
if {[llength $sync_regs] == 0} {
    puts "ERROR: No synchronizer registers matched; fix preserve query."
} else {
    set_dont_touch $sync_regs true
    set_db $sync_regs .preserve true
}
```

### 3.3 Advanced Diagnostics Expansion (drop-in)

```tcl
# Deep timing visibility (100 worst setup paths with net details)
report_timing -max_paths 100 -path_type full_clock -nets > $design(reports_dir)/timing/report_timing_post_opt_full.rpt

# Full design-rule visibility
report_design_rules -all > $design(reports_dir)/qor/report_design_rules_all.rpt

# Error-only message isolation
report_messages -severity error > $design(reports_dir)/messages/report_errors.rpt
```

### 3.4 Report command fix (must apply in production script)

```tcl
position_run_report "report_area -hierarchical" \
    "$design(reports_dir)/qor/report_area_hierarchy_${tag}.rpt"
```

---

## Section 4: **LAST RESORT FALLBACK: Adds +1 Cycle of Latency—DO NOT IMPLEMENT UNLESS POST-CTS TIMING IS UNCLOSABLE.**

If Innovus post-CTS/post-route timing turns negative and cannot be recovered by constraints/sizing/placement optimization:

1. Split the current worst scanner chunk stage in `spadmic_axis_cluster_scan.sv` by inserting **exactly one** additional register boundary after threshold predecode.
2. Restructure chunk evaluation as a **4-bit + 4-bit registered merge** (instead of current single-stage 8-bit chunk pressure point).
3. Preserve all cluster semantics and overflow behavior; only latency changes by **+1 cycle**.

This is the final architectural fallback and is intentionally deferred until physical evidence proves closure is unattainable otherwise.
