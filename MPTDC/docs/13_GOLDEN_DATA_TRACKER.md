# MPTDC Golden Data Tracker — rapport SPADMIC

Ce fichier est la checklist de lundi. Tant que les cases ci-dessous ne sont pas remplies avec des chiffres issus de la campagne sous `/sim/ksabra`, aucune réécriture finale du rapport ne doit commencer.

## Décisions figées avant campagne

- [x] Ne publier que la nouvelle architecture prouvée ; les chiffres legacy de deadtime à quelques ns sont invalides pour le rapport final.
- [x] Décrire le RTL actif tel qu’il est écrit, y compris les modifications faites pour satisfaire les contraintes de timing.
- [x] Conserver le terme `fast_clear`, mais l’expliquer comme mécanisme de nettoyage rapide/ordonné après sécurisation de l’image de mesure.
- [x] Utiliser `RAW_FEATURES` comme mode principal de caractérisation.
- [x] Inclure `stop_phase_disc` dans la clé de calibration si le RTL/protocole actif l’exporte.
- [x] Ne pas cacher `nslow == 0` : analyser séparément all-row, core `nslow > 0`, et non-core `nslow == 0`.
- [x] Limiter l’étude de moyennage publiée à `N <= 15`.
- [x] Mentionner les SVA seulement brièvement, comme aides de debug protocol/handshake.
- [x] Considérer le jitter analogique cible autour de 800 fs RMS par tap, tout en notant que les plusargs actuels sont entiers en ps.

## Commande de lancement recommandée

Script dans le repo :

```bash
MPTDC/scripts/sim/mptdc_weekend_golden_run.sh
```

Utilisation recommandée depuis le repo SPADMIC ou `SPADMIC/MPTDC` :

```bash
chmod +x MPTDC/scripts/sim/mptdc_weekend_golden_run.sh

RUN_TAG=mptdc_golden_weekend_20260522 \
OUT_ROOT=/sim/ksabra/mptdc_golden_weekend_20260522 \
JOBS=24 \
SIM=xrun \
JITTER_SIGMA_PS=1 \
JITTER_BOUND_PS=3 \
bash MPTDC/scripts/sim/mptdc_weekend_golden_run.sh
```

Paramètres lourds par défaut :

| Paramètre | Valeur |
|---|---:|
| Train seeds | 128 |
| Validation seeds | 32 |
| Conversions par seed | 200000 |
| Fixed-delay seeds | 24 |
| Fixed-delay conversions par seed | 10000 |
| VIP seeds | 128 |
| VIP conversions/test | 20000 |
| Jobs parallèles | 24 |

Note : le jitter `1 ps` est une approximation conservatrice de `800 fs` car le modèle actuel lit `OSC_JITTER_SIGMA_PS` comme entier.

Les rapports sweep/alias générés automatiquement sont volontairement échantillonnés pour éviter une explosion mémoire sur les campagnes à centaines de millions de lignes. Les métriques RMSE report-grade doivent être prises dans le rapport de calibration chunké `calibration_stop_disc/calibration_report.json`.

## Périmètre de données à remplir lundi

### 1. Traçabilité de campagne

- [ ] Chemin racine `/sim/ksabra/...` :
- [ ] Commit Git exact :
- [ ] Simulateur et version :
- [ ] Nombre de jobs réellement utilisés :
- [ ] Date de début / fin :
- [ ] Espace disque consommé :
- [ ] Statut global : PASS / FAIL / PARTIAL
- [ ] Logs principaux à archiver :
- [ ] Valeur `SWEEP_ANALYZE_MAX_FILES` :
- [ ] Valeur `CAL_HELDOUT_MAX_FILES` :
- [ ] Valeur `ALIAS_MAX_FILES_PER_DELAY` :

### 2. Protocole et observables

