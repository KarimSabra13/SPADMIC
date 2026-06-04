# O10.2 Reset/Recovery Summary

REPORT_STATUS=REVIEW_REQUIRED

- Reset/recovery checks are reported separately in `timing_post_route_reset_recovery.rpt`.
- Do not broadly false-path resets without a documented protocol waiver.
- Review whether oscillator-domain clears release only while oscillators are idle and before restart.
