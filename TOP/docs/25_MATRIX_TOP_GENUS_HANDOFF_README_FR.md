# README handoff Genus matrix-top

Statut: document de handoff pour integration top/netlist. Ce document decrit
les blocs presents dans `/sim/ksabra/SPADMIC_work/handoff/genus`, leurs
connexions attendues, et les entrees/sorties principales du coeur digital
`spadmic_top_matrix_v1`.

Ce handoff n'est pas un wrapper pad-ring final, pas un PnR top route, pas une
validation timing MMMC, et pas un signoff. Il est suffisant comme base pour
assembler une netlist top de travail avec les macros/pads/stubs necessaires.

## Dossier handoff

Chemin serveur:

```text
/sim/ksabra/SPADMIC_work/handoff/genus
```

Fichiers attendus par bloc digital:

```text
<block>/<block>.postsyn.v
<block>/<block>.postsyn.sdc
```

Matrice de connectivite detaillee:

```text
TOP/docs/26_MATRIX_TOP_HANDOFF_CONNECTIVITY.csv
```

Vues lisibles derivees de la meme matrice:

```text
TOP/docs/26_MATRIX_TOP_HANDOFF_CONNECTIVITY_READABLE.md
TOP/docs/26_MATRIX_TOP_HANDOFF_CONNECTIVITY_EXCEL.csv
```

La matrice CSV source est le document machine-readable a copier dans le dossier
handoff serveur pour lever l'ambiguite que les `.postsyn.v/.sdc` seuls ne
resolvent pas: ports de chaque sous-bloc, connexions inter-blocs, pads, macros,
glue RTL, tieoffs et actions attendues dans le wrapper top final. Pour une
lecture humaine, utiliser de preference la vue Markdown ou le CSV Excel.

Blocs disponibles:

| Dossier | Module netlist | Role |
| --- | --- | --- |
| `matrix_reset_ctrl` | `spadmic_matrix_reset_ctrl` | Reset selectif des lignes matrice R/Y/B via Rz/Yz/Bz |
| `or64_tree` | `spadmic_matrix_or_tree` | Detection d'activite sur un bus 64 lignes |
| `position_snapshot` | `spadmic_position_snapshot_packetizer` | Packet position depuis snapshot R/Y/B |
| `matrix_cfg_ctrl` | `spadmic_matrix_cfg_ctrl` | Controle configuration matrice Din/Cin/Dout/Cout |
| `event_coordinator` | `spadmic_event_coordinator` | Sequencement d'un evenement complet |
| `event_bundle_tx` | `spadmic_event_bundle_tx` | Multiplex/bundle des packets TDC et position |
| `output_fifo` | `spadmic_output_fifo` | FIFO de sortie, 256 mots dans le top actif |
| `matrix_top_csr` | `spadmic_matrix_top_csr` | Registres CSR du matrix-top |
| `i2c_csr_bridge` | `spadmic_i2c_csr_bridge` | Pont transaction I2C vers bus CSR local |
| `i2c_slave` | `spadmic_i2c_slave` | Esclave I2C synchronise dans `clk_sys` |
| `ddr16_pairer` | `spadmic_ddr16_tx_pairer` | Regroupement 2 mots 16b vers interface DDR16 |
| `tdc3_frontend` | `spadmic_tdc3_frontend` | Glue synthetise autour des trois axes MPTDC avec `mptdc_axis_core` en black-box |
| `mptdc` | `mptdc` / macro handoff | Bloc MPTDC physique separe, a garder protege |

Note importante: `spadmic_tdc_axis_wrapper` n'est pas donne comme dossier
separe parce qu'il est maintenant emballe dans le handoff `tdc3_frontend`.
`tdc3_frontend` ne contient pas les internes MPTDC: chaque instance
`mptdc_axis_core` y est traitee comme black-box et doit etre liee au handoff
MPTDC physique separe. `spadmic_matrix_snapshot_frontend`, les synchroniseurs
reset, le wrapper clock/PLL, les pads, le BOX_RING, la matrice analogique et
les drivers SLVS ne sont pas tous des dossiers de handoff separes dans ce tree.
Ils restent du glue/top integration ou des macros a instancier dans le wrapper
final.

## Handoff TDC3 frontend

Le bloc `tdc3_frontend` est le plus simple moyen de ne pas perdre la
fonctionnalite de wrapper autour des MPTDC:

- un wrapper independant par axe `R`, `Y`, `B`;
- un `spadmic_ref_stop_qualifier` independant par axe;
- gating independant des signaux SPAD et calibration;
- mux calibration/SPAD conserve dans le `mptdc_axis_core` externe;
- backpressure et status packet separes par axe.

La convention d'axe est:

```text
index 0 = R
index 1 = Y
index 2 = B
```

Le runner dedie ne lit pas le RTL interne MPTDC. Il lit seulement
`mptdc_pkg.sv` et le stub black-box `mptdc_axis_core_blackbox.sv`, puis
synthesise le glue TOP:

