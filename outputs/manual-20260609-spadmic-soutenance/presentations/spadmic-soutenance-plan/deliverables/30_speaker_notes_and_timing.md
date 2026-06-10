# Notes orales et minutage

## Plan de parole sur 30 minutes

| # | Temps | Note de présentation |
|---:|---:|---|
| 1 | 1:00 | Présenter le sujet en une phrase : un bloc de mesure temporelle intégré dans un prototype ASIC de lecture SPAD. |
| 2 | 0:50 | Dire que la soutenance suit une chaîne d'ingénierie, pas le sommaire du rapport. |
| 3 | 1:20 | Garder le contexte institutionnel court. Ne pas passer plusieurs minutes sur CNRS/IP2I. |
| 4 | 1:30 | Expliquer le système SPADMIC global et pourquoi le MPTDC reste intégré dans une chaîne de lecture complète. |
| 5 | 2:00 | Poser le problème comme compromis : résolution, plage, réarmement, observabilité, sortie, faisabilité ASIC. |
| 6 | 1:45 | Expliquer le rattrapage Vernier simplement, sans dérivation longue. |
| 7 | 1:45 | Utiliser la matrice `8x8` pour expliquer l'observation enrichie. Bien séparer multiphase et moyennage. |
| 8 | 1:40 | Expliquer la transformation de la référence vers l'actif : la théorie seule ne suffit pas pour un bloc ASIC. |
| 9 | 1:40 | Orienter le wrapper : entrées, reset/contrôle, sorties. Rester au-dessus du détail pin par pin. |
| 10 | 1:50 | Expliquer la non-uniformité avant les résultats de calibration. Cela évite l'effet "magie" de la LUT. |
| 11 | 2:00 | Dérouler le protocole : attente, mesure, snapshot, capture contexte, clear. Phrase clé : pas de clear avant protection. |
| 12 | 1:35 | Distinguer reset global et clear de conversion. C'est une question classique de jury. |
| 13 | 1:40 | Expliquer les contextes comme images stockées, pas comme duplication de matrice. Mentionner la saturation contrôlée. |
| 14 | 1:30 | Expliquer pourquoi la trame compacte est utile pour la calibration et réaliste pour l'intégration. |
| 15 | 2:00 | Présenter la vérification par familles de risques, pas par liste brute de tests. |
| 16 | 1:40 | Expliquer la LUT externe comme choix d'architecture, pas comme rustine. |
| 17 | 2:10 | Lire le résultat avec prudence : `1.94 ns -> 18.56 ps`, P99 `38.99 ps`, RTL/Xcelium, validation tenue hors apprentissage. |
| 18 | 2:20 | Conclure sur contribution, limites honnêtes et prochaines étapes vers la validation physique. |
| Total | 30:00 |  |

## Ouverture proposée

Bonjour, je vais présenter le travail réalisé sur SPADMIC, un prototype ASIC de lecture de matrice SPAD, avec un focus sur son coeur de mesure temporelle MPTDC. L'objectif n'est pas seulement de montrer un TDC Vernier multiphase, mais d'expliquer comment ce principe a été transformé en bloc RTL intégrable, vérifiable et calibrable. Je suivrai donc la chaîne d'ingénierie complète : besoin système, choix d'architecture, protocole de mesure, vérification, calibration et limites pré-silicium.

## Conclusion proposée

Le résultat principal est un MPTDC cohérent avec les contraintes SPADMIC : capture asynchrone, matrice Vernier multiphase, protection par contexte, sortie compacte et calibration externe. La validation RTL/Xcelium montre que les observables exportées suffisent à corriger le biais brut, avec `18.56 ps` de RMSE après LUT et `38.99 ps` en P99, tout en restant un résultat pré-silicium. La suite logique est la fermeture temporelle, le passage post-layout et la confrontation aux mesures silicium, qui diront jusqu'où ce contrat numérique se maintient dans le circuit physique.

## Version d'urgence en 20 minutes

| Slides | Temps | Règle de compression |
|---|---:|---|
| 1-2 | 1:00 | Sujet en une phrase, roadmap en une phrase. |
| 3-4 | 1:25 | Contexte seulement pour justifier les contraintes. |
| 5 | 1:30 | Garder le problème d'ingénierie complet. |
| 6-7 | 2:00 | Expliquer Vernier et multiphase ensemble. |
| 8 | 1:25 | Garder la transition référence vers architecture active. |
| 9 | 0:45 | Wrapper en une phrase. |
| 10-14 | 5:50 | Fusionner architecture, protocole, contextes et sortie. |
| 15 | 1:35 | Méthode de vérification et risques couverts. |
| 16 | 1:00 | Raison d'être de la LUT externe uniquement. |
| 17 | 2:15 | Chiffres principaux avec réserve RTL/Xcelium. |
| 18 | 2:00 | Contribution, limites, prochaines étapes. |
| Total | 20:00 |  |

## Si le temps déborde

- Réduire d'abord le contexte institutionnel.
- Compresser Vernier et multiphase dans une même explication.
- Éviter les noms de signaux RTL sauf question directe.
- Garder la réserve pré-silicium dans la diapositive résultat.
- Ne pas supprimer la conclusion sur les limites et la suite physique.
