# O10.1 Manual GUI Screenshot Instructions

Automatic screenshot export may be unavailable in Innovus `-nowin` mode.

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
innovus -gui -init results/innovus/20260604_o10_1_innovus_repair/checkpoints/restore_latest.tcl
```

After restore, use the GUI to zoom full, enable desired layers, highlight RO/PD/phase nets if needed, and export manager PNGs manually.