```text
TOP/syn/scripts/run_genus_tdc3_frontend_handoff.sh
```

Sorties serveur attendues:

```text
/sim/ksabra/SPADMIC_work/handoff/genus/tdc3_frontend/tdc3_frontend.postsyn.v
/sim/ksabra/SPADMIC_work/handoff/genus/tdc3_frontend/tdc3_frontend.postsyn.sdc
/sim/ksabra/SPADMIC_work/handoff/genus/tdc3_frontend/HANDOFF_MANIFEST.txt
```

Le wrapper top final doit ensuite linker trois instances physiques externes de
`mptdc_axis_core` depuis le handoff MPTDC. Il ne faut pas resynthetiser ou
modifier le MPTDC pour generer ce glue.

## Vue top niveau

Le coeur digital actif est:

```text
TOP/rtl/spadmic_top_matrix_v1.sv
```

Il n'est pas le wrapper pad-ring final. Le wrapper final doit instancier:

- le coeur digital `spadmic_top_matrix_v1`;
- la macro matrice `matrice3`;
- les trois macros MPTDC physiques;
- le PLL et son mux/diviseur clock;
- les drivers SLVS: 16 data + 1 forwarded clock + 1 valid;
- les pads I2C, reset, clock, calibration, PLL-control et power;
- le BOX_RING/pad-ring custom.

Flux fonctionnel simplifie:

```text
Pads I2C/reset/clock/PLL/calibration
  -> wrapper pad/clock/PLL
  -> spadmic_top_matrix_v1

matrice3 R/Y/B
  -> or64_tree
  -> snapshot_frontend
  -> event_coordinator

event_coordinator
  -> matrix_reset_ctrl
  -> MPTDC R/Y/B wrappers
  -> position_snapshot_packetizer
  -> event_bundle_tx
  -> output_fifo_256
  -> ddr16_pairer
  -> 16 data SLVS + clock SLVS + valid SLVS
```

## Pads et IO top chip

### Pads externes digitaux ou controles

| Pad / groupe | Direction | Domaine | Connexion attendue |
| --- | --- | --- | --- |
| `VDD`, `VSS` | power | 1.8 V digital | Digital, PLL digital/control, MPTDC, arbiter/FIFO/TX |
| `AVDD`, `AVSS` | power | analog/matrice | Macro matrice et analog macro-owned |
| `async_rst_n` | input | 1.8 V | Reset global actif bas du coeur digital |
| `i2c_RST` | input | 1.8 V | Reset actif haut du transport I2C uniquement, mappe vers `i2c_rst_i` |
| `i2c_scl_i` | input | 1.8 V | Horloge I2C vers `spadmic_i2c_slave` |
| `i2c_sda_i` | input | 1.8 V | Donnee I2C entree vers `spadmic_i2c_slave` |
| `i2c_sda_oe_o` | output | 1.8 V | Enable open-drain SDA; le pad final force SDA bas quand OE=1 |
| `clk_160m_ext_i` | input | TBD pad type | Unique clock externe 160 MHz de secours/test |
| `cal_r_start_async_i` | input | 1.8 V | Calibration START axe R / MPTDC R |
| `cal_r_stop_async_i` | input | 1.8 V | Calibration STOP axe R / MPTDC R |
| `cal_y_start_async_i` | input | 1.8 V | Calibration START axe Y / MPTDC Y |
| `cal_y_stop_async_i` | input | 1.8 V | Calibration STOP axe Y / MPTDC Y |
| `cal_b_start_async_i` | input | 1.8 V | Calibration START axe B / MPTDC B |
| `cal_b_stop_async_i` | input | 1.8 V | Calibration STOP axe B / MPTDC B |
| `pll_Ibi_KVCO_i` | input | 1.8 V/TBD | Entree pad directe vers macro PLL |
| `pll_Icp_i` | input | 1.8 V/TBD | Entree pad directe vers macro PLL |
| `pll_Ref_in_pll_ro_i` | input | 1.8 V/TBD | Entree reference/RO PLL, type exact a confirmer |
| `pll_Rst_Div_i` | input | 1.8 V | Reset divider PLL, direct pad vers PLL |
| `pll_Rst_CP_i` | input | 1.8 V | Reset charge-pump PLL, direct pad vers PLL |
| `DATA[15:0]` | output SLVS | north row | 16 drivers SLVS data, depuis DDR16 pairer |
| `DATA_CLK` | output SLVS | north row | Driver SLVS forwarded clock, depuis `ddr_clk_o` |
| `DATA_VALID` | output SLVS | north row | Driver SLVS valid, depuis `ddr_pair_valid_o` |

Il n'y a pas de pads externes separes pour `clk_cfg_40m` et `clk_ref_40m` en
v1. Le wrapper clock derive les 40 MHz depuis le 160 MHz PLL ou depuis le 160
MHz externe divise par 4.