- [ ] Confirmer que `RAW_FEATURES` exporte `stop_phase_disc` dans le paquet actif.
- [ ] Confirmer que TOP/shared readout conserve `stop_phase_disc` jusqu’au flux final.
- [ ] Confirmer les champs CSV présents : `nslow`, `nfast_hit`, `ns`, `nf`, `phase0_snap`, `slow_boundary_inc`, `stop_phase_disc`, `hit_idx`, `Tref_ps`, `t_raw_ps`.
- [ ] Confirmer le nombre de lignes où `stop_phase_disc` est présent et non nul.
- [ ] Confirmer le traitement des éventuelles lignes malformées ou CSV vides.

### 3. Calibration LUT STOP-discriminator

Source attendue : `characterization/analysis/calibration_stop_disc/calibration_report.json`.

- [x] Clé LUT exacte : `(ns_inf, nf_inf, nslow, nfast_hit, stop_phase_disc, phase0_snap, hit_idx)`.
- [x] Nombre de fichiers train : 64 seeds/fichiers CSV.
- [x] Nombre de fichiers validation : 1 fichier held-out (`seed_100000.csv`) + 32 fichiers fresh validation.
- [x] Lignes train avant filtre : 192 000 000.
- [x] Lignes train après filtre : 181 624 425 (`nslow > 0`), soit 10 375 575 lignes retirées (5,404 %).
- [x] Lignes validation avant filtre : held-out 3 000 000 ; fresh 96 000 000.
- [x] Lignes validation après filtre : held-out 2 835 090 ; fresh 90 810 660.
- [x] Nombre de bins LUT : 13 195.
- [ ] Population min / médiane / max par bin : médiane 11 180 ; min/max à extraire si nécessaire du fichier LUT.
- [x] Taux de couverture LUT validation : held-out 2 835 073 / 2 835 090 = 99,9994 % ; fresh 90 810 228 / 90 810 660 = 99,9995 %.
- [x] Nombre de lignes validation sans entrée LUT : held-out 17 ; fresh 432.
- [x] RMSE pré-calibration validation : held-out 435,682 ps ; fresh 435,706 ps.
- [x] RMSE post-calibration validation : held-out 19,614 ps ; fresh 19,608 ps.
- [x] MAE pré/post : held-out 375,773 ps -> 15,928 ps ; fresh 375,744 ps -> 15,922 ps.
- [x] Moyenne d’erreur pré/post : held-out -137,799 ps -> -0,0106 ps ; fresh -137,777 ps -> +0,0031 ps.
- [x] Écart-type pré/post : held-out 413,317 ps -> 19,614 ps ; fresh 413,515 ps -> 19,625 ps.
- [x] P50 / P90 / P95 / P99 absolus pré/post : held-out 326 / 732 / 795 / 881 ps -> 13,842 / 32,531 / 37,528 / 45,910 ps ; fresh 326 / 732 / 796 / 1161 ps -> 13,838 / 32,546 / 37,537 / 45,936 ps.
- [x] Min / max erreur post-calibration : held-out -75,507 / +75,473 ps ; fresh -73,767 / +159,748 ps.
- [x] Amélioration relative en % : RMSE fresh réduite de 95,50 % (435,706 ps -> 19,608 ps).

### 4. Analyse `nslow == 0` à ne pas cacher

Sources attendues :

- `fixed_delay/analysis/raw_aliases/all_rows`
- `fixed_delay/analysis/raw_aliases/core_nslow_gt_0`
- `fixed_delay/analysis/raw_aliases/noncore_nslow_eq_0`

À remplir pour `cal_lut_key` et `packet_stop_disc` :

