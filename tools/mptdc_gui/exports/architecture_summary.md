# Résumé d'architecture MPTDC

- Top MPTDC actif : `mptdc_top_asic`.
- Contexte full-chip : `spadmic_top_v1`.
- Le nom attendu initialement `mptdc_vernier_top_silicon` n'apparaît pas dans cette copie de travail.
- Le parser de ports ANSI est validé sur `mptdc_input_mux`, `mptdc_core`, `mptdc_top_asic` et `mptdc_narrow16_tx_v2`.

## Flux principal

- **Sélection source SPAD/CAL asynchrone** : `mptdc_input_mux` sélectionne START/STOP SPAD ou calibration comme signaux asynchrones combinatoires purs. (`MPTDC/rtl/ctrl/mptdc_input_mux.sv:47`).
- **START accepté et contexte alloué** : Le frontend accepte START uniquement si la conversion est armée, non verrouillée et avec un contexte libre. (`MPTDC/rtl/async/mptdc_async_frontend_v2.sv:98`).
- **STOP lance l'oscillateur rapide et l'éligibilité PD** : STOP, ou le timeout synthétique, ne verrouille `stop_latched` qu'après START ; l'oscillateur rapide et `pd_enable` dérivent des verrous START/STOP. (`MPTDC/rtl/async/mptdc_async_frontend_v2.sv:144`).
- **Matrice phase detector 8 x 8** : `mptdc_core` génère une cellule PD par paire phase lente/rapide et verrouille `nfast_hit` par cellule. (`MPTDC/rtl/top/mptdc_core.sv:406`).
- **Snapshot, banque de contextes, drain** : La FSM `clk_sys` échantillonne l'image tenue, commit le contexte, puis `drain_ctrl` émet META/HIT. (`MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:165`).
- **FIFO vers sortie locale ou readout partagé** : La FIFO acquisition est consommée par le serializer local `narrow16` ou par l'export partagé `acq_valid/acq_ready`. (`MPTDC/rtl/top/mptdc_core.sv:563`).

## Points incertains / revue manuelle

- **moyen** - Nom de top attendu absent : `mptdc_vernier_top_silicon` n'a pas été trouvé dans les fichiers du dépôt parcourus.
- **élevé** - Oscillateur physique non prêt pour la revue de signoff : Le chemin synthèse utilise un bloc de remplacement tant que le contrat macro réel n'est pas disponible.
- **élevé** - Fermeture CDC/STA standard non prouvée : Les verrous asynchrones, la capture STOP, les snapshots Gray et les horloges locales PD exigent une méthodologie et des dérogations contrôlées.
- **moyen** - Artefact VIP commité probablement ancien ou échoué : `vip_summary.json` rapporte 4096 échecs, en contradiction avec les statuts README/docs courants.