### Connexions internes macro, pas des pads digitaux

| Signal / groupe | Direction vue coeur digital | Connexion |
| --- | --- | --- |
| `R_i[63:0]`, `Y_i[63:0]`, `B_i[63:0]` | input | Sorties evenement de la matrice vers le digital |
| `Rz_o[63:0]`, `Yz_o[63:0]`, `Bz_o[63:0]` | output | Reset selectif actif bas vers matrice |
| `matrix_din_o[43:0]` | output | Donnees serie configuration colonnes matrice |
| `matrix_cin_o[43:0]` | output | Clock/strobe configuration colonnes matrice |
| `matrix_dout_i[43:0]` | input | Readback data depuis matrice |
| `matrix_cout_i[43:0]` | input | Readback/capture strobe depuis matrice |
| `VTUNE` | analog | Macro matrice, pas route digitale |
| `matrix_supplies` | power | Macro-owned jusqu'au handoff power final |

## IO du coeur digital actif `spadmic_top_matrix_v1`

| Port | Direction | Description |
| --- | --- | --- |
| `clk_sys` | input | Clock systeme digital principal |
| `clk_ref_40m` | input | Clock 40 MHz reference MPTDC/ref-stop |
| `clk_cfg_40m` | input | Clock 40 MHz configuration matrice |
| `async_rst_n` | input | Reset global actif bas |
| `i2c_rst_i` | input | Reset actif haut du transport I2C uniquement |
| `i2c_scl_i`, `i2c_sda_i` | input | Pins I2C apres pads |
| `i2c_sda_oe_o` | output | Enable open-drain pour pad SDA |
| `pll_lock_i` | input | Status PLL visible en CSR seulement |
| `pll_fint_sel_o[7:0]` | output | SelA_Fint..SelH_Fint vers PLL wrapper |
| `pll_ro_sw_o[4:0]` | output | Sw0_RO..Sw4_RO vers PLL wrapper |
| `pll_sel_pulse_pfd_o` | output | Controle PLL CSR |
| `pll_enable_div_o` | output | Controle divider PLL CSR |
| `pll_sel_40m_o` | output | Selection 40 MHz PLL CSR |
| `clk_160m_ext_select_o` | output | Selection PLL 160 MHz vs clock externe 160 MHz |
| `R_i/Y_i/B_i[63:0]` | input | Lignes evenement matrice |
| `Rz_o/Yz_o/Bz_o[63:0]` | output | Reset selectif actif bas matrice |
| `matrix_din_o/matrix_cin_o[43:0]` | output | Configuration matrice |
| `matrix_dout_i/matrix_cout_i[43:0]` | input | Readback matrice |
| `cal_*_async_i` | input | Six entrees calibration R/Y/B start/stop |
| `ddr_data_l_o[15:0]` | output | Demi-mot bas pour drivers DDR16 |
| `ddr_data_h_o[15:0]` | output | Demi-mot haut pour drivers DDR16 |
| `ddr_pair_valid_o` | output | Pulse valid pour une paire DDR16 |
| `ddr_clk_o` | output | Forwarded clock logique vers driver clock |

## Connexions bloc par bloc

### `i2c_slave` -> `i2c_csr_bridge` -> `matrix_top_csr`

Role: chemin de controle externe.

```text
i2c pads -> i2c_slave -> i2c_csr_bridge -> matrix_top_csr
```

`i2c_slave` recoit `i2c_scl_i`, `i2c_sda_i` et produit un canal transaction:
`txn_valid_o`, `txn_write_o`, `txn_addr_o`, `txn_wdata_o`. Il consomme les
reponses `txn_rsp_valid_i`, `txn_rsp_rdata_i`, `txn_rsp_err_i`. `i2c_sda_oe_o`
pilote l'open-drain du pad SDA.

`i2c_csr_bridge` transforme ce canal I2C en requetes CSR locales:
`csr_req_valid_o`, `csr_req_write_o`, `csr_req_addr_o`, `csr_req_wdata_o`.
Il renvoie la reponse CSR vers l'I2C avec `i2c_rsp_valid_o`,
`i2c_rsp_rdata_o`, `i2c_rsp_err_o`.

`matrix_top_csr` centralise les registres de controle/status:

- mode actif/demande, enable global, axis mask;
- parametres MPTDC communs: max hits, RO slow/fast code, reset soft, FIFO clear;
- masques calibration;
- configuration matrice: op, colonne, data 64b, status/readback;
- status snapshot/reset/event/FIFO/DDR;
- controles PLL CSR;
- selection clock 160 MHz externe vs PLL.

### `or64_tree`

Role: detection rapide d'activite sur chaque axe matrice.

```text
R_i[63:0] -> or64_tree -> r_matrix_event
Y_i[63:0] -> or64_tree -> y_matrix_event
B_i[63:0] -> or64_tree -> b_matrix_event
```

IO:

