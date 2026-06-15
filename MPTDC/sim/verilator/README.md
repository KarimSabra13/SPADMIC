# MPTDC Local Verilator Flow

This directory contains the local-only Verilator baseline used for timing
closure iterations. It is intended for syntax, lint, and directed digital smoke
coverage. It is not Genus, Innovus, Xcelium, CDC signoff, analog signoff, or
post-route timing evidence.

## Commands

From the repository root:

```bash
bash MPTDC/sim/verilator/run_lint.sh
bash MPTDC/sim/verilator/run_smoke.sh
```

Both scripts create a timestamped result directory:

```text
results/local_verilator/<RUN_ID>/
```

Each run records:

- `git_head.txt`
- `git_status.txt`
- `verilator_version.txt`
- `command_transcript.log`
- `lint.log`
- one log per smoke test
- `SUMMARY.md`

## Scope

The maintained product smoke set is intentionally focused:

- lint for `mptdc_axis_core`
- `tb_axis_core_product_smoke`

The old standalone VIP smoke set was retired with the product-only
`mptdc_axis_core` boundary.

## Lint Waivers

The lint command uses the same practical waivers as the existing repository
smoke flow for the mixed async/event RTL:

- `WIDTHEXPAND`
- `WIDTHTRUNC`
- `UNUSEDSIGNAL`
- `UNDRIVEN`
- `UNUSEDPARAM`
- `PINMISSING`
- `UNUSEDGENVAR`
- `CASEINCOMPLETE`
- `LATCH`
- `REALCVT`
- `INITIALDLY`
- `COMBDLY`
- `PINCONNECTEMPTY`
- `SYNCASYNCNET`
- `UNOPTFLAT`
- `DECLFILENAME`
- `VARHIDDEN`

These waivers keep Verilator usable for local structural and directed functional
checks. They do not waive Cadence synthesis, STA, CDC, or Xcelium findings.
