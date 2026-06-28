# Review: Matrix TOP Phase 0

Status: Phase 0 signed off by Verifier.

## Repository Snapshot

- Branch: `SPADMIC_test`
- Commit reviewed: `a9ec83afc2ca2923896af014e6bc8e4fae6c4296`
- Last commit: `a9ec83af position: add matrice3 final matrix extraction results`
- Working tree context:
  - untracked user references: `ParameterDefs.sv`, `multi_ShiftRegisterChain_cfg_v1.sv`, `pixel_readout.pdf`
  - Phase 0 documentation files are newly created and uncommitted.

## Phase Reviewed

Phase 0 - documentation and decision log.

## Files Reviewed

- `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`
- `TOP/docs/11_FINAL_TOP_RESET_CONTROL_PLAN.md`
- `TOP/docs/12_FINAL_CSR_MAP_PROPOSAL.md`
- `TOP/docs/13_MATRIX_CONFIG_AND_RESET_CONTRACT.md`
- `TOP/docs/14_DDR16_TX_MACRO_CONTRACT.md`
- `TOP/docs/15_FLOORPLAN_MATRICE3_INTEGRATION_PLAN.md`
- `TOP/docs/16_TOP_IMPLEMENTATION_PHASES.md`
- `TOP/docs/17_VERIFICATION_PLAN_MATRIX_TOP.md`
- `TOP/docs/18_STA_CDC_PNR_PLAN_MATRIX_TOP.md`

Reference files checked by Verifier:

- `TOP/rtl/spadmic_pkg.sv`
- `TOP/rtl/spadmic_csr_decoder.sv`
- `I2C/rtl/spadmic_i2c_slave.sv`
- `position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv`

## Specification Points Checked

- `clk_cfg_40m` is documented as a separate PLL-generated matrix configuration domain.
- Matrix configuration CDC uses stable-bus plus toggle handshake.
- Mode-dependent masks are required; no fixed all-source AND is allowed.
- DDR16 pair-valid default is recorded and current 8-bit DDR TX is marked obsolete.
- Matrix configuration is 44 columns by 64 bits.
- Floorplan plan uses normalized `ll_*` matrix CSV coordinates and reserves `INTERNAL_NEAREST_RIGHT` corridors.
- MPTDC internals are protected.
- Old reference PDF/SV files are concept references only, not SPADMIC RTL sources.

## Tests And Checks Run

Builder checks:

- `git diff --check`
- `rg` for critical decisions in Phase 0 docs

Verifier checks:

- read-only inspection of Phase 0 docs and current RTL address-width sources
- matrix CSV fact consistency review

No simulation or lint was run in Phase 0 because no RTL was implemented.

## Findings

### P0-001 - Current RTL CSR Width Does Not Reach Final 16-Bit Map

- Severity: HIGH
- Status: FIXED
- Issue: `12_FINAL_CSR_MAP_PROPOSAL.md` reserves a final 16-bit CSR map through `0x7xxx`, while current RTL still stores/decodes 12-bit CSR addresses.
- Affected files:
  - `TOP/docs/12_FINAL_CSR_MAP_PROPOSAL.md`
  - `TOP/rtl/spadmic_pkg.sv`
  - `TOP/rtl/spadmic_csr_decoder.sv`
  - `I2C/rtl/spadmic_i2c_slave.sv`
- Risk: An implementer could mistakenly assume the proposed regions are already reachable.
- Builder response: recorded current 12-bit CSR handling as obsolete/incomplete in the decision log and added an explicit warning in the CSR proposal that Phase 3 must widen address storage/decode before final regions are reachable.
- Fix status: FIXED in documentation. RTL fix deferred to Phase 3.

### P0-002 - Phase 0 Review Report Was Missing

- Severity: MEDIUM
- Status: FIXED
- Issue: The decision log and phase plan listed a Phase 0 review report, but the file did not exist yet.
- Affected files:
  - `TOP/docs/DECISIONS_LOG_MATRIX_TOP.md`
  - `TOP/docs/16_TOP_IMPLEMENTATION_PHASES.md`
  - `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE0.md`
- Risk: Review-loop status was ambiguous.
- Builder response: created this review report and updated the decision log to show Builder response complete and Verifier recheck pending.
- Fix status: FIXED.

## CDC/Reset/STA/PnR Risks

- `clk_cfg_40m` domain is new relative to active TOP RTL and must be introduced with local reset synchronization and a robust command/status CDC.
- Matrix configuration timing remains non-signoff until analog handoff provides setup, hold, min high, min low, and Dout/Cout delay.
- OR64 START trees need physical review and cannot be hidden only by broad false paths.
- Matrix reset outputs need register/buffer placement close to Rz/Yz/Bz pin banks.
- DDR16 macro timing and board timing remain TBD.

## Protocol And Mode Risks

- Existing output path tags event ID per packet rather than per physical event.
- Existing current/active controls do not yet implement the final explicit mode enum.
- Existing position block owns obsolete reset behavior and must be split/refactored so TDC-only does not wait for position packetization.
- Current CSR decode does not yet implement final external 16-bit map.

## Required Fixes Before Phase 1

None remaining after Builder fixes and Verifier recheck.

## Builder Response Summary

- Added CSR-width mismatch to `DECISIONS_LOG_MATRIX_TOP.md`.
- Added final-map/current-RTL warning to `12_FINAL_CSR_MAP_PROPOSAL.md`.
- Created `TOP/docs/reviews/REVIEW_MATRIX_TOP_PHASE0.md`.

## Signoff

- Verifier initial review: completed.
- Builder fixes: completed.
- Verifier recheck: PASS, no remaining findings in the requested recheck scope.