| Port | Direction | Description |
| --- | --- | --- |
| `lines_i[63:0]` | input | Une famille de lignes matrice |
| `event_o` | output | OR reduce hierarchique, indique au moins une ligne active |

Le top instancie trois fois ce bloc: R, Y, B.

### `spadmic_matrix_snapshot_frontend` glue top

Ce bloc n'a pas de dossier handoff separe dans le tree actuel. Il est quand
meme essentiel dans `spadmic_top_matrix_v1`.

Role: synchroniser/capturer un snapshot stable de `R/Y/B` avant que la matrice
soit resetee.

Entrees principales: `R_i/Y_i/B_i`, `required_direction_mask_i`,
`settle_cycles_i`, `watchdog_cycles_i`, `clear_i`.

Sorties principales: `snapshot_valid_o`, `snapshot_R/Y/B_o`, `busy_o`,
`timeout_o`, `overlap_o`, `reject_o`, `rearm_ready_o`.

Connexions:

```text
matrix R/Y/B -> snapshot_frontend
snapshot_frontend -> matrix_reset_ctrl
snapshot_frontend -> position_snapshot
snapshot_frontend -> matrix_top_csr status/readback
snapshot_frontend -> event_coordinator ack/rearm
```

### `matrix_reset_ctrl`

Role: generer les resets selectifs actifs bas de la matrice apres capture.

Entrees:

- `clk_sys`, `rst_n`;
- `enable_i`: autorise auto-reset;
- `start_i`: pulse de debut depuis `event_coordinator`;
- `reset_width_i[15:0]`: largeur du reset en cycles;
- `snapshot_R/Y/B_i[63:0]`: masque des pixels/lignes a reset.

Sorties:

- `Rz_o/Yz_o/Bz_o[63:0]`: resets actifs bas vers la matrice;
- `busy_o`, `done_o`, `disabled_o`: status vers CSR/event coordinator.

### `matrix_cfg_ctrl`

Role: programmer et relire la matrice via `Din/Cin/Dout/Cout`, avec CDC entre
`clk_sys` et `clk_cfg_40m`.

Entrees:

- `clk_sys`, `clk_cfg_40m`, `rst_sys_n`, `rst_cfg_n`;
- `cmd_start_i`, `cmd_op_i[2:0]`, `col_idx_i[5:0]`, `wdata_i[63:0]`;
- `matrix_dout_i[43:0]`, `matrix_cout_i[43:0]` depuis matrice.

Sorties:

- `matrix_din_o[43:0]`, `matrix_cin_o[43:0]` vers matrice;
- `busy_o`, `done_o`, `error_o`, `last_error_o[3:0]`;
- `rdata_o[63:0]`, `readback_valid_o`;
- `matrix_cfg_valid_o` pour status CSR.

Operations connues: write colonne 64b, read colonne 64b, global fill 0,
global fill 1.

### `event_coordinator`

Role: figer les masques d'un evenement, attendre les acknowledgements requis,
lancer reset et bundle, puis attendre rearm.

Entrees importantes:

- mode actif, enable global, axis mask;
- `matrix_activity_i` depuis OR trees;
- `cal_activity_i` depuis pads calibration;
- `pre_event_resources_ready_i` depuis top glue;
- `snapshot_valid_i`, `position_snapshot_captured_i`;
- `tdc_start_seen_i[2:0]`;
- `packet_pending_mask_i[3:0]`;
- `reset_done_i`, `bundle_done_i`, `rearm_ready_i`.

Sorties:

- `event_open_o`, `event_id_o[13:0]`, `event_id_valid_o`;
- `required_packet_mask_o[3:0]`: TDC R/Y/B + position;
- `required_tdc_mask_o[2:0]`;
- `required_reset_ack_mask_o[3:0]`, `observed_reset_ack_mask_o[3:0]`;
- `reset_start_o`, `bundle_start_o`;
- `accept_enable_o`, `rejected_not_ready_o`, `busy_o`, `idle_o`.

### `tdc3_frontend` et `mptdc`

Role: conserver le glue TOP autour des trois MPTDC sans resynthetiser les
internes MPTDC. Le handoff `tdc3_frontend` contient les trois wrappers R/Y/B et
les trois qualifiers de STOP. Le handoff `mptdc` reste un bloc/macro protege.
Les internes MPTDC ne doivent pas etre modifies au niveau TOP.

Dans le wrapper top final, le chemin attendu devient:

```text
R event -> tdc3_frontend[0] -> TDC R wrapper -> MPTDC R packet stream
Y event -> tdc3_frontend[1] -> TDC Y wrapper -> MPTDC Y packet stream
B event -> tdc3_frontend[2] -> TDC B wrapper -> MPTDC B packet stream
```

Entrees de `tdc3_frontend`:

