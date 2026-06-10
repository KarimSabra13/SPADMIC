# Pack de survie pour le jury

## Claims principaux à défendre

1. SPADMIC a besoin d'un timing fin, mais aussi observable, exportable et compatible avec une intégration ASIC.
2. Le Vernier multiphase est un choix défendable car il tire la finesse temporelle d'une différence de délais et enrichit l'observation de phase.
3. Le MPTDC actif n'est pas une simple recopie théorique : il ajoute capture asynchrone, CDC, deux contextes, lecture par paquets, watchdogs et calibration externe.
4. Le séquencement snapshot avant clear est central pour préserver l'intégrité de la mesure.
5. La trame exportée n'est pas seulement un timestamp compact : c'est un flux d'observables conçu pour la calibration.
6. Le résultat de calibration RTL/Xcelium du rapport valide le contrat numérique, pas la performance physique finale.

## Formulation exacte du résultat

Formulation recommandée :

"Dans la campagne de caractérisation du rapport final, la validation RTL/Xcelium tenue hors apprentissage réduit la RMSE brute d'environ `1.94 ns` à `18.56 ps` après correction LUT côté hôte, avec un P99 de l'erreur absolue à `38.99 ps`. Je présente ce résultat comme une validation pré-silicium du flux d'observables et de calibration, pas comme une performance mesurée sur silicium."

## Attaques probables et réponses sûres

| Attaque | Réponse sûre |
|---|---|
| L'erreur brute est énorme. | Oui, et c'est précisément le point : la grille brute Vernier est non uniforme. L'architecture exporte des observables riches pour corriger l'erreur de classe côté hôte. |
| La calibration masque une faiblesse matérielle. | La calibration fait partie du contrat d'architecture. Elle simplifie le silicium et rend la correction adaptable après caractérisation. |
| `18.56 ps` n'est pas du silicium. | Exactement. C'est une preuve RTL/Xcelium pré-silicium, pas une performance physique finale. |
| La CDC est risquée. | Oui. Le RTL utilise Gray, synchroniseurs et snapshot stable, mais une revue CDC complète et le post-layout restent nécessaires. |
| Le moyennage est survendu. | L'affirmation principale reste la RMSE mono-observation après LUT. Le moyennage est un résultat statistique, à formuler avec les seuils `N=4` et `N=15`. |
| Deux contextes peuvent saturer. | Oui. Deux contextes sont un compromis PPA. La saturation doit être visible par statuts/rejets et gérée au niveau système. |

## Limites à assumer clairement

- Pas encore de mesure silicium.
- Pas encore de comportement post-layout final de l'oscillateur.
- Pas d'affirmation de signoff STA/CDC complet.
- Pas de garantie que `18.56 ps` soit la dernière valeur globale du dépôt.
- DNL/INL valables sur les codes observés uniquement.
- Moyennage : preuve statistique côté analyse, pas précision déterministe d'un hit unique.
- PVT, jitter réel et paquets hors domaine LUT restent des sujets de suite.

## Travaux futurs à citer

- Finaliser ou remplacer les hypothèses de macro-oscillateur.
- Réaliser une revue CDC et une STA de niveau signoff avec clocks générées et exceptions asynchrones justifiées.
- Rejouer la caractérisation après synthèse puis après layout.
- Formaliser la génération des LUT et la gestion des paquets hors domaine.
- Valider la répétabilité à délai fixe et la dérive PVT.
- Corréler les prédictions RTL/post-layout avec les mesures silicium.
