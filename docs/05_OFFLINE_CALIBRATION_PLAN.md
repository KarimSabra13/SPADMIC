# MPTDC v2.0 — Offline Calibration Plan

## Overview

All calibration in MPTDC v2.0 is performed **offline** on a PC. The silicon outputs raw features only — no on-chip LUT, ridge regression, or averaging. This simplifies the ASIC, reduces area, and allows calibration algorithm updates without silicon respin.

## Raw Features Extracted Per Hit

| Feature | Width | Description |
|---------|-------|-------------|
| nslow | 7 bits | Slow oscillator revolution count |
| nfast | 7 bits | Fast oscillator revolution count |
| ns | 4 bits | Slow phase index (0-8) |
| nf | 4 bits | Fast phase index (0-8) |
| pd_idx | 7 bits | Flat PD cell index (0-80) |
| event_seq | 4 bits | Hit sequence number within conversion |
| phase0_snap | 1 bit | Boundary phase snapshot (in header) |

## Calibration Workflow

### Phase 1: Silicon Characterization

1. **Setup**: Connect precision pulse generator to `cal_start` and `cal_stop` pads
2. **Configure**: Set CSR `input_sel=CAL`, `mode=MULTI_HIT`, `out_mode=RAW_FEATURES`
3. **Sweep**: Inject known time differences from 0 to 32 ns in ~10 ps steps
4. **Collect**: For each delay, perform 100+ conversions to build statistics
5. **Store**: Save raw feature CSVs: `(t_known, nslow, nfast, ns, nf, pd_idx, event_seq, phase0_snap)`

### Phase 2: PVT Characterization

Repeat Phase 1 at multiple operating conditions:
- **Temperature**: -40°C, 25°C, 85°C, 125°C
- **Voltage**: V_nom ± 10%
- **Process**: Multiple die from different wafer positions

### Phase 3: Model Fitting

1. **Dual-class split**: Separate data by `phase0_snap` (0 vs 1) — the two boundary classes have different correction profiles
2. **Feature engineering**: Compute interaction terms if needed
3. **Ridge regression**: Fit `t_corrected = α₀ + α₁·nslow + α₂·nfast + α₃·ns + α₄·nf + ... + residual`
4. **Validation**: Cross-validate, compute RMS error per class
5. **Export**: Store coefficient tables indexed by (PVT condition, phase0_snap class)

### Phase 4: Runtime Correction

During SPAD matrix operation:
1. TDC streams raw features via 16-bit bus
2. PC (or FPGA) receives packets, extracts features
3. Apply stored coefficients: `t_corrected = Σ(αᵢ × featureᵢ)`
4. Output corrected timestamps

### Phase 5: Re-characterization

Periodically (daily/weekly/on temperature change):
1. Switch to CAL mode
2. Inject reference pulses
3. Collect fresh raw data
4. Re-fit or verify existing coefficients
5. Update if drift exceeds threshold

## Why Offline?

| Aspect | On-chip (v1) | Offline (v2) |
|--------|-------------|-------------|
| Area | 2898-word LUT + precision pipe | Zero calibration area |
| Flexibility | Fixed ridge model | Any algorithm (ML, splines, etc.) |
| PVT adaptation | Requires silicon re-characterization | Easy re-fit from new data |
| Accuracy | Limited by LUT resolution | Unlimited precision on PC |
| Algorithm updates | Requires respin | Software update only |
| Debug visibility | Opaque | Full access to raw data |

## Data Rate Considerations

At maximum throughput (15 hits, RAW_FEATURES mode):
- Packet size: 47 words × 16 bits = 752 bits
- At 160 MHz with no backpressure: ~47 cycles per packet → ~3.4 Mconversions/s
- For SPAD matrix with 1 MHz event rate: easily sufficient
- For burst calibration sweeps: ~3200 delays × 100 reps = 320K packets in ~94 ms

## CSV Output Format (PC-side)

```csv
conv_id,hit_seq,t_known_ps,nslow,nfast,ns,nf,pd_idx,phase0_snap,ctx_id,flags
0,0,5000,11,12,3,4,31,0,0,0x0
0,1,5000,11,12,5,6,51,0,0,0x0
1,0,5010,11,12,3,5,32,0,1,0x0
...
```
