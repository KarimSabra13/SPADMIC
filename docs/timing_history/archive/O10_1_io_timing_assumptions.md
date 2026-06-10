# O10.1 IO Timing Assumptions

O10 post-route timing was dominated by external output delay paths on `acq_data_o`, not by the O9 residual `FAST_TAG_TO_PD_TS` paths.

For O10.1, IO timing is treated as a block-level assumption:

- Keep IO timing visible.
- Report IO paths separately from core internal timing where Innovus supports the report command.
- Do not hide oscillator/PD core timing behind output-delay artifacts.
- Do not claim IO timing closure from this feasibility run.

Open item for backend integration:

- Confirm whether `acq_data_o` has a real top-level IO timing budget or should be constrained as an internal block output for macro-level P&R.

O10.1 manager summaries must state that IO timing is still provisional.
