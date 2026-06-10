# Périmètre des sources et thèse centrale

## Périmètre des sources

La source principale pour la soutenance est le rapport final `Rapport_5PSM_KS/dist/Rapport_Karim_Sabra_5PSM.pdf`, complété par les chapitres LaTeX correspondants dans `Rapport_5PSM_KS/chapters`.

Le dépôt local `KarimSabra13/SPADMIC` sert de contexte technique et de garde-fou sur l'état courant du projet. Les documents du dépôt sont utiles pour vérifier la cohérence de l'architecture, de la vérification et des limites, mais le récit de soutenance doit rester aligné avec le rapport final sauf décision explicite de Karim.

Point critique : le rapport et les artefacts associés soutiennent le résultat de calibration `1.94 ns -> 18.56 ps` RMSE après LUT. En parallèle, `MPTDC/README.md` mentionne une base plus récente ou différente autour de `374.11 ps -> 24.64 ps`, et indique que certains chiffres proches de `18.9 ps` sont historiques ou nominaux dans ce contexte. Pour cette soutenance, il faut citer `18.56 ps` comme résultat de caractérisation RTL/Xcelium archivé dans le rapport, pas comme dernière valeur de validation globale du dépôt ni comme performance silicium.

## Thèse centrale

En une phrase : le travail transforme un principe de TDC Vernier multiphase en une chaîne de mesure pré-silicium pour SPADMIC, avec un MPTDC asynchrone `8x8`, une capture protégée par snapshot/contexte, une sortie compacte, une vérification fonctionnelle et une calibration côté hôte, tout en gardant clairement ouvertes les étapes de validation physique et silicium.

En trois phrases : SPADMIC a besoin d'une mesure temporelle fine, mais aussi observable, exportable et compatible avec l'intégration ASIC. Le MPTDC répond à ce besoin par une capture asynchrone `START/STOP`, une matrice Vernier multiphase, deux contextes de stockage, une lecture en domaine système, une trame compacte et une calibration externe. Les résultats valident le contrat numérique et la logique de calibration en RTL/Xcelium, mais l'oscillateur réel, la STA, la CDC, le comportement PVT, le post-layout et la corrélation silicium restent les étapes décisives.

En un paragraphe : la thèse défendable n'est pas simplement "j'ai utilisé une formule de TDC", mais "j'ai construit une chaîne de mesure temporelle exploitable pour un prototype ASIC de lecture SPAD". Le travail part d'un principe Vernier multiphase puis le transforme en architecture MPTDC pratique : matrice de phase lente/rapide `8x8`, capture asynchrone des événements, discipline CDC par Gray/snapshot, deux contextes figés, séquencement watchdog/clear, et sortie compacte compatible avec le chemin de lecture partagé de SPADMIC. La vérification RTL et la caractérisation montrent que la grille temporelle brute, non uniforme, peut devenir exploitable grâce à une calibration externe. Dans la campagne du rapport, la RMSE brute d'environ `1.94 ns` est ramenée à `18.56 ps` après correction LUT. La limite honnête est essentielle : il s'agit d'une preuve numérique pré-silicium, pas d'une performance mesurée sur circuit fabriqué.

## Contributions les plus fortes

- Une architecture RTL cohérente qui transforme une référence Vernier multiphase en bloc MPTDC intégrable : capture asynchrone, matrice de détection `8x8`, deux contextes, jusqu'à `15` détections exportées, lecture système à `160 MHz` et trame compacte sur `16 bit`.
- Un protocole de mesure prudent : snapshot et écriture de contexte avant tout clear destructif, distinction entre reset global et clear de conversion, traversées par Gray/snapshot, watchdogs, gestion de la rétropression et visibilité des statuts d'overflow.
- Un contrat de données pensé pour la calibration : le bloc exporte assez d'observables brutes et de métadonnées de frontière pour permettre une correction côté hôte. La campagne RTL/Xcelium du rapport montre une amélioration forte après LUT.

## Limites les plus importantes

- Les résultats sont pré-silicium : le comportement de l'oscillateur est modélisé ou remplacé par stub, et les étapes oscillateur réel, contraintes de clocks générées, CDC/STA, DFT, post-layout, PVT et mesure silicium ne sont pas closes.
- Les résultats de calibration dépendent de la campagne, du format d'observables et du domaine couvert. Il ne faut pas présenter `18.56 ps` comme une performance universelle, finale, jitter-limited, déployée ou silicium.
- L'architecture a des ressources bornées et des structures temporelles non triviales : deux contextes, `15` hits maximum, sortie partagée sensible à la rétropression, logique asynchrone intentionnelle, détecteurs de phase et latches à valider physiquement.

## Chiffres à citer avec précision

| Sujet | Chiffre utilisable en soutenance | Usage conseillé |
|---|---:|---|
| Géométrie Vernier | `8 x 8 = 64` cellules de détection de phase | Slide principal |
| Pas de phase lent / rapide | `55 ps / 50 ps` | Slide principal |
| Différence Vernier élémentaire | `5 ps` | Slide principal |
| Pas brut de reconstruction | `10 ps` | Backup ou Q&A |
| Nombre de contextes | `2` | Slide principal |
| Détections exportables | jusqu'à `15` par conversion | Slide principal |
| Horloge système | `160 MHz` | Slide principal |
| Flux de sortie | trame compacte `16 bit` | Slide principal |
| Validation tenue hors apprentissage | `8,999,942` lignes | Backup |
| RMSE brute avant LUT | `1940.32 ps`, soit environ `1.94 ns` | Slide principal |
| RMSE après LUT | `18.56 ps` | Diapositive principale avec réserve explicite |
| P99 de l'erreur absolue après LUT | `38.99 ps` | Slide principal |
| Moyennage après LUT | `N=4 -> 9.28 ps`, `N=15 -> 4.77 ps` | Avec prudence |
| DNL / INL sur codes observés | DNL pic `0.987 LSB`, INL extrémité `1.553 LSB` | Backup |
| État de vérification dans le dépôt | VIP smoke `13/13`; baseline observée `109/109`, couverture `70.08%`, grade `82.05%` | Backup/statut seulement |

## Discipline de formulation

- Dire : "La campagne RTL/Xcelium du rapport valide que les observables exportées suffisent à une correction externe efficace sur le domaine étudié."
- Ne pas dire : "Le circuit atteint `18.56 ps`."
- Dire : "Les deux contextes découplent la capture de la lecture et réduisent la dépendance du temps mort à la sérialisation."
- Ne pas dire : "Les deux contextes suppriment toute limite de débit."
- Dire : "Le moyennage donne un gain statistique sur des estimations corrigées."
- Ne pas dire : "Un événement unique est mesuré de façon déterministe sous `5 ps`."
- Dire : "La stratégie CDC est conçue et partiellement vérifiée au niveau RTL."
- Ne pas dire : "La CDC et le signoff physique sont terminés."