- `clk_sys`, `clk_ref_40m`, `async_rst_n`;
- `global_enable_i`, `axis_enable_i[2:0]`;
- `spad_event_async_i[2:0]` depuis le front-end matrice;
- `cal_start_async_i[2:0]`, `cal_stop_async_i[2:0]`;
- `input_sel_i`: SPAD ou calibration;
- `conv_arm_i[2:0]`, `fifo_clr_i`, `soft_reset_i`;
- `max_hits_i`, `ro_slow_code_i`, `ro_fast_code_i`.

Sorties de `tdc3_frontend`:

- `pkt_valid_o[2:0]`, `pkt_ready_i[2:0]`;
- `pkt_data_o[3*NARROW_W-1:0]`, avec slices R=0, Y=1, B=2;
- `pkt_sop_o[2:0]`, `pkt_eop_o[2:0]`;
- `packet_active_o[2:0]`, `packet_pending_o[2:0]`;
- `ready_o[2:0]`, `busy_o[2:0]`, `fifo_full_o[2:0]`;
- `stop_armed_o[2:0]`.

Le netlist engineer doit donc instancier `tdc3_frontend.postsyn.v` puis linker
les trois black-box `mptdc_axis_core` vers le handoff MPTDC physique.

### `position_snapshot`

Role: produire un packet position depuis le snapshot matrice. Il peut envoyer
le snapshot brut ou des clusters selon `mode_i`.

Entrees:

- `clk_sys`, `rst_n`;
- `start_i` depuis le top/event flow;
- `mode_i`, `event_id_i`;
- `snapshot_R/Y/B_i[63:0]`;
- `gap_threshold_i`, `min_cluster_span_i`.

Sorties:

- `pkt_valid_o`, `pkt_ready_i`, `pkt_data_o[15:0]`, `pkt_sop_o`, `pkt_eop_o`;
- `packet_pending_o`, `busy_o`;
- `snapshot_captured_o`: ack pour event/reset sequencing;
- `done_o`, `drop_o`.

Connexion:

```text
snapshot_frontend -> position_snapshot -> event_bundle_tx source POSITION
```

### `event_bundle_tx`

Role: transmettre un bundle deterministe pour un evenement donne. Il prend les
packets TDC R/Y/B et position, applique les masques requis, patch l'ID TDC dans
les headers TDC, remplace le dernier mot par l'event ID, puis ajoute un flush.

Entrees:

- `bundle_start_i`;
- `required_packet_mask_i[3:0]`;
- `source_pending_mask_i[3:0]`;
- `event_id_i[13:0]`;
- `src_valid_i[3:0]`, `src_data_i[4][15:0]`, `src_sop_i[3:0]`, `src_eop_i[3:0]`;
- `word_ready_i` depuis FIFO.

Sorties:

- `src_ready_o[3:0]`;
- `word_valid_o`, `word_data_o[15:0]`;
- `flush_o`;
- `completed_packet_mask_o[3:0]`;
- `done_o`, `busy_o`, `idle_o`, `missing_source_error_o`.

Source order logique: TDC R/X, TDC Y, TDC B/Z, puis position.

### `output_fifo`

Role: absorber les mots du bundle avant la sortie DDR16. Dans le top actif la
FIFO utilise `SPADMIC_OUTPUT_FIFO_DEPTH = 256`.

Entrees:

- `clk_sys`, `rst_n`;
- `push_valid_i`, `push_data_i`;
- `pop_ready_i`.

Sorties:

- `push_ready_o`;
- `pop_valid_o`, `pop_data_o`;
- `level_o`, `free_words_o`;
- `empty_o`, `full_o`, `almost_full_o`, `overflow_o`.

Dans `spadmic_top_matrix_v1`, la largeur est `NARROW_W+1`: le bit supplementaire
marque un flush interne vers le pairer DDR16.

### `ddr16_pairer`

Role: regrouper deux mots 16b single-edge en une paire DDR pour les drivers
SLVS. Si un flush arrive avec un demi-mot en attente, le second demi-mot est
padde a zero.

Entrees:

- `clk_sys`, `rst_n`;
- `word_valid_i`, `word_data_i[15:0]`;
- `flush_i`.

Sorties:

- `word_ready_o`;
- `ddr_data_l_o[15:0]`, `ddr_data_h_o[15:0]`;
- `ddr_pair_valid_o`;
- `ddr_padded_o`;
- `ddr_clk_o`;
- `busy_o`, `empty_o`.

Le wrapper final connecte ces sorties aux 16 drivers data SLVS, au driver clock
forwarded et au driver valid.

## Vue ASCII top du chip

Le dessin ci-dessous est une vue planning/top-integration. Il n'est pas a
l'echelle exacte et ne remplace pas le BOX_RING, le DEF, le LEF, ni le floorplan
Innovus. Il sert a montrer les connexions attendues entre pads, macros et
blocs de handoff.

Legende:

