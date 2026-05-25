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

- [ ] Clé LUT exacte :
- [ ] Nombre de fichiers train :
- [ ] Nombre de fichiers validation :
- [ ] Lignes train avant filtre :
- [ ] Lignes train après filtre :
- [ ] Lignes validation avant filtre :
- [ ] Lignes validation après filtre :
- [ ] Nombre de bins LUT :
- [ ] Population min / médiane / max par bin :
- [ ] Taux de couverture LUT validation :
- [ ] Nombre de lignes validation sans entrée LUT :
- [ ] RMSE pré-calibration validation :
- [ ] RMSE post-calibration validation :
- [ ] MAE pré/post :
- [ ] Moyenne d’erreur pré/post :
- [ ] Écart-type pré/post :
- [ ] P50 / P90 / P95 / P99 absolus pré/post :
- [ ] Min / max erreur post-calibration :
- [ ] Amélioration relative en % :

### 4. Analyse `nslow == 0` à ne pas cacher

Sources attendues :

- `fixed_delay/analysis/raw_aliases/all_rows`
- `fixed_delay/analysis/raw_aliases/core_nslow_gt_0`
- `fixed_delay/analysis/raw_aliases/noncore_nslow_eq_0`

À remplir pour `cal_lut_key` et `packet_stop_disc` :

- [ ] All rows — lignes :
- [ ] All rows — clés uniques :
- [ ] All rows — clés aliasées :
- [ ] All rows — lignes aliasées :
- [ ] All rows — oracle RMSE floor :
- [ ] All rows — oracle P99 :
- [ ] All rows — max delay span :
- [ ] Core `nslow > 0` — mêmes métriques :
- [ ] Non-core `nslow == 0` — mêmes métriques :
- [ ] Conclusion : `stop_phase_disc` résout-il totalement, partiellement, ou pas du tout l’ambiguïté de frontière ?

### 5. Fixed-delay et moyennage réaliste `N <= 15`

Source attendue : `fixed_delay/analysis` + rapport calibration.

- [ ] Liste des délais testés :
- [ ] Seeds par délai :
- [ ] Conversions par seed :
- [ ] Lignes par délai :
- [ ] RMSE mono-coup par délai :
- [ ] Biais moyen par délai :
- [ ] P95 / P99 par délai :
- [ ] Pire délai en RMSE :
- [ ] Pire délai en P99 :
- [ ] RMSE moyennée N=1 :
- [ ] RMSE moyennée N=2 :
- [ ] RMSE moyennée N=3 :
- [ ] RMSE moyennée N=4 :
- [ ] RMSE moyennée N=5 :
- [ ] RMSE moyennée N=8 :
- [ ] RMSE moyennée N=10 :
- [ ] RMSE moyennée N=15 :
- [ ] Vérifier que la courbe publiée ne montre pas `N > 15`.

### 6. Code-density, DNL, INL, couverture de phase

Sources attendues : analyses train et validation sweep.

- [ ] Nombre total de hits code-density :
- [ ] Occupation min / médiane / max par couple `(ns,nf)` :
- [ ] Nombre de couples `(ns,nf)` couverts sur 64 :
- [ ] Nombre de codes scalaires vides :
- [ ] DNL min / max :
- [ ] INL min / max :
- [ ] Incertitude DNL 95 % :
- [ ] Heatmap de phase régénérée :
- [ ] Figure DNL/INL régénérée :

### 7. Boundary / stop-phase discriminator

- [ ] Offsets de frontière balayés :
- [ ] RMSE min / max / moyenne vs offset :
- [ ] Biais min / max vs offset :
- [ ] Distribution de `phase0_snap` :
- [ ] Distribution de `slow_boundary_inc` :
- [ ] Distribution de `stop_phase_disc` :
- [ ] Corrélation erreur vs `stop_phase_disc` :
- [ ] Figure boundary régénérée en français :
- [ ] Conclusion scientifique : quelles frontières restent faibles ?

### 8. Deadtime nouvelle architecture

Ancienne valeur à ne pas publier comme résultat correct : 4-6 ns / 5,5 ns.

- [ ] Banc exact utilisé pour la preuve deadtime :
- [ ] Commande exacte :
- [ ] Gap STOP-to-next-START minimum lossless :
- [ ] Conditions : sink ready / stalls / backpressure :
- [ ] `max_hits` testés :
- [ ] Nombre d’essais par gap :
- [ ] Courbe acceptation vs gap :
- [ ] Définition publiée : best-case lossless / backpressure-tolerant / frontend re-arm :
- [ ] Valeur canonique à insérer dans le rapport :

### 9. Throughput, backpressure, FIFO, overflow

- [ ] Nombre d’événements throughput :
- [ ] Conversions acceptées :
- [ ] START rejetés :
- [ ] Paquets sortis :
- [ ] Niveau FIFO max :
- [ ] Conditions de `ready` :
- [ ] `OVF_COUNT` exact par rejet :
- [ ] Preuve absence de corruption contexte/FIFO :
- [ ] Figure throughput régénérée en français :

### 10. VIP / vérification industry-grade

Source attendue : `vip_cdv/vip_summary.json` et couverture associée.

- [ ] Nombre total de tests VIP :
- [ ] Nombre de PASS :
- [ ] Nombre de FAIL :
- [ ] Tests exacts couverts :
- [ ] Seeds par test :
- [ ] Conversions par test :
- [ ] Tests avec backpressure :
- [ ] Tests avec watchdog :
- [ ] Tests avec overflow/recovery :
- [ ] Tests avec max_hits matrix :
- [ ] Tests avec reference STOP / qualified-ref :
- [ ] Couverture fonctionnelle globale :
- [ ] Couverture code globale :
- [ ] Modules faibles :
- [ ] Waivers nécessaires :
- [ ] Bugs trouvés :
- [ ] Bugs corrigés avant rapport :

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
