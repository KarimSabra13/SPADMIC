# Mise en route CSR et I2C - ABI 1.0

## Objet

Ce guide décrit la mise en route logicielle du contrôle SPADMIC. Il ne lance ni
Genus, ni Innovus, ni modification OA.

## Paramètres I2C

- adresse 7 bits fixe : `0x42`
- fréquence : 100 kHz
- adresse registre : 16 bits, octet fort en premier
- donnée : 32 bits, octet fort en premier
- une transaction par registre, sans auto-incrémentation
- lecture par pointeur + START répété, ou avec le pointeur courant

Une écriture de pointeur seul est valide. Une donnée incomplète de 1 à 3 octets
est entièrement annulée et journalisée. `i2c_rst_i` réinitialise seulement le
transport I2C et conserve la configuration, les défauts et les compteurs CSR.

## Vérification d'identité

1. Lire `CHIP_ID` à `0x0000`; valeur attendue : `0x53504D54`.
2. Lire `ABI_VERSION` à `0x0004`; valeur attendue : `0x00010000`.
3. Lire `GLOBAL_CTRL` à `0x0008`; après reset puce : `0x000000F0`.
4. Lire `GLOBAL_STATUS` à `0x000C` et attendre le bit `safe_idle[7] = 1`.

En cas d'échec, arrêter la mise en route et lire `ACCESS_STATUS`,
`ACCESS_FAULT`, `ACCESS_LAST_INFO`, `ACCESS_LAST_WDATA` et
`ACCESS_ERROR_COUNT`.

## Configuration de base

La configuration doit être écrite avec l'acquisition globale désactivée et le
système au repos.

| Registre | Adresse | Valeur de départ recommandée |
| --- | ---: | ---: |
| `GLOBAL_CTRL` | `0x0008` | `0x000000F0` - désactivé |
| `TDC_SHARED_CFG` | `0x0018` | `0x0000000F` - max hits par défaut |
| `CALIB_AXIS_MASK` | `0x0020` | `0x00000007` |
| `POSITION_CFG` | `0x4000` | `0x00000104` - cluster, gap 2, minimum 1 |
| `SNAPSHOT_CFG` | `0x5008` | `0x00400002` |
| `RESET_CFG` | `0x500C` | valeur non nulle, par exemple `0x00000004` |

Relire chaque registre après écriture. Les bits réservés doivent rester à zéro.

## Activation atomique

Avec `RESET_CFG != 0` et `GLOBAL_STATUS.safe_idle = 1` :

| Mode | Valeur `GLOBAL_CTRL` | Résultat |
| --- | ---: | --- |
| TDC normal | `0x000000F3` | R/Y/B actifs, auto-reset actif |
| Position | `0x000000F5` | position active, auto-reset actif |
| TDC + Position | `0x000000F7` | R/Y/B et position actifs |

Pour la calibration, programmer d'abord un masque non nul dans
`CALIB_AXIS_MASK`, puis écrire `GLOBAL_CTRL` avec enable, mode calibration et
auto-reset. Un masque partiel est autorisé uniquement en calibration.

Ne pas chercher de commande manuelle de démarrage de conversion en mode normal :
le démarrage appartient au coordinateur d'événement SPAD.

## Arrêt et reconfiguration

1. Attendre la fin de l'événement courant.
2. Écrire `GLOBAL_CTRL = 0x000000F0`.
3. Attendre `GLOBAL_STATUS.safe_idle[7] = 1`.
4. Modifier les registres de configuration.
5. Relire, puis réactiver atomiquement le mode choisi.

Toute écriture de configuration pendant un état actif ou occupé est refusée,
sans effet de bord, et enregistrée comme `UNSAFE_WRITE`.

## Défauts et compteurs

Les registres `*_FAULT` sont W1C : écrire `1` uniquement sur les bits à
effacer. Les compteurs saturent à `0xFFFFFFFF`. `MAINT_CMD[0]` remet les
compteurs d'erreur à zéro uniquement lorsque le système est désactivé et au
repos; cette commande ne modifie ni la configuration ni les défauts sticky.

Une lecture invalide retourne zéro et journalise l'erreur. Une écriture invalide
n'a aucun effet fonctionnel et journalise aussi l'erreur.

## Artefacts logiciels

- C : `TOP/sw/include/spadmic_csr.h`
- Python : `TOP/sw/python/spadmic_csr_map.py`
- CSV registres : `TOP/docs/csr/spadmic_csr_map.csv`
- CSV champs : `TOP/docs/csr/spadmic_csr_fields.csv`
- carte complète : `TOP/docs/csr/CSR_MAP.md`

Ces fichiers sont générés depuis `TOP/rtl/spadmic_csr_map_pkg.sv`; ne pas les
modifier manuellement.
