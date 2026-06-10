# O11 RO Liberty Shell Policy

## Current Shell

`MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib` remains the normal RO_tune4 shell.  Its `S` bus has:

```liberty
max_capacitance : 0.050;
```

The shell uses `capacitive_load_unit (1, pf)`, so this is a `50 fF` limit.  It is close to the strict analog D-load budget of `58.72 fF`.

## Experiment-Only Shells

O11 adds two optional shells:

- `MPTDC/syn/macros/RO_tune4_shell_load58ff.lib`
- `MPTDC/syn/macros/RO_tune4_shell_load76ff.lib`

They exist only for controlled experiments that ask whether a `58.72 fF` or `75.59 fF` limit changes tool behavior.  They are not used by the O11 report-only flow and are not a waiver for real routed load.

## Policy

- Do not silently replace `RO_tune4_real_abstract_shell.lib`.
- Do not use a larger shell limit to declare O10.2 or O11 load closed.
- Do not add buffers or dummy loads on RO outputs without analog/backend review.
- Treat any measured source-pin load above `150 fF` as a physical blocker until explained by O11 sink classification.

The immediate task is measurement and classification.  Liberty relaxation is only an experiment after the physical sink picture is understood.
