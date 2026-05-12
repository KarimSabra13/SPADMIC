# ASIC RTL Current-State Specification and Dataset Report

**Source used for final PDF:** `rtl_current_state_spec.tex`

This is the polished A4 specification package generated from the SPADMIC RTL database. The final PDF intentionally uses a controlled LaTeX layout for professional margins, wrapping, headers, footers, and long tables.

## Executive Summary

The active chip-level digital RTL top is `spadmic_top_v1`. It integrates the I2C/CSR control plane, global requested-to-active sequencing, three `mptdc_top_asic` TDC axes, shared TDC readout, position capture, correlated packet export, and the 8-bit source-synchronous DDR TX interface.

The current RTL is structured and substantially documented, but it is not a final mixed-signal signoff package. Open items include oscillator-domain STA, PLL/SPAD/oscillator macro contracts, CDC waiver proof, DDR output timing, and verification coverage closure.

## Generated Package

| File | Role |
| --- | --- |
| `rtl_current_state_spec.pdf` | Final professional A4 PDF report |
| `rtl_current_state_spec.tex` | LaTeX source used to build the PDF |
| `rtl_current_state_spec.md` | Markdown companion summary |
| `rtl_extracted_dataset.json` | Machine-readable extracted dataset |
| `rtl_extracted_dataset.csv` | CSV extraction dataset |
| `extraction_notes.md` | Build/extraction notes |

## Key Counts

- RTL modules analyzed: 36
- TOP-visible registers extracted: 48
- Modes extracted: 13
- Testbenches inventoried: 35
- Open issues tracked: 8

For full register maps, bitfields, interfaces, modes, metrics, risks, and traceability, use the PDF and LaTeX source.