```text
[PAD]       pad externe ou driver IO
[MACRO]     macro physique analog/mixed-signal ou bloc MPTDC protege
[CORE]      logique du coeur digital spadmic_top_matrix_v1
[HANDOFF]   bloc present comme netlist/SDC dans handoff/genus
[GLUE]      logique top/wrapper non livree comme dossier handoff separe
-->         data/control principal
==>         bus large ou flux packet/DDR
~~~>        clock/reset/control wrapper
<-->        connexion bidirectionnelle ou handshake
```

```text
                                      N O R T H   /   top pad row
        +------------------------------------------------------------------------------------------+
        | [PAD/SLVS] DATA[15:0]             [PAD/SLVS] DATA_CLK        [PAD/SLVS] DATA_VALID       |
        |      ^                                  ^                         ^                      |
        |      | 16 lanes                         | forwarded clock          | pair valid           |
        |      | ddr_data_l_o[15:0]               | ddr_clk_o                | ddr_pair_valid_o     |
        |      | ddr_data_h_o[15:0]               |                          |                      |
        +======|==================================|==========================|======================+
        |      |                                  |                          |                      |
        |      |          north output corridor: route short and direct to SLVS drivers             |
        |      |                                  |                          |                      |
        |  +---v--------------------------------------------------------------------------------+  |
        |  | [CORE] output north-east cluster                                                   |  |
        |  |                                                                                    |  |
        |  | [HANDOFF] event_bundle_tx  ==> [HANDOFF] output_fifo_256 ==> [HANDOFF] ddr16_pairer|  |
        |  |      ^                         ^ level/full/overflow        ^ flush/word stream      |  |
        |  |      |                         |                             |                       |  |
        |  |      | completed_packet_mask    | CSR status                  |                       |  |
        |  +------|-------------------------|-----------------------------|-----------------------+  |
        |         |                         |                             |                          |
        |         |                         |                             |                          |
        |  +------|--------------------------------------------------------------------------------+|
        |  |      |        [CORE] event and packet assembly zone                                   ||
        |  |      |                                                                                ||
        |  |  [HANDOFF] event_coordinator                                                         ||
        |  |      | event_id[13:0], required_packet_mask[3:0], required_tdc_mask[2:0]              ||
        |  |      | reset_start, bundle_start, accept/reject, observed_reset_ack_mask             ||
        |  |      |                                                                                ||
        |  |      +--> [HANDOFF] position_snapshot_packetizer                                      ||
        |  |      |       input: snapshot_R/Y/B[63:0], event_id, position mode                   ||
        |  |      |       output: POSITION pkt_valid/data/sop/eop/pending                       ||
        |  |      |                                                                                ||
        |  |      +--> [HANDOFF] tdc3_frontend with three MPTDC wrapper slices                    ||
        |  |              TDC_R pkt_valid/data/sop/eop/pending                                    ||
        |  |              TDC_Y pkt_valid/data/sop/eop/pending                                    ||
        |  |              TDC_B pkt_valid/data/sop/eop/pending                                    ||
        |  +--------------------------------------------------------------------------------------+|
        |                                                                                          |
        |  +-----------------------------------+        +-----------------------------------------+ |
        |  | [MACRO] matrice3                 |        | [MACRO] MPTDC_R top                      | |
        |  | left / center-left               |        | full boundary planning: 1061.20 x 801.92 | |
        |  | AVDD/AVSS, VTUNE macro-owned     |        | plus 5 percent dimension margin + halo   | |
        |  |                                   |        |                                         | |
        |  | outputs to digital:               | R_i -->| [HANDOFF] tdc3_frontend R slice          | |
 WEST   |  |   R_i[63:0] --------------------+|        | input: spad_event_async_i, cal_r_*       | | EAST
 left   |  |   Y_i[63:0] -------------------+||        | output: TDC_R packet stream              | | right
 side   |  |   B_i[63:0] ------------------+|||        +-----------------------------------------+ | side
        |  |                                   |||                                                        |
        |  | resets from digital:              |||      +-----------------------------------------+ |
        |  |   Rz_o[63:0] <-------------------+||      | [MACRO] MPTDC_Y middle                   | |
        |  |   Yz_o[63:0] <--------------------+|      | same orientation as R/B if possible       | |
        |  |   Bz_o[63:0] <---------------------+      |                                         | |
        |  |                                   | Y_i -->| [HANDOFF] tdc3_frontend Y slice          | |
        |  | matrix config/readback:           |        | input: spad_event_async_i, cal_y_*       | |
        |  |   Din[43:0] <--- matrix_din_o     |        | output: TDC_Y packet stream              | |
        |  |   Cin[43:0] <--- matrix_cin_o     |        +-----------------------------------------+ |
        |  |   Dout[43:0] --> matrix_dout_i    |                                                  |
        |  |   Cout[43:0] --> matrix_cout_i    |        +-----------------------------------------+ |
        |  +-----------------|-----------------+        | [MACRO] MPTDC_B bottom                   | |
        |                    |                          | same orientation, close to R/Y           | |
        |                    |                          |                                         | |
        |                    |                    B_i -->| [HANDOFF] tdc3_frontend B slice          | |
        |                    |                          | input: spad_event_async_i, cal_b_*       | |
        |                    |                          | output: TDC_B packet stream              | |
        |                    |                          +-----------------------------------------+ |
        |                    |                                                                        |
        |  +-----------------v------------------------------------------------------------------+   |
        |  | [CORE] matrix front-end and control, physically close to matrix pin corridors      |   |
        |  |                                                                                    |   |
        |  | R_i/Y_i/B_i ==> [GLUE] snapshot_frontend ==> snapshot_R/Y/B[63:0]                 |   |
        |  |       |                 |        |         \                                      |   |
        |  |       |                 |        |          +--> [HANDOFF] position_snapshot    |   |
        |  |       |                 |        +------------> [HANDOFF] matrix_reset_ctrl     |   |
        |  |       |                 |                         outputs Rz/Yz/Bz            |   |
        |  |       |                 +---------------------> CSR snapshot/status              |   |
        |  |       |                                                                    |       |   |
        |  |       +--> [HANDOFF] or64_tree R/Y/B --> r/y/b_matrix_event ---------------+       |   |
        |  |                                                                                    |   |
        |  | [HANDOFF] matrix_cfg_ctrl                                                        |   |
        |  |     clk_sys <-> clk_cfg_40m CDC                                                   |   |
        |  |     CSR cmd/op/col/wdata --> matrix_din_o/matrix_cin_o                            |   |
        |  |     matrix_dout_i/matrix_cout_i --> rdata/status/errors                           |   |
        |  +------------------------------------------------------------------------------------+   |
        |                                                                                          |
        |  +------------------------------------------------------------------------------------+  |
        |  | [CORE] control south / CSR / clock-status zone                                      |  |
        |  |                                                                                    |  |
        |  | [PAD] i2c_scl_i ----+                                                              |  |
        |  | [PAD] i2c_sda_i ----+--> [HANDOFF] i2c_slave <--> [HANDOFF] i2c_csr_bridge          |  |
        |  | [PAD] i2c_RST  ~~~~~+       reset only I2C transport          |                     |  |
        |  |                                                           CSR req/rsp                |  |
        |  |                                                               v                     |  |
        |  |                         [HANDOFF] matrix_top_csr                                    |  |
        |  |                         mode, axis mask, reset cfg, matrix cfg,                    |  |
        |  |                         MPTDC cfg, PLL cfg, FIFO/TX/status                         |  |
        |  +------------------------------------------------------------------------------------+  |
        |                                                                                          |
        |  +-----------------------------+       +----------------------------------------------+  |
        |  | [MACRO] PLL / analog cluster |       | [GLUE] clock wrapper and mux/divider          |  |
        |  | bottom region               |       |                                              |  |
        |  | external pads direct to PLL:|       | reset default: PLL 160 MHz selected           |  |
        |  |   pll_Ibi_KVCO_i            |       | CSR select: clk_160m_ext_select_o             |  |
        |  |   pll_Icp_i                 |       | clk_160m_ext_i -> mux -> clk_sys              |  |
        |  |   pll_Ref_in_pll_ro_i       |       | 160 MHz / 4 -> clk_cfg_40m and clk_ref_40m    |  |
        |  |   pll_Rst_Div_i             |       | PLL lock -> pll_lock_i -> CSR only            |  |
        |  |   pll_Rst_CP_i              |       | PLL controls from CSR:                        |  |
        |  | CSR outputs to PLL wrapper: |       |   pll_fint_sel_o[7:0]                         |  |
        |  |   pll_fint_sel_o[7:0]       |       |   pll_ro_sw_o[4:0]                            |  |
        |  |   pll_ro_sw_o[4:0]          |       |   pll_sel_pulse_pfd_o                         |  |
        |  |   pll_enable_div_o          |       |   pll_enable_div_o, pll_sel_40m_o             |  |
        |  +-----------------------------+       +----------------------------------------------+  |
        +==========================================================================================+
        | SOUTH pads/control row: async_rst_n, clk_160m_ext_i, i2c_scl_i, i2c_sda_i, i2c_RST,      |
        | PLL external controls, digital VDD/VSS. Calibration pads cal_r/y/b_start/stop are TBD   |
        | side/order and are drawn logically; final placement belongs to pad-ring/layout owner.    |
        +------------------------------------------------------------------------------------------+
                                      S O U T H   /   bottom pad row
```

