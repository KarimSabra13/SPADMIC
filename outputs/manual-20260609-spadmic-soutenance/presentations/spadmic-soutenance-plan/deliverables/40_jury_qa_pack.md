# Pack de questions-réponses pour le jury

## Questions très probables

| # | Question | Réponse orale concise | Visuel utile |
|---:|---|---|---|
| 1 | Quel est le rôle du MPTDC dans SPADMIC ? | Il transforme le timing d'événements SPAD asynchrones en observables numériques compactes, exploitables par une reconstruction et une calibration côté hôte. Ce n'est pas simplement un générateur de timestamp final. | Vue SPADMIC |
| 2 | Pourquoi choisir un TDC Vernier ? | Le Vernier permet d'obtenir une finesse temporelle à partir de la différence entre deux délais proches, sans imposer une horloge système extrêmement rapide. | Principe Vernier |
| 3 | Pourquoi utiliser une architecture Vernier multiphase ? | Plusieurs couples de phases sont observés en parallèle. Cela enrichit l'observabilité et peut réduire le temps nécessaire à la décision pendant une conversion. | Chronogramme multiphase |
| 4 | Quels sont les paramètres principaux du MPTDC ? | Matrice de phase `8x8`, pas lent/rapide `55 ps / 50 ps`, différence Vernier `5 ps`, deux contextes, jusqu'à `15` hits, horloge système `160 MHz`, sortie `16 bit`. | Tableau de paramètres |
| 5 | Pourquoi le pas brut de reconstruction vaut-il `10 ps` alors que la différence Vernier vaut `5 ps` ? | Le `5 ps` correspond à l'unité élémentaire de différence de phase. L'encodage et la reconstruction bruts utilisent une grille de `10 ps`, puis les observables plus riches alimentent la correction LUT. | Heatmap de matrice |
| 6 | Pourquoi ne pas synchroniser directement `START/STOP` dans `clk_sys` ? | Cela injecterait l'incertitude de l'horloge système dans le chemin même que l'on veut mesurer. L'architecture capture donc `START/STOP` de manière asynchrone, puis transfère une image protégée vers `clk_sys`. | Timing de capture asynchrone |
| 7 | Comment éviter de perdre la mesure avant la lecture ? | Le snapshot arrive avant l'écriture contexte et avant le clear. La matrice n'est nettoyée qu'une fois l'image de conversion protégée. | Séquence reset/clear |
| 8 | À quoi servent les deux contextes ? | Ils découplent la capture rapide de la lecture plus lente. Ils réduisent le temps mort lié à la sérialisation, mais ne dupliquent pas la matrice physique. | Pipeline de contextes |
| 9 | Que se passe-t-il si la sortie applique une rétropression ? | Le drain conserve son mot courant et sa position. Si les deux contextes restent occupés, de nouveaux événements peuvent être rejetés de façon contrôlée, avec statut visible. | Flux FIFO/TX |
| 10 | Pourquoi une sortie `16 bit` ? | Elle limite le coût en broches et garde une interface compacte. Chaque paquet contient un en-tête, deux mots par hit et un mot de fin de conversion. | Format de paquet |
| 11 | Que signifie `2*Ndet + 2` ? | Un mot d'en-tête, deux mots `16 bit` pour chaque hit exporté, puis un mot de fin de conversion. | Format de paquet |
| 12 | Quelles observables sont exportées pour la calibration ? | Des compteurs grossiers, indices de phase, informations de hit, champs de contexte/statut et métadonnées de frontière. | Flux de calibration |
| 13 | Pourquoi une calibration externe plutôt qu'une correction embarquée ? | Elle simplifie le silicium et laisse la correction évoluer après caractérisation ou mesures silicium. C'est un choix d'architecture, pas seulement un post-traitement. | ASIC vers LUT hôte |
| 14 | Quel est le résultat principal de calibration ? | Sur validation RTL/Xcelium tenue hors apprentissage, la RMSE passe d'environ `1.94 ns` brut à `18.56 ps` après LUT, avec un P99 à `38.99 ps`. | Résultat avant/après |
| 15 | `18.56 ps`, est-ce une performance silicium ? | Non. C'est un résultat pré-silicium RTL/Xcelium qui valide le contrat d'observabilité et de correction, pas une mesure sur circuit fabriqué. | Slide limites |
| 16 | Pourquoi l'erreur brute est-elle si grande ? | La grille Vernier brute est non uniforme et biaisée. La LUT corrige l'erreur systématique associée aux classes d'observables. | Histogramme d'erreur |
| 17 | Que montrent la DNL et l'INL ? | Sur les codes observés, la DNL pic vaut environ `0.987 LSB` et l'INL d'extrémité environ `1.553 LSB`. Cela soutient l'exploitabilité des codes atteints, pas l'uniformité de toute la grille. | Courbes DNL/INL |
| 18 | Existe-t-il des codes manquants ? | Oui. La grille fine complète est creuse. C'est précisément pour cela que l'architecture exporte des observables riches et s'appuie sur une calibration. | Code-density |
| 19 | Comment la validation tenue hors apprentissage est-elle faite ? | Les seeds d'apprentissage et de validation sont séparés. Les métriques annoncées sont calculées sur des données non utilisées pour construire la LUT. | Séparation train/validation |
| 20 | Que signifie le P99 ? | Après LUT, `99 %` des erreurs absolues de validation sont inférieures à `38.99 ps`. | Histogramme ou CDF |
| 21 | Pourquoi utiliser la RMSE et pas seulement l'erreur moyenne ? | La moyenne montre la suppression du biais. La RMSE mesure la dispersion résiduelle, plus pertinente pour la précision temporelle. | Tableau avant/après |
| 22 | Quel est le résultat du moyennage ? | Le moyennage statistique post-LUT descend sous `10 ps` vers `N=4` et sous `5 ps` vers `N=15` dans le cadre d'analyse étudié. | RMSE versus N |
| 23 | Peut-on atteindre `N=50` dans une seule conversion ? | Non. Le matériel exporte jusqu'à `15` détections par conversion. Les grands `N` relèvent d'un moyennage d'observations, pas d'une promesse par conversion unique. | Courbe avec réserve |
| 24 | Multiphase et moyennage, est-ce la même chose ? | Non. Le multiphase enrichit l'observation pendant une conversion. Le moyennage combine ensuite plusieurs estimations corrigées. | Multiphase versus moyennage |
| 25 | Que couvre la vérification ? | Cohérence des paquets, resets, rétropression, timeouts, rejets d'événements, cas de frontière et comparaison avec un modèle de référence. | Environnement de vérification |
| 26 | La CDC est-elle complètement signée ? | Pas encore. Le RTL utilise compteurs Gray, synchroniseurs et discipline de snapshot, mais une revue CDC formelle reste nécessaire. | Diagramme CDC |
| 27 | Pourquoi utiliser des compteurs Gray ? | Un seul bit change à chaque transition. Ainsi, un échantillonnage incertain reste borné entre ancienne et nouvelle valeur, au lieu de produire un mot binaire incohérent. | Principe Gray CDC |
| 28 | Que se passe-t-il si `STOP` n'arrive pas ? | Des watchdogs ferment ou récupèrent la conversion et rendent la situation observable dans les champs de statut. | FSM/watchdog |
| 29 | Pourquoi trois axes MPTDC ? | SPADMIC repose sur des projections tri-axis. Les voies temporelles participent à cette logique de lecture coordonnée, ce ne sont pas seulement trois canaux indépendants. | Vue tri-axis |
| 30 | Quelle est la contribution principale du projet ? | Transformer un principe Vernier multiphase en bloc RTL intégré, avec capture, contextes, paquetisation, vérification et preuve de calibration. | Résumé architecture |

