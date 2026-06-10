# Plan principal final en 18 diapositives

Objectif : soutenance d'ingénieur de 30 minutes. Format : 16:9. Principe : affirmation-preuve, une idée forte par diapositive, une preuve visuelle dominante.

| # | Temps | Titre-assertion | Visuel / preuve principale | Points à dire à l'oral |
|---:|---:|---|---|---|
| 1 | 1:00 | SPADMIC a besoin d'une information temporelle mesurable, exportable et calibrable. | Visuel d'ouverture : SPADMIC -> MPTDC -> correction côté hôte | Présenter SPADMIC comme prototype ASIC de lecture SPAD. Annoncer le focus : le MPTDC, brique numérique temporelle la plus mûre. Donner le ton : la soutenance suivra les preuves et les choix d'ingénierie. |
| 2 | 0:50 | La soutenance suit le chemin du besoin détecteur vers une chaîne MPTDC vérifiée en pré-silicium. | Entonnoir narratif : besoin -> contraintes -> architecture -> RTL/protocole -> vérification -> calibration -> limites | Expliquer que la présentation ne recopie pas le rapport chapitre par chapitre. Elle construit un raisonnement d'architecture. Poser dès le début la frontière : validation numérique pré-silicium. |
| 3 | 1:20 | Le travail s'inscrit dans un contexte d'instrumentation où la microélectronique rend la lecture détecteur possible. | Entonnoir institutionnel : CNRS / IN2P3 / IP2I / équipe microélectronique / SPADMIC | Rester bref sur CNRS et IP2I. Utiliser ce contexte pour justifier le cadre instrumentation et ASIC, pas pour remplir la présentation. |
| 4 | 1:30 | Dans SPADMIC, le TDC sert trois axes temporels sans résumer toute la puce. | Architecture SPADMIC simplifiée : trois axes MPTDC, chemin position, TX partagé, hôte | Montrer que le temps est un chemin coordonné dans un ASIC plus large. Mentionner la sortie partagée et le traitement côté hôte. |
| 5 | 2:00 | Le vrai problème combine résolution fine, plage, réarmement, observabilité et contraintes ASIC. | Carte des compromis de conception | C'est la première diapositive technique clé. Montrer que l'objectif n'est pas seulement une résolution nominale. Relier chaque contrainte à un choix d'architecture. |
| 6 | 1:45 | Le Vernier est pertinent car la résolution vient d'une différence de délais, pas d'un délai absolu unique. | Chronogramme de principe Vernier | Expliquer les chemins lent/rapide, `START/STOP`, le rattrapage et pourquoi une horloge `clk_sys` très rapide n'est pas la solution réaliste. |
| 7 | 1:45 | L'observation multiphase transforme un croisement Vernier en mesure plus riche dans une matrice de phases. | Intuition de matrice `8x8` et chronogramme multiphase simplifié | Distinguer le gain multiphase pendant une conversion du moyennage statistique présenté plus tard. Introduire `55 ps / 50 ps`, `5 ps` et les coordonnées de phase. |
| 8 | 1:40 | L'architecture de référence doit être transformée pour survivre à l'intégration SPADMIC. | Comparaison architecture de référence / implémentation retenue | Montrer ce qui est conservé : deux oscillateurs, séparation grossier/fin, matrice de phase, besoin de calibration. Montrer ce qui est ajouté : capture asynchrone, contextes, CDC, sortie compacte. |
| 9 | 1:40 | Le MPTDC actif conserve le principe Vernier mais ajoute capture asynchrone, discipline CDC, contextes et lecture. | Wrapper top-level MPTDC/ASIC avec interfaces | Expliquer la frontière du wrapper : entrées SPAD/cal asynchrones, reset, CSR, sortie et lecture. Éviter la surcharge de pins et de noms RTL. |
| 10 | 1:50 | La matrice `8x8` fournit des observables utiles, pas une règle temporelle naturellement uniforme. | Carte thermique de matrice de phase / codes fins | Expliquer la grille fine creuse et non uniforme. Préparer le jury à comprendre la calibration sans donner l'impression que le résultat brut est un accident. |
| 11 | 2:00 | La validité de la mesure dépend du gel de l'image avant tout nettoyage de la matrice. | Chronogramme de protocole : START, STOP, gate PD, snapshot, écriture contexte, clear | Parcourir la séquence lentement. Phrase clé : "figer, stocker, libérer, puis nettoyer". C'est une diapositive d'ingénierie à forte valeur. |
| 12 | 1:35 | Le reset global et le clear de conversion ne résolvent pas le même problème. | Chronogramme reset versus clear | Le reset place le bloc dans un état connu. Le clear réarme une fenêtre de mesure après protection de l'image. L'ordre évite la destruction de données utiles. |
| 13 | 1:40 | Les deux contextes découplent la capture rapide de la lecture, sans supprimer les limites de débit. | Flux double contexte / buffer / export | Expliquer que les contextes stockent des images de mesure, ils ne dupliquent pas la matrice physique. Mentionner la rétropression et le rejet contrôlé lorsque les ressources saturent. |
| 14 | 1:30 | La trame compacte exporte des informations de calibration plutôt qu'un timestamp final absolu. | Flux de trame `16 bit` : META, HIT, EOC, décodeur hôte | Expliquer pourquoi la trame transporte observables et métadonnées. Garder les bitfields détaillés pour les backups. |
| 15 | 2:00 | La vérification cible l'ordre du protocole, les resets, la rétropression, les watchdogs et la cohérence des paquets. | Environnement de vérification en couches : générateur, driver, DUT, monitor, modèle de référence, scoreboard/assertions | Présenter la vérification comme une méthode, pas comme une trace de simulation. Dire clairement ce qu'elle prouve et ce qu'elle ne prouve pas. |
| 16 | 1:40 | La calibration externe transforme une grille brute biaisée en estimation temporelle exploitable. | Pipeline calibration : observables exportées -> LUT -> temps corrigé | Expliquer la logique de LUT côté hôte : silicium plus simple, correction évolutive après caractérisation. Mentionner la validation tenue hors apprentissage. |
| 17 | 2:10 | Dans le rapport, la calibration réduit la RMSE brute d'environ `1.94 ns` à `18.56 ps` après LUT. | Résumé résultat : RMSE avant/après, moyenne, P99 et histogramme compact | Citer le résultat précisément : moyenne brute `-1895.97 ps`, RMSE brute `1940.32 ps`, moyenne post-LUT `-0.008 ps`, RMSE `18.56 ps`, P99 `38.99 ps`. Rappeler que c'est pré-silicium RTL/Xcelium. |
| 18 | 2:20 | La contribution principale est une chaîne MPTDC crédible, avec une feuille de route claire vers la validation physique. | Feuille de route contribution/limites : RTL validé -> STA/CDC/PnR -> post-layout -> silicium | Conclure en trois messages : architecture intégrée, contrat numérique vérifié et calibrable, prochaines étapes physiques. Mentionner le moyennage uniquement comme appui prudent : `N=4 -> <10 ps`, `N=15 -> <5 ps` en statistique. |

## Diapositives à protéger si le temps manque

Ne pas supprimer les diapositives 5, 11, 15, 17 ni les limites de la diapositive 18. Elles forment la colonne vertébrale de la soutenance.

## Diapositives compressibles

- La diapositive 3 peut passer à 30 secondes.
- Les diapositives 6 et 7 peuvent être fusionnées si le jury comprend déjà le principe Vernier.
- La diapositive 9 peut devenir une orientation wrapper en une phrase.
- Les détails bit à bit de la diapositive 14 vont dans les diapositives de secours.
- Le moyennage reste dans les supports de secours sauf question directe.

## Règle visuelle pour le support principal

Ne pas coller les figures denses du rapport directement si elles deviennent illisibles en vignette ou en salle. Les utiliser comme source technique, puis les redessiner avec une logique orale plus claire.
