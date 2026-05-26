# MPTDC v2.7 — CSR Register Map and Usage

> - **Author:** Karim Sabra
> - **Purpose:** Document the active CSR block, register semantics, and expected control/status behavior.
> - **Scope:** Covers the software-visible interface of `rtl/readout/mptdc_csr_minimal.sv`.

## 1. Interface behavior

The active CSR block is `rtl/readout/mptdc_csr_minimal.sv`.

Bus signals:

```text
csr_valid_i   request valid
csr_write_i   1 = write, 0 = read
csr_addr_i    6-bit address
csr_wdata_i   32-bit write data
csr_ready_o   always 1 in the active implementation
csr_rvalid_o  registered read-valid pulse
csr_rdata_o   registered read data
```

Read timing model:

- the request is accepted when `csr_valid_i=1` and `csr_write_i=0`
- `csr_ready_o` is always `1`
- `csr_rvalid_o` pulses on the next `clk_sys` cycle
- `csr_rdata_o` is valid with that pulse

## 2. Register summary

| Addr | Name | R/W | Purpose |
|------|------|-----|---------|
| `0x00` | `CTRL` | R/W | arm level and self-clearing control pulses |
| `0x04` | `MODE` | R/W | reserved bit, input source, output format |
| `0x08` | `MAX_HITS` | R/W | max hits per conversion |
| `0x0C` | `WDT_CTX` | R/W | watchdog-class context/safety timeout field retained in the live config image |
| `0x10` | `WDT_GLOBAL` | R/W | system-domain global watchdog timeout |
| `0x20` | `STATUS` | R | readiness, busy state, context states, drain FSM state |
| `0x24` | `HIT_COUNT` | R | last hit count and last close flags |
| `0x28` | `FIFO_STATUS` | R | FIFO level/full/empty |
| `0x2C` | `WDT_STATUS` | R | global watchdog trip counter |
| `0x30` | `CONV_COUNT` | R | conversions completed |
| `0x34` | `OVF_COUNT` | R | rejected START count |

## 3. Control register details

### 3.1 `CTRL` (`0x00`)

```text
bit 0  conv_arm   latched level, readable
bit 1  fifo_clr   self-clearing pulse
bit 2  soft_rst   self-clearing pulse
```

Important semantics:

- `conv_arm` is not self-clearing by itself, but every write to `CTRL` rewrites bit `0`.
  So a write of `0x2` (`fifo_clr`) or `0x4` (`soft_rst`) also de-arms the design unless software writes `conv_arm=1` again afterward.
- `fifo_clr` is a one-cycle synchronous pulse in `clk_sys`.
- `soft_rst` is a one-cycle synchronous pulse in `clk_sys` and, in the current top-level implementation, resets the whole local `rst_n_internal` domain. That means `mptdc_core` and `mptdc_csr_minimal` both return to reset defaults, not just `conv_arm`.

Recommended usage:

- keep `conv_arm=1` for sustained operation
- after `fifo_clr`, explicitly re-arm if you want to resume conversions immediately
- after `soft_rst`, reprogram `MODE`, `MAX_HITS`, and watchdog registers because the local CSR block has been reset to defaults
- use `soft_rst` only when the design is idle or when forced recovery is required

### 3.2 `MODE` (`0x04`)

```text
bit 0    reserved   read-as-zero / ignored on write in the active v2.4 RTL
bit 1    input_sel  0 = SPAD inputs, 1 = CAL inputs
bit 3:2  out_mode   compatibility field; maintained RTL reads/emits RAW_FEATURES
```

Usage rule:

Do not change `input_sel` while a conversion is active. The `out_mode` field is
retained for legacy software compatibility, but the maintained v2.7 packet path
ignores writes and emits the fixed RAW_FEATURES feature packet.
If you want the minimum-latency fast-close behavior that older collateral called `FIRST_HIT`, use `MAX_HITS = 1`.

### 3.3 `MAX_HITS` (`0x08`)

```text
bit 3:0  max_hits
```

Live behavior:

- the design supports `1..15`
- `0` is treated as a disabled compare in the close logic, so use an explicit nonzero value in normal operation

### 3.4 `WDT_CTX` (`0x0C`)

```text
bit 15:0  wdt_ctx_timeout
```