## Questions critiques ou sceptiques

| Question | Réponse orale solide |
|---|---|
| Est-ce que la calibration sert à masquer un mauvais TDC ? | Non. La non-uniformité brute est attendue dans cette architecture. L'objectif est justement d'exporter assez d'information pour qu'une correction externe soit possible et maîtrisée. |
| Si la RMSE brute vaut `1.94 ns`, pourquoi faire confiance à l'architecture ? | Parce que le timestamp brut seul n'est pas le produit final. Le résultat LUT montre que les métadonnées exportées portent l'information nécessaire à la correction. |
| Sans silicium, `18.56 ps` a-t-il une vraie valeur ? | Oui, comme validation numérique du contrat d'observabilité. Non, comme performance physique finale. Il faut garder ces deux niveaux séparés. |
| Avez-vous prouvé que la métastabilité est impossible ? | Non, on ne prouve pas cela au niveau RTL. On réduit le risque avec Gray, synchroniseurs et snapshot stable, puis il faut une revue CDC et une validation post-layout. |
| La vérification prouve-t-elle la fermeture temporelle ? | Non. La vérification fonctionnelle prouve le comportement logique et protocolaire, pas les marges setup/hold, le skew ou le comportement de l'oscillateur réel. |
| Les résultats de moyennage sont-ils trop optimistes ? | Ils doivent être annoncés comme une analyse statistique sur erreurs corrigées. Les `N` supérieurs à `15` ne sont pas une promesse d'une seule conversion matérielle. |
| Le premier hit exporté est-il le premier événement physique ? | Pas nécessairement. Les hits suivent un ordre de scan/paquet déterministe, qui n'est pas automatiquement l'ordre chronologique physique. |
| Que se passe-t-il si la LUT reçoit un paquet hors domaine ? | C'est une étape de travail future : il faudra définir le rejet, le repli, l'extrapolation ou la recalibration selon le domaine d'observables. |
| Les chiffres DNL/INL sont-ils trompeurs si des codes manquent ? | Ils sont valables sur les codes observés. La parcimonie de la grille complète est explicitement reconnue et motive la calibration. |
| Pourquoi deux contextes seraient-ils suffisants à haut débit ? | Deux contextes sont un compromis surface/puissance/lecture. À débit soutenu ou sous rétropression, la saturation est possible et doit être visible et gérée. |