- [x] All rows — lignes : 6 000 000.
- [x] All rows — clés uniques : 439.
- [x] All rows — clés aliasées : 56.
- [x] All rows — lignes aliasées : 1 871 152.
- [x] All rows — oracle RMSE floor : 162,340 ps.
- [x] All rows — oracle P99 : 548,558 ps.
- [x] All rows — max delay span : 900 ps.
- [x] Core `nslow > 0` — mêmes métriques : 2 400 000 lignes ; 235 clés uniques ; 0 clé aliasée ; 0 ligne aliasée ; oracle RMSE/P99/span = 0 ps.
- [x] Non-core `nslow == 0` — mêmes métriques : 3 600 000 lignes ; 204 clés uniques ; 56 clés aliasées ; 1 871 152 lignes aliasées ; oracle RMSE 209,580 ps ; oracle P99 586,452 ps ; span max 900 ps.
- [x] Conclusion : `stop_phase_disc` et la clé `cal_lut_key` résolvent totalement l’ambiguïté sur le sous-ensemble core `nslow > 0`, mais pas sur le sous-ensemble frontière `nslow == 0`; toutes les collisions observées proviennent de cette population non-core.

### 5. Fixed-delay et moyennage réaliste `N <= 15`

Source attendue : `fixed_delay/analysis` + rapport calibration.

- [x] Liste des délais testés : 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000 et 30000 ps.
- [x] Seeds par délai : 24.
- [x] Conversions par seed : 10 000.
- [x] Lignes par délai : 3 600 000 lignes `row`, 240 000 conversions moyennées et 240 000 premiers hits scannés.
- [x] RMSE mono-coup par délai : raw `row` non calibré = 1319,546 / 1317,652 / 1276,561 / 1175,405 / 914,178 / 479,892 / 437,256 / 339,021 / 350,587 / 500,168 ps pour les délais ci-dessus.
- [x] Biais moyen par délai : raw `row` non calibré = -1284,724 / -1282,158 / -1225,965 / -1105,460 / -872,977 / -284,153 / -168,140 / +73,798 / -53,922 / -345,362 ps.
- [x] P95 / P99 par délai : P95 non extrait par ce rapport ; P99 raw `row` = 1700 / 1750 / 1700 / 1680 / 1280 / 800 / 840 / 760 / 840 / 840 ps.
- [x] Pire délai en RMSE : 20 ps avec RMSE raw `row` = 1319,546 ps.
- [x] Pire délai en P99 : 50 ps avec P99 raw `row` = 1750 ps.
- [x] RMSE moyennée N=1 : 19,578 ps.
- [x] RMSE moyennée N=2 : 13,866 ps.
- [x] RMSE moyennée N=3 : 11,227 ps.
- [x] RMSE moyennée N=4 : 9,801 ps.
- [x] RMSE moyennée N=5 : 8,747 ps.
- [x] RMSE moyennée N=8 : 6,848 ps.
- [x] RMSE moyennée N=10 : 6,194 ps.
- [x] RMSE moyennée N=15 : 5,090 ps.
- [x] Vérifier que la courbe publiée ne montre pas `N > 15` : le rapport peut citer uniquement N=1..15 même si le JSON contient des points exploratoires au-delà.

### 6. Code-density, DNL, INL, couverture de phase

Sources attendues : analyses train et validation sweep.

- [x] Nombre total de hits code-density : 3 000 000 lignes analysées dans `train_sweep` et 3 000 000 lignes dans `validation_sweep` (analyse échantillonnée).
- [ ] Occupation min / médiane / max par couple `(ns,nf)` :
- [ ] Nombre de couples `(ns,nf)` couverts sur 64 :
- [ ] Nombre de codes scalaires vides :
- [x] DNL min / max : pic absolu estimé à 1,208 LSB (`train_sweep`) et 1,308 LSB (`validation_sweep`).
- [x] INL min / max : pic absolu estimé à 98,802 LSB (`train_sweep`) et 98,673 LSB (`validation_sweep`).
- [ ] Incertitude DNL 95 % :
- [x] Heatmap de phase régénérée : fichiers générés dans `characterization/analysis/{train_sweep,validation_sweep}`.
- [x] Figure DNL/INL régénérée : fichiers générés dans `characterization/analysis/{train_sweep,validation_sweep}`.

