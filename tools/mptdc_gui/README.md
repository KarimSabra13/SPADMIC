# Explorateur MPTDC Vernier

Outil local de présentation et de revue RTL pour le MPTDC SPADMIC. Le RTL n'est
pas modifié: `rtl_parser.py` extrait `architecture_db.json`, puis l'interface
React/Vite présente un scénario START/STOP configurable.

La calibration est volontairement décrite comme **logicielle / off-chip**: le
RTL produit les packets et features brutes; le logiciel reconstruit, calibre,
moyenne et affiche la valeur finale.

## Régénérer la base RTL

Depuis la racine du dépôt:

```bash
python tools/mptdc_gui/rtl_parser.py --validate-ports
python tools/mptdc_gui/diagram_generator.py
```

La validation échoue si les ports clés de `mptdc_top_asic`, `mptdc_core`,
`mptdc_input_mux`, `mptdc_async_frontend_v2` ou `mptdc_narrow16_tx_v2` sont
tronqués en noms d'un seul caractère comme `s`, `n`, `i`, `o`.

## Lancer la nouvelle UI React

```bash
cd tools/mptdc_gui/frontend
npm install
npm run dev
```

Ouvrir l'URL affichée par Vite, typiquement:

```text
http://127.0.0.1:5173
```

Mode soutenance direct:

```text
http://127.0.0.1:5173/presentation
```

ou:

```text
http://127.0.0.1:5173?presentation=1
```

## Build web statique

```bash
cd tools/mptdc_gui/frontend
npm run build
npm run preview
```

## Ancienne version fallback Python

L'ancien serveur standard-library reste disponible:

```bash
python tools/mptdc_gui/app.py
```

Ouvrir ensuite:

```text
http://127.0.0.1:8501
```

## Scénario interactif

Vue principale: **Simulation interactive de mesure Vernier**.

Contrôles disponibles:

- source `SPAD` ou `CAL`;
- délai START→STOP de 0 à 32 ns, défaut 17.5 ns;
- presets 15 ns, 17.5 ns, 20 ns, cas court, cas long, cas timeout;
- mode sortie standalone `narrow16` ou shared `acq_*`;
- `max_hits`, défaut 15;
- lecture, pause, pas suivant, pas précédent, reset;
- vitesse 0.25x, 0.5x, 1x, 2x;
- mode soutenance;
- export scénario.

La vue principale n'utilise pas de grands domaines d'horloge visibles. Le
parcours suit la mesure:

```text
Entrées → MUX → frontend → oscillateurs → matrice Vernier → capture
→ contexte → drain → FIFO → packets → calibration logicielle
```

Les informations CDC/timing sont conservées dans la vue dédiée **CDC / timing**.

## Exports navigateur

Depuis la vue **Export**:

- SVG du schéma courant;
- PNG du schéma courant si le navigateur le permet;
- JSON du scénario;
- Markdown français;
- HTML présentation;
- CSV des hits;
- CSV raw/calibrated;
- WaveDrom JSON.

## Packaging desktop

Scripts fournis:

```bash
bash tools/mptdc_gui/build_desktop_tauri.sh
bash tools/mptdc_gui/build_desktop_electron.sh
```

Ces scripts construisent d'abord l'UI web. Tauri/Electron restent optionnels et
nécessitent leurs chaînes de packaging respectives.

## Fichiers principaux

- `rtl_parser.py`: parsing RTL/docs et génération `architecture_db.json`.
- `diagram_generator.py`: génération des SVG/exports fallback.
- `app.py`: serveur Python fallback.
- `frontend/src/App.tsx`: point d'entrée React.
- `frontend/src/components/MptdcExplorer.tsx`: orchestration UI.
- `frontend/src/sim/vernierModel.ts`: modèle pédagogique START/STOP.
- `frontend/src/sim/packetModel.ts`: records META/HIT/EOC et mots `narrow16`.
- `frontend/src/sim/calibrationModel.ts`: calibration logicielle/off-chip.
- `frontend/src/components/PdMatrixView.tsx`: matrice Vernier 8x8.
- `frontend/src/components/PacketStreamView.tsx`: visualisation packet stream.
- `frontend/src/components/SoftwareCalibrationView.tsx`: reconstruction/calibration.

## Limites assumées

- Le modèle de scénario est pédagogique et aligné avec les constantes RTL; il ne
  remplace pas une simulation transistor, STA, CDC ou silicon.
- Les relations producteur/consommateur complexes restent inférées depuis le RTL.
- Le packaging Tauri/Electron nécessite une configuration desktop complète si un
  exécutable final est requis.
