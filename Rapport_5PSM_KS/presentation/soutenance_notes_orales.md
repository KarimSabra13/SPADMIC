# Notes orales -- Soutenance SPADMIC / MPTDC

Durée cible : 20 à 25 minutes. Les slides 15 ou 18 peuvent être raccourcies si le temps est serré ; l'histoire reste lisible en passant directement de la vérification au résultat principal.

## 1. Titre
Présenter le sujet en une phrase : étude d'un bloc de mesure temporelle intégré dans un prototype ASIC de lecture SPAD. Annoncer que le fil de la soutenance va du contexte SPADMIC jusqu'à l'architecture RTL, la vérification, la caractérisation et les étapes physiques.

## 2. Plan
Expliquer que la présentation part du système, introduit ensuite le besoin de mesure temporelle et le principe Vernier, puis descend vers le MPTDC intégré. Terminer par la vérification, les résultats, les limites et le bilan méthodologique.

## 3. Cadre CNRS / IN2P3 / IP2I
Situer l'alternance : CNRS comme organisme national, IN2P3 pour la physique subatomique et l'instrumentation, IP2I Lyon comme laboratoire reliant détecteurs, acquisition et microélectronique. Le message est que le bloc RTL répond à un besoin d'instrumentation scientifique.

## 4. Besoin de lecture d'une matrice SPAD
Vulgariser : une matrice SPAD produit des impulsions brèves, asynchrones, qu'il faut transformer en données exploitables. Le temps d'arrivée complète l'information spatiale et devient une grandeur utile pour la reconstruction.

## 5. Vue d'ensemble SPADMIC
Montrer que le MPTDC n'est pas isolé : matrice SPAD, trois voies temporelles, bloc de position, arbitrage, FIFO, transmission et hôte de calibration. Indiquer que le travail se concentre sur le cœur temporel tout en gardant le contexte d'intégration.

## 6. Défi technique
Nommer les trois contraintes : précision temporelle, intégration ASIC et exploitabilité des données. Le sujet n'est pas seulement de faire un TDC fonctionnel, mais un bloc intégrable, vérifiable et calibrable.

## 7. Rôle d'un TDC
Définir simplement : un TDC convertit un intervalle START/STOP en code numérique. Introduire les métriques utiles : résolution, plage, linéarité, dispersion et temps mort, sans entrer dans les détails de calcul.

## 8. Principe Vernier
Expliquer que deux anneaux ont des délais proches. Le rapide rattrape progressivement le lent ; la résolution vient de la différence entre les deux délais, pas d'une période absolue. Garder la formule comme seul point mathématique.

## 9. Pourquoi multiphase
Dire que le multiphase observe plusieurs phases en parallèle, densifie les points d'observation et peut réduire le temps nécessaire à la décision. Bien distinguer ce gain architectural pendant une conversion du moyennage statistique présenté plus tard.

## 10. Architecture de référence
Présenter la figure comme le socle théorique : oscillateurs lent/rapide, matrice de détection, compteurs grossiers et mémoire d'échantillonnage. Transition : SPADMIC impose ensuite une adaptation pour en faire un bloc RTL complet.

## 11. Transition vers SPADMIC
Mettre en avant ce qui est conservé et ce qui est ajouté. Conservé : oscillateurs, matrice, compteurs. Ajouté : capture asynchrone, contextes, drain/FIFO/TX et sortie compacte 16 bit.

## 12. Architecture fonctionnelle MPTDC
Insister sur la séparation entre mesure rapide et lecture système. Les événements arment les anneaux et la matrice ; le domaine système récupère ensuite une image stabilisée, puis la lit vers la sortie.

## 13. Capture asynchrone
Présenter les latches START/STOP comme un choix d'architecture. Si START/STOP étaient d'abord échantillonnés par clk_sys, l'incertitude de l'horloge système entrerait dans la mesure. Le système reprend ensuite la main pour nettoyer et réarmer.

## 14. Protocole de mesure et réarmement
Décrire la séquence : attente, mesure active, snapshot, capture contexte, clear/réarmement. Le snapshot protège l'image avant nettoyage ; le double contexte découple la mesure rapide de la lecture plus lente.

## 15. Sortie et calibration externe
Expliquer au niveau système : l'ASIC exporte une trame compacte contenant l'information utile, puis la correction LUT se fait côté hôte. Avantage : silicium plus simple et correction évolutive.

## 16. Vérification fonctionnelle
Présenter une méthode par couches : bancs unitaires, bancs d'intégration, scénarios dirigés et aléatoires, modèle de référence et contrôle des paquets. Éviter les noms de scripts ; insister sur la comparaison attendu/observé.

## 17. Résultat principal de calibration
Lire la slide de gauche à droite : avant LUT, biais fort et RMSE autour de 1,94 ns ; après LUT, erreur recentrée, RMSE à 18,56 ps et P99 à 38,99 ps. Rappeler que ce sont des résultats RTL/Xcelium pré-silicium.

## 18. Moyennage post-LUT
Présenter le moyennage comme une tendance statistique réaliste, bornée à N <= 64. Mettre en avant les seuils utiles : moins de 10 ps autour de N=4 et moins de 5 ps autour de N=15, sans promettre une performance déterministe par hit.

## 19. Limites et travaux en cours
Être sobre : le bloc est cohérent côté numérique, mais les étapes physiques restent structurantes. Citer synthèse, STA, PnR, post-layout, oscillateurs réels, jitter PVT, setup/hold et skew.

## 20. Apport méthodologique
Formuler professionnellement l'apprentissage : raisonner en boucle entre besoin système, architecture, RTL, vérification, données de caractérisation et contraintes physiques. Le travail dépasse l'écriture RTL isolée.

## 21. Conclusion
Finir sur trois messages : architecture intégrée et cohérente, contrat numérique validé et calibrable, prochaines étapes vers timing closure, PnR et silicium. Répéter la phrase finale avec calme.

## 22. Remerciements
Remercier les encadrants, l'équipe microélectronique IP2I, CPE Lyon et le jury. Ouvrir les questions.

## Backups
Les backups couvrent les questions probables : détail Vernier, choix multiphase, trois axes, calibration externe, signification de la RMSE, biais brut, portée de la vérification, signoff physique, timing closure, double contexte, rétropression et limites pré-silicium.