### 7. Boundary / stop-phase discriminator

- [x] Offsets de frontière balayés : validation sweep échantillonnée, configuration `multihit_15_cal_nominal_raw_features_js1_jb3`.
- [x] RMSE min / max / moyenne vs offset : métrique globale sweep pré-calibration, train 459,094 ps et validation 459,021 ps ; extraction par offset encore à consolider depuis les profils CSV si une figure détaillée est publiée.
- [x] Biais min / max vs offset : biais global sweep pré-calibration, train -157,194 ps et validation -157,451 ps ; extraction par offset encore à consolider depuis les profils CSV si une figure détaillée est publiée.
- [ ] Distribution de `phase0_snap` :
- [ ] Distribution de `slow_boundary_inc` :
- [ ] Distribution de `stop_phase_disc` :
- [ ] Corrélation erreur vs `stop_phase_disc` :
- [ ] Figure boundary régénérée en français :
- [ ] Conclusion scientifique : quelles frontières restent faibles ?

### 8. Deadtime nouvelle architecture

Ancienne valeur à ne pas publier comme résultat correct : 4-6 ns / 5,5 ns.

- [x] Banc exact utilisé pour la preuve deadtime : `tb_char_deadtime_persistent`, lancé via `run_characterization_overnight.sh --sim xrun`.
- [x] Commande exacte : `bash MPTDC/scripts/sim/run_characterization_overnight.sh --sim xrun --jobs 8 --seed-start 400000 --seeds 24 --out-dir /sim/ksabra/mptdc_golden_weekend_20260522/deadtime_throughput_final --stages deadtime,context_overflow,throughput --overnight --analyze`.
- [x] Gap STOP-to-next-START minimum lossless : 32 000 ps = 32 ns.
- [x] Conditions : persistent-arm, `xrun`, 24 seeds, 100 essais par gap et par seed, sink/ready local sans backpressure artificielle dans le banc deadtime.
- [x] `max_hits` testés : 1 pour la preuve deadtime persistante.
- [x] Nombre d’essais par gap : 2 400 (`24 seeds x 100 essais`).
- [x] Courbe acceptation vs gap : 0 % jusqu’à 31,5 ns inclus ; 100 % dès 32,0 ns, puis 100 % jusqu’à 80 ns.
- [x] Définition publiée : best-case lossless persistent-arm RTL, séparée de la latence de réarmement logiciel/CSR et de toute latence analogique réelle des oscillateurs.
- [x] Valeur canonique à insérer dans le rapport : deadtime numérique RTL persistent-arm = 32 ns, sous hypothèse modèle oscillateur idéal.

### 9. Throughput, backpressure, FIFO, overflow

- [x] Nombre d’événements throughput : 480 000 (`24 seeds x 20 000 événements`).
- [x] Conversions acceptées : 121 439.
- [x] START rejetés : 358 517.
- [x] Paquets sortis : 121 343.
- [x] Niveau FIFO max : 64 mots.
- [x] Conditions de `ready` : duty-cycle local 50 %.
- [x] `OVF_COUNT` exact par rejet : somme finale 358 517 dans la campagne throughput.
- [x] Preuve absence de corruption contexte/FIFO : campagne VIP finale 2048/2048 PASS + campagne throughput Xcelium complète 72 CSV / 1 272 000 lignes ; l’écart conversions/paquets sous backpressure doit être décrit comme observation de drainage final du banc, pas comme corruption protocolaire.
- [x] Figure throughput régénérée en français : générée dans `deadtime_throughput_final/analysis/plots/throughput_counters.{png,pdf}`.

### 10. VIP / vérification industry-grade

Source attendue : `vip_cdv_final_971cd90/vip_summary.json` et couverture associée.