### Vue ASCII des flux internes du coeur digital

Cette deuxieme vue est plus logique que physique. Elle montre les connexions a
respecter lorsque les netlists de handoff sont assemblees avec les macros et le
wrapper final.

```text
                    +----------------------------------------------------------+
                    | wrapper chip final                                      |
                    | pads + BOX_RING + PLL + matrix + SLVS drivers           |
                    +-------------------------------+--------------------------+
                                                    |
                                                    v
        +--------------------------------------------------------------------------------+
        | [CORE] spadmic_top_matrix_v1                                                    |
        |                                                                                |
        |  Reset/clock                                                                    |
        |  ----------                                                                    |
        |  async_rst_n --> reset sync --> rst_sys_n, rst_cfg_n                            |
        |  i2c_RST -----> reset sync --> rst_i2c_n only                                   |
        |  clk_sys, clk_cfg_40m, clk_ref_40m come from wrapper clock/PLL                  |
        |                                                                                |
        |  Control path                                                                   |
        |  ------------                                                                  |
        |  i2c_scl_i/i2c_sda_i                                                           |
        |      --> i2c_slave                                                             |
        |      --> i2c_csr_bridge                                                        |
        |      --> matrix_top_csr                                                        |
        |          | mode/global_enable/axis_mask                                        |
        |          | tdc_max_hits, ro_slow_code, ro_fast_code, soft_reset, fifo_clr       |
        |          | matrix_cfg command/data                                             |
        |          | PLL control bits and clock-source select                            |
        |          | status counters/faults                                              |
        |                                                                                |
        |  Matrix event path                                                              |
        |  -----------------                                                             |
        |  matrice3 R_i/Y_i/B_i[63:0]                                                     |
        |      --> 3x or64_tree --> matrix_activity                                      |
        |      --> snapshot_frontend --> snapshot_R/Y/B[63:0]                             |
        |          |--> event_coordinator reset ack                                      |
        |          |--> matrix_reset_ctrl --> Rz/Yz/Bz[63:0] back to matrice3             |
        |          |--> position_snapshot --> POSITION packet source                     |
        |          +--> matrix_top_csr snapshot/status                                   |
        |                                                                                |
        |  Matrix config path                                                             |
        |  ------------------                                                            |
        |  matrix_top_csr command                                                        |
        |      --> matrix_cfg_ctrl                                                       |
        |      --> matrix_din_o[43:0], matrix_cin_o[43:0] to matrice3                    |
        |      <-- matrix_dout_i[43:0], matrix_cout_i[43:0] from matrice3                |
        |      <-- readback/status/error to matrix_top_csr                               |
        |                                                                                |
        |  MPTDC / calibration path                                                       |
        |  ------------------------                                                      |
        |  event_coordinator + matrix events + cal_r/y/b_start/stop                      |
        |      --> tdc3_frontend                                                         |
        |      --> 3x spadmic_tdc_axis_wrapper                                           |
        |      --> 3x MPTDC protected macro/block                                        |
        |      --> TDC_R/TDC_Y/TDC_B packet streams                                      |
        |                                                                                |
        |  Output path                                                                    |
        |  -----------                                                                   |
        |  TDC_R/TDC_Y/TDC_B packets + POSITION packet                                   |
        |      --> event_bundle_tx                                                       |
        |      --> output_fifo_256                                                       |
        |      --> ddr16_pairer                                                          |
        |      --> ddr_data_l_o[15:0], ddr_data_h_o[15:0], ddr_clk_o, ddr_pair_valid_o   |
        |      --> wrapper SLVS data/clock/valid drivers                                 |
        +--------------------------------------------------------------------------------+
```

