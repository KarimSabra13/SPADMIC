# MPTDC Calibration Flow

Author: Karim Sabra

Calibration reconstructs timing from the fixed MPTDC packet fields.  Cleanup
must not change the packet format, raw tag interpretation, or calibration
semantics.

## Active Commands

Run characterization:

```bash
bash MPTDC/scripts/sim/run_mptdc_characterization.sh
```

Run calibration:

```bash
bash MPTDC/scripts/calibration/run_mptdc_calibration.sh
```

Run a reconstruction check:

```bash
bash MPTDC/scripts/calibration/run_mptdc_reconstruction_check.sh
```

Outputs are written under `work/characterization/<run_id>/` and
`work/calibration/<run_id>/`.

## Active Assumptions

- Fixed packet format.
- Local fast raw tag encoding.
- Slow Johnson epoch.
- Typical R750_delta5 timing constants when the typical closure mode is used.
- Characterization datasets generated after the selected RTL and physical
  timing model are fixed.

## Required Rerun Points

Characterization and calibration must be rerun after:

- Final phase-buffer topology changes.
- Final analog phase behavior updates.
- Any packet field change, which is currently prohibited for cleanup.
- Any reconstruction feature change.
- Any final extracted timing model update.

## Retention

Keep compact manifests and summaries in git.  Keep large CSVs, model artifacts,
plots, and scratch outputs under `work/` or external storage.