Important semantic detail:

After the `clk_sys` control/context pivot, this field is still stored and passed
through the live config image, but it is not a clean fast-domain programmable
counter. `mptdc_meas_ctrl.sv` uses it only as part of watchdog-class close-flag
compatibility after the held image is evaluated, while the START-without-STOP
safety path is the slow-domain saturation latch in `mptdc_core.sv`.

Do not use `WDT_CTX` as a calibrated timeout unit in software until the desired
post-pivot packet/CSR semantics are explicitly redefined.

### 3.5 `WDT_GLOBAL` (`0x10`)

```text
bit 15:0  wdt_global_timeout
```

This timeout is consumed by `mptdc_watchdog.sv` in `clk_sys`, so the unit is one `clk_sys` cycle.

At `160 MHz`, one count is `6.25 ns`.

## 4. Status register details

### 4.1 `STATUS` (`0x20`)

```text
bit 0    ready
bit 1    busy
bit 3:2  ctx0_state
bit 5:4  ctx1_state
bit 7:6  drain_state
```

Context state encoding comes from `ctx_state_e`.

The active meanings are:

- `FREE`
- `CAPTURING`
- `DRAINING`

`ready` means:

- `conv_arm=1`
- not all contexts busy
- no active `start_latched` measurement ownership visible in `clk_sys`

`busy` means any of the following are true:

- a conversion is currently owned by the frontend
- a context is draining
- the drain FSM is not idle

### 4.2 `HIT_COUNT` (`0x24`)

```text
bit 3:0  last_hit_count
bit 7:4  last_flags
```

This reflects the most recently completed conversion seen at `drain_conv_done`.

### 4.3 `FIFO_STATUS` (`0x28`)

```text
bit [FIFO_LVL_W-1:0]  fifo_level
bit FIFO_LVL_W        fifo_full
bit FIFO_LVL_W+1      fifo_empty
```

In the current implementation, `fifo_empty` is derived from `~fifo_rd_valid`.

### 4.4 `WDT_STATUS` (`0x2C`)

```text
bit 7:0  wdt_global_trip_cnt
```

Only the global watchdog trip count is exposed in the active RTL.

### 4.5 `CONV_COUNT` (`0x30`)

```text
bit 31:0  conv_count
```

This increments when the drain FSM finishes a conversion (`drain_conv_done`).

### 4.6 `OVF_COUNT` (`0x34`)

```text
bit 15:0  ovf_count
```

This counts true rejected START events:

- START arrived while no context was free, or
- START arrived while `conv_arm=0`, or
- START arrived while another conversion was already active

It is not the same thing as hit saturation.

## 5. Shared-readout export note

The optional shared-readout export used by the active SPADMIC top is **not**
controlled through this CSR block. It is driven through the top-level ports:

- `shared_readout_en_i`
- `acq_ready_i`
- `acq_valid_o`
- `acq_data_o`

When `shared_readout_en_i = 1`, the internal FIFO is drained through the
acquisition-record export path instead of the local narrow serializer. The CSR
map itself does not change.

## 6. Typical configuration sequences

### 5.1 SPAD multi-hit collection

```text
1. Write MODE      : reserved[0]=0, input_sel=SPAD, out_mode=RAW_FEATURES
2. Write MAX_HITS  : 15
3. Write WDT_CTX   : 0 unless a post-pivot watchdog experiment explicitly needs the compatibility field
4. Write WDT_GLOBAL: sys-domain timeout value
5. Write CTRL      : conv_arm=1
6. Stream packets from the 16-bit output
```

### 5.2 Calibration collection

```text
1. Write MODE      : reserved[0]=0, input_sel=CAL, out_mode=RAW_FEATURES
2. Program MAX_HITS / watchdogs as needed
3. Write CTRL      : conv_arm=1
4. Apply external calibration START/STOP pulses
5. Capture packet stream and log raw features offline
```

## 7. Operational cautions

1. Keep `conv_arm` high if you want minimum deadtime between conversions.
2. Do not retarget `input_sel` during an active conversion.
3. Prefer `RAW_FEATURES` for silicon characterization and precision calibration.
4. Use `OVF_COUNT` to detect sustained throughput problems.
5. Use `WDT_STATUS` to detect global-stall recovery events.