- [x] Nombre total de tests VIP : 2048 runs (`16 tests x 128 seeds`).
- [x] Nombre de PASS : 2048.
- [x] Nombre de FAIL : 0.
- [x] Tests exacts couverts : `smoke_single_conv`, `full_mode_timestamp`, `firsthit_contract`, `backpressure_integrity`, `start_watchdog`, `cal_inject`, `overflow_status`, `long_random`, `multi_conv_rearm_stress`, `global_watchdog_recovery`, `csr_readback_control`, `hard_reset_readback`, `coverage_exhaustive`, `stress_random`, `vip_ref_stop_cdv`, `vip_maxhits_matrix`.
- [x] Seeds par test : 128, de 300000 à 300127.
- [x] Conversions par test : 20 000.
- [x] Tests avec backpressure : `backpressure_integrity`, `stress_random`.
- [x] Tests avec watchdog : `start_watchdog`, `global_watchdog_recovery`.
- [x] Tests avec overflow/recovery : `overflow_status`, `global_watchdog_recovery`, `stress_random`.
- [x] Tests avec max_hits matrix : `vip_maxhits_matrix`.
- [x] Tests avec reference STOP / qualified-ref : toute la campagne VIP utilise `--stop-model qualified-ref`.
- [ ] Couverture fonctionnelle globale :
- [ ] Couverture code globale :
- [ ] Modules faibles :
- [ ] Waivers nécessaires :
- [x] Bugs trouvés : aucun échec RTL/VIP sur la campagne finale ; les échecs initiaux étaient dus au refus des chemins absolus `/sim/ksabra`.
- [x] Bugs corrigés avant rapport : wrapper VIP corrigé au commit `971cd90` pour accepter les artefacts sous `/sim/ksabra`.

### 11. Figures à régénérer pour le rapport

Toutes les figures doivent avoir axes, légendes, unités et annotations en français.

- [ ] Occupation `(n_s,n_f)` LUT / phase.
- [ ] DNL / INL avec intervalle statistique.
- [ ] Pré/post calibration : RMSE, P95, P99.
- [ ] Histogramme des résidus post-calibration.
- [ ] Résidus vs délai vrai.
- [ ] Résidus vs `stop_phase_disc`.
- [ ] Boundary RMSE/biais vs offset.
- [ ] Deadtime acceptance nouvelle architecture.
- [ ] Throughput/backpressure/FIFO.
- [ ] Alias all/core/noncore.
- [ ] RMSE vs moyennage `N <= 15`.

### 12. Phrases à insérer plus tard dans le rapport

Ne pas rédiger maintenant ; remplir uniquement les données.

- [ ] Chapitre architecture — insérer la séquence RTL active exacte :
- [ ] Chapitre architecture — insérer la justification timing du pivot `clk_sys` :
- [ ] Chapitre architecture — expliquer `fast_clear` :
- [ ] Chapitre calibration — insérer la clé LUT finale :
- [ ] Chapitre calibration — insérer RMSE pré/post définitif :
- [ ] Chapitre calibration — insérer analyse `nslow == 0` :
- [ ] Chapitre vérification — insérer tableau VIP définitif :
- [ ] Chapitre limites — insérer caveat jitter analogique / implémentation physique :

## Blocages connus avant lundi

- [ ] Le script `calibrate_6d_lut.py` publie encore une portée “core subset only (nslow > 0)” dans son JSON ; il faudra décider lundi si on patch le calibrateur pour produire aussi une calibration all-row officielle ou si on publie séparément core/all-row/noncore.
- [ ] Le script d’averaging génère encore des points `N > 15`; il faudra filtrer ou patcher avant génération des figures rapport.
- [ ] Les plots de calibration générés par le script Python source sont encore majoritairement en anglais ; les figures finales du rapport devront être régénérées/francisées.
- [ ] Le jitter 800 fs RMS n’est pas représentable exactement par les plusargs actuels entiers en ps ; le run `1 ps` doit être décrit comme stress conservateur, pas comme modèle analogique exact.
