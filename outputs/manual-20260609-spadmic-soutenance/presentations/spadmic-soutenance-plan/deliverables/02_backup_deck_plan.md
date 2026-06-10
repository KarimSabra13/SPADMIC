# Plan du support de secours

Objectif : 10 diapositives de secours. Elles doivent aider à répondre au jury, pas servir de dépôt de contenus non utilisés.

| # | Message de la diapositive de secours | Question probable | Visuel | Réponse clé |
|---:|---|---|---|---|
| B1 | La formule Vernier sépare comptage grossier et information fine de phase. | Pourquoi choisir un Vernier plutôt qu'un compteur ou une ligne à délais ? | Principe Vernier avec formule simplifiée | La finesse vient de la différence entre deux délais proches, sans imposer une horloge système irréaliste. |
| B2 | La matrice `8x8` donne des observables riches mais non uniformes. | Y a-t-il des codes manquants ? Pourquoi l'erreur brute est-elle biaisée ? | Heatmap de phase et note sur les codes observés | La grille est creuse et non uniforme. Le timestamp brut n'est donc pas le produit final visé. |
| B3 | L'implémentation active garde la physique Vernier mais ajoute la logique d'intégration ASIC. | Qu'est-ce qui change par rapport à l'architecture de référence ? | Tableau référence / actif | Ajout de la capture asynchrone, CDC, contextes, FIFO/lecture, paquetisation et calibration externe. |
| B4 | Reset et clear sont deux mécanismes de contrôle distincts. | Pourquoi le séquencement reset/clear est-il important ? | Chronogramme reset/clear | Le reset met le bloc dans un état connu. Le clear réarme une conversion après snapshot et écriture contexte. |
| B5 | Les deux contextes réduisent la dépendance au temps de lecture, mais restent une ressource bornée. | Pourquoi seulement deux contextes ? Que se passe-t-il sous pression ? | Occupation des contextes et rétropression | Deux contextes sont un compromis PPA. La saturation doit être visible et contrôlée par le système. |
| B6 | Le format de paquet transporte les observables nécessaires à la reconstruction hôte. | Qu'est-ce qui est réellement exporté ? | Paquet `16 bit` META/HIT/EOC | La trame contient compteurs grossiers, indices de phase, données de hit, statut et métadonnées de frontière. |
| B7 | La LUT est apprise et validée sur des ensembles séparés. | Comment éviter de surapprendre la correction ? | Flux apprentissage / validation tenue hors apprentissage | Le résultat du rapport est calculé sur des lignes de validation non utilisées pour construire la LUT. |
| B8 | La DNL et l'INL sont données uniquement sur les codes observés. | Les chiffres de linéarité sont-ils trompeurs ? | Courbes DNL/INL avec réserve | DNL pic autour de `0.987 LSB` et INL extrémité autour de `1.553 LSB`, mais seulement sur les codes atteints. |
| B9 | Le moyennage est une analyse statistique post-LUT, pas une promesse sur un événement unique. | Peut-on vraiment annoncer moins de `5 ps` ? | Courbe RMSE versus moyennage | `N=4 -> 9.28 ps`, `N=15 -> 4.77 ps`. Les grands `N` relèvent d'un moyennage d'observations, pas d'une conversion unique. |
| B10 | Les étapes restantes concernent la validation physique et silicium. | Qu'est-ce qui n'est pas encore prouvé ? | Roadmap RTL -> silicium | Il reste l'oscillateur réel, CDC/STA, post-layout, PVT et corrélation sur mesures silicium. |

## Diapositives de secours optionnelles

- Chemin de sortie partagé SPADMIC et TX DDR.
- Inventaire VIP et logique de scoreboard.
- Champs de clé LUT et carte de simplification orale.
- Statut actuel du dead time, avec prudence autour de la note RTL `39 ns`.