## Ordre d'integration recommande

1. Verifier que les fichiers netlist/SDC de chaque dossier sont presents.
2. Instancier les blocs de controle I2C/CSR.
3. Connecter les signaux macro matrice: R/Y/B, Rz/Yz/Bz, Din/Cin/Dout/Cout.
4. Ajouter le glue `snapshot_frontend` s'il n'est pas absorbe dans un top netlist
   genere.
5. Instancier `tdc3_frontend`, puis linker ses trois black-box
   `mptdc_axis_core` vers les macros MPTDC protegees.
6. Connecter `position_snapshot`, `event_bundle_tx`, `output_fifo`,
   `ddr16_pairer`.
7. Ajouter le wrapper PLL/clock: une entree externe 160 MHz seulement, pas de
   pads externes 40 MHz separes.
8. Ajouter les pads et drivers SLVS dans le wrapper final.
9. Relancer une elaboration top complete avec stubs/macro models pour verifier
   tous les noms de ports.

## Points a ne pas sur-interpreter

- Les netlists sont propres pour integration top/netlist, mais pas pour signoff.
- Les SDC sont OOC et doivent etre reconciles au niveau top.
- Les avertissements OOC de type missing external delay sont attendus.
- Les clocks 40 MHz sont des clocks internes wrapper/core, pas des pads externes.
- La matrice, le PLL, les drivers SLVS, le BOX_RING et les pads restent sous la
  responsabilite du wrapper top/custom layout.
- Les internes MPTDC restent proteges.
- `tdc3_frontend` est un handoff de glue seulement; il ne remplace pas le
  handoff physique `mptdc_axis_core`.
