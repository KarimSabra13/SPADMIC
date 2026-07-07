# PVS DRC Real RO6 Evidence - 2026-07-07

This folder contains small text evidence only for the manual real-RO6 PVS DRC run.

Source manual assembly run:

```text
/sim/ksabra/SPADMIC_work/innovus/mptdc_manual_gui_streamout_realro6_20260707_165027
```

PVS DRC run directory:

```text
/sim/ksabra/SPADMIC_work/innovus/mptdc_manual_gui_streamout_realro6_20260707_165027/pvs_drc_realro6_20260707_01
```

Relevant assembly:

```text
OA top: MPTDC_GDS_REALRO6_20260707 / mptdc_axis_core / layout
Real RO local master: MPTDC_GDS_REALRO6_20260707 / RO_tune6 / layout
Original RO source: SPADMIC / RO_tune6 / layout
```

Included files in the original server folder:

```text
total 3.8M
-rw-r--r-- 1 ksabra validmgr  54K Jul  7 17:25 PIPO1.LOG
-rw-r--r-- 1 ksabra validmgr  56K Jul  7 17:25 PIPO1.OUT
-rw-r--r-- 1 ksabra validmgr    0 Jul  7  2026 README.md
-rw-r--r-- 1 ksabra validmgr    0 Jul  7 17:25 config.rul
-rw-r--r-- 1 ksabra validmgr  99K Jul  7 17:27 drcSummaryReport.txt
-rw-r--r-- 1 ksabra validmgr 599K Jul  7 17:27 mptdc_axis_core_drc.err
-rw-r--r-- 1 ksabra validmgr  99K Jul  7 17:27 mptdc_axis_core_drc.sum
-rw-r--r-- 1 ksabra validmgr  985 Jul  7 17:25 pvsdrcctl
-rw-r--r-- 1 ksabra validmgr 2.8M Jul  7 17:27 pvsuidrc.log
-rwxr-xr-x 1 ksabra validmgr  965 Jul  7 17:27 run.pvs
-rw-r--r-- 1 ksabra validmgr  113 Jul  7 17:25 technology.rul
```

The committed repository evidence intentionally contains only the small text
files that were actually added under this directory. In this checkout,
`pvsuidrc.log` is not present; use `PIPO1.LOG`, `mptdc_axis_core_drc.sum`,
`mptdc_axis_core_drc.err`, and `pvsdrcctl` for the committed triage record.

Excluded intentionally:

```text
mptdc_axis_core.oas
*.rdb
mptdc_axis_core_drc.err.pvstdb/
03_metal_drc_grep.txt
large generated databases/caches
```