## Questions méthodologiques

| Question | Réponse orale concise |
|---|---|
| Quelle est exactement la clé de LUT ? | Indices de phase lent/rapide inférés, compteurs grossiers, discriminateur de phase STOP, snapshot phase 0 et index du hit. |
| Quel simulateur produit les résultats du rapport ? | Des simulations RTL sous Xcelium. |
| Quelle est la taille de la validation ? | Environ `9 millions` de lignes tenues hors apprentissage. |
| Que signifie "tenue hors apprentissage" ? | Les seeds de validation ne servent pas à construire la LUT. Ils testent donc la généralisation dans le domaine simulé. |
| Comment les indices de phase sont-ils inférés ? | Par l'algèbre Vernier. L'artefact indique que les combinaisons actives de la matrice `8x8` sont distinguables dans ce cadre. |
| Comment DNL et INL sont-elles calculées ? | Par analyse de densité de codes sur les codes effectivement atteints dans la campagne focalisée. |
| Quelle est la différence entre mono-hit et multi-hit ? | Le mono-hit évalue une estimation corrigée. Le multi-hit/moyennage combine plusieurs observations corrigées de façon statistique. |
| Que compare le scoreboard ? | Il compare le comportement paquet attendu par un modèle de référence avec les paquets observés en sortie. |
| Que prouve une suite VIP qui passe ? | Elle donne une confiance fonctionnelle sur les scénarios couverts. Elle ne remplace pas la couverture complète ni le signoff physique. |
| Quels modes de sortie supportent cette LUT ? | RAW_FEATURES et FULL transportent les champs nécessaires. RAW_TIMESTAMP est plutôt diagnostique pour cette LUT. |

## Questions sur les limites et la suite

| Question | Réponse orale concise |
|---|---|
| Quel est le plus grand risque restant ? | La validation physique : CDC, STA, PnR, comportement post-layout de l'oscillateur, jitter et variations PVT. |
| Que faut-il faire après le RTL ? | Synthèse, fermeture temporelle, revue CDC, simulation post-synthèse, simulation post-layout, puis caractérisation silicium. |
| Comment les variations PVT affectent-elles la LUT ? | Elles peuvent déplacer les délais d'oscillateur et la structure de grille. La LUT externe facilite la recalibration, mais il faut caractériser ces conditions. |
| Le jitter est-il modélisé de façon réaliste ? | Pas complètement au niveau RTL. Le jitter réel de l'oscillateur et les effets layout devront être mesurés ou simulés après extraction. |
| Qu'en est-il du délai de front-end avant le démarrage des anneaux ? | Il peut ajouter un offset et du jitter. Il devra être quantifié avec les cellules réelles et le timing post-layout. |
| Quel travail reste pour les outliers ? | Définir les règles de rejet, de fallback et de gestion hors domaine LUT, notamment près des frontières. |
| Que faut-il pour parler de maturité production ? | Couverture fermée, CDC formelle, contraintes robustes, données silicium calibrées et validation système du débit. |
| Peut-on agrandir l'architecture au-delà de `8x8` ? | Potentiellement, mais la surface, la charge sur les phases, le coût de lecture et la complexité de timing augmentent fortement. |
| Que mesurer en premier sur silicium ? | Transfert brut, répétabilité à délai fixe, jitter, dérive PVT, densité de codes, stabilité de la LUT et débit sous rétropression. |
| Quelle est la conclusion honnête ? | L'architecture numérique et le contrat de calibration sont cohérents et prometteurs, mais la performance finale reste à prouver physiquement. |
