# TX Packet Core Canonical Rebuild And PVS Closure

Status: `P02_PHYSICAL_CONTRACT_IMPLEMENTED_CADENCE_SERVER_PENDING`

This runbook replaces the invalid historical `spadmic_tx_packet_core_HV` LVS
contract with a fresh canonical `spadmic_tx_packet_core` implementation. The
mapped Innovus GDS is the physical authority. OA is a derived, versioned review
copy only.

## Fixed Decisions

- PVS scope is DRC plus LVS; PEX is deferred.
- Layout and source top are both `spadmic_tx_packet_core`.
- The packet core is rebuilt from RTL through Genus and Innovus; the historical
  `_HV` GDS is evidence only.
- Active matrix-path TX source-data ports are scalar. Legacy
  `spadmic_top_v1` and `spadmic_packet_arbiter4` remain unchanged.
- Packet footprint remains `2066.960 x 366.800 um`.
- Packet and strip stream pins use one paired absolute-coordinate contract.
- Signal routing uses MET1-MET3. METTP is reserved for complete internal PG.
- PVS base DRC and density-enabled DRC must both be zero outside antenna.
- An antenna-only result may pass the PVS milestone but blocks final handoff.
- LVS passes only from an explicit report-level `MATCH`.

## P01 Scalar Source-Data Contract

The canonical manifest is:

```text
TOP/rtl/interfaces/tx_src_data_flat.csv
```

It contains exactly 64 unique source-major entries:

```text
src_data_i_s0_b0 ... src_data_i_s0_b15
src_data_i_s1_b0 ... src_data_i_s1_b15
src_data_i_s2_b0 ... src_data_i_s2_b15
src_data_i_s3_b0 ... src_data_i_s3_b15
```

`TOP/scripts/generate_tx_src_data_flat.py` writes explicit declarations and
connections into marked RTL regions. `--check` is mandatory in CI and fails on
any generated drift. This avoids simulator/synthesis include-path differences
while retaining one source of truth.

The API change is intentional for the active matrix path. Ordinary 1D buses
retain normal bracketed names. `spadmic_event_bundle_tx` reconstructs the
original 4x16 array internally, so arbitration behavior and dynamic indexing
remain unchanged.

Local evidence:

| Gate | Result |
| --- | --- |
| Manifest/generator unit tests | `4 pass / 0 fail` |
| Exhaustive scalar mapping oracle | `258 pass / 0 fail` |
| Event bundle regression | `14 pass / 0 fail` |
| TX egress core regression | `11 pass / 0 fail` |
| TX egress cluster regression | `13 pass / 0 fail` |
| Matrix top shell compile/regression | `32 pass / 0 fail` |

The mapping oracle drives every source/bit independently and compares all four
reconstructed source words. It detects aliases, source swaps, bit swaps,
duplicates, and missing connections.

## Required Server Gates

1. Run Xcelium for the same four TX regressions and matrix top compile.
2. Run fresh packet OOC Genus at 6.25 ns. Require no unresolved references,
   no unclocked sequential logic, no unconstrained paths, WNS non-negative,
   and TNS zero.
3. Generate the paired packet/strip pin guide from the new scalar netlist.
4. Run fresh packet Innovus with complete internal PG, then require regular
   and special connectivity zero, post-route setup/hold closure, and DRC zero
   outside the separately classified antenna markers.
5. Export mapped Innovus GDS with the official XH018 stream map and merged JIHD
   GDS. Do not promote an OA XStream GDS as the authority.
6. Prepare a filtered PG LVS source plus official JIHD CDL, create one fresh
   canonical GUI template, and replay it immutably for base DRC, density DRC,
   and LVS.
7. Re-pin/re-route and qualify the strip, then run the connected signal-route
   assembly smoke. Assembly PG remains a later phase.

## P02 Paired Physical Contract

The canonical interface file is:

```text
TOP/pnr/interfaces/tx_packet_strip_pin_contract.csv
```

It contains 19 rows in this order: valid, ready, flush, then data bits 0 through
15. Packet pins are north MET3 pins; strip pins are south MET3 pins. Both local
X columns are identical and both assembly origins are `61.980 um`, so every
link has zero intended X displacement. The first center is `100.800 um`, the
pitch is `100.800 um`, and the last center is `1915.200 um`.

The generated packet plan also consumes the P01 scalar manifest. It cannot
emit a `src_data_i[i][j]` physical port without failing local tests. The strip
plan combines the paired south assignments with the existing DDRs2-derived
north assignments in one guided-pin Tcl file.

The assembly generator no longer forces packet `MY`. It evaluates R0 and MY
from transformed LEF rectangles and minimizes crossings, maximum X delta, then
total X delta. New exact-coordinate LEFs select R0/R0; historical geometry can
still select MY/R0 when that is objectively cleaner.

## P02 Internal PG Contract

Fresh packet and strip runs enable `explicit_exact` local PG:

1. Create VDD/VSS north terminals on METTP.
2. Reuse those snapped terminal centers for explicit METTP `add_shape` paths.
3. Start VDD on the first VDD followpin row and VSS at the JIHD half-row offset.
4. Stitch only `corePin` objects with `sroute` and geometry checking.
5. Create PG before ordinary MET1-MET3 signal route.
6. Require detailed special connectivity, regular connectivity, and Innovus
   DRC independently.
7. Stream out with official map plus merged JIHD GDS and require the audit.

The corrected legacy `addStripe` formula subtracts the core-left margin before
forming `-start_offset`. This correction is retained even though TX uses
`add_shape`, because the old formula caused the measured 10.080 um displacement.

Local evidence is limited to deterministic generation, Python tests, shell
syntax, and static fail-closed checks. No local Cadence installation was used,
so `PG_CONNECTIVITY_STATUS`, Innovus DRC, timing, GDS content, PVS DRC, density,
and LVS remain unverified until the server run.

## Negative Command Ledger

- Do not flatten with `i+j`; use the explicit source/bit names above.
- Do not change 1D buses merely because the old layout had zero recognized
  pins.
- Do not rerun Genus from the old netlist after changing the RTL boundary.
- Do not reuse the `_HV` PVS template without canonical top, CDL, and pin-set
  checks.
- Do not export if regular or special connectivity is non-zero.
- Do not infer DRC clean from router transcript or LVS match from process RC.
- Do not claim the P02 implementation is physically clean from local generator
  tests; only the server connectivity and DRC reports can establish that.
- Do not force MY after the paired pin contract; use the measured orientation
  score from the actual LEFs.
- Do not allow mapped streamout without the JIHD `-merge` audit.
- Do not run multiple candidate `restoreDesign` operations in one Innovus
  process; isolate candidates when exploration is required.
