# README_COPILOT — Contexte et règles de rédaction du rapport 5PSM

## Pourquoi ce fichier existe

Ce document sert de brief de continuité pour les prochaines sessions et les futurs agents travaillant sur `Rapport_5PSM_KS/`.

Il verrouille :

- le contexte global du dépôt,
- le rôle des dossiers racine,
- la ligne éditoriale du rapport 5PSM,
- les règles de rédaction à respecter,
- l'ordre de lecture conseillé pour comprendre rapidement le projet.

Ce fichier n'est pas destiné à être compilé dans le rapport LaTeX. C'est un document de travail.

## Contexte global du dépôt

Le rapport 5PSM porte sur le chip `SPADMIC`, mais `SPADMIC` n'est pas encore totalement finalisé. La rédaction doit donc rester honnête et défendable :

- donner un contexte global bref sur `SPADMIC`,
- poser une base théorique solide sur le `TDC`,
- puis se concentrer sur les parties déjà maîtrisées, documentées et techniquement solides.

Le cœur technique le plus exploitable est le dossier `MPTDC/`, qui documente l'architecture et l'implémentation du `TDC`.

La base théorique prioritaire est la thèse présente dans `sources/TH2021ANNAGREBAHAMINA.pdf`.

Le rapport 4PSM sert surtout de référence de ton et de structure, pas de source technique principale pour `SPADMIC`.

## Lecture correcte des dossiers racine

### `Rapport_5PSM_KS/`

C'est le rapport actif de cette année.

Contenu important :

- `main.tex` : point d'entrée du rapport,
- `chapters/` : chapitres du corps principal,
- `frontmatter/` : page de garde, résumé, acronymes, remerciements,
- `bibliography/` : bibliographie,
- `figures/` : figures à utiliser dans le rapport,
- `preamble/` : configuration LaTeX.

### `sources/`

Contient la source théorique majeure du rapport :

- `TH2021ANNAGREBAHAMINA.pdf`

Cette thèse doit être considérée comme :

- la base principale pour expliquer le principe du `TDC`,
- une source forte pour la partie théorique,
- une source prioritaire pour les figures académiques sur le Vernier TDC,
- une référence importante pour la bibliographie.

### `MPTDC/`

C'est le socle technique principal pour la partie implémentation.

À lire comme :

- la référence sur l'architecture du `TDC`,
- la source des détails sur les blocs, les flux, la calibration, la vérification et l'état du projet,
- la matière à transformer en texte académique pour le rapport.

Points d'entrée prioritaires :

1. `MPTDC/README.md`
2. `MPTDC/docs/01_ARCHITECTURE.md`
3. `MPTDC/docs/09_PROJECT_STATUS.md`
4. `MPTDC/docs/02_OUTPUT_PROTOCOL.md`
5. `MPTDC/docs/05_OFFLINE_CALIBRATION_PLAN.md`
6. `MPTDC/docs/06_DEADTIME_ANALYSIS.md`
7. `MPTDC/docs/04_VERIFICATION.md`

### `Rapport__KARIMSABRA_4PSM/`

Ce dossier contient le rapport 4PSM précédent.

Il faut l'utiliser pour :

- retrouver la voix de rédaction,
- comprendre la densité attendue,
- observer la structure narrative,
- voir comment sont gérés les acronymes, les figures, les annexes et la bibliographie.

Il ne faut pas le traiter comme source technique de vérité pour `SPADMIC`.

### `README.md` (racine)

Le `README.md` racine donne un aperçu global rapide du dépôt `SPADMIC` et du rôle de `MPTDC`.

## Ce qu'il ne faut pas confondre

- thèse dans `sources/` : source théorique,
- `MPTDC/` : source d'implémentation et d'architecture,
- `Rapport__KARIMSABRA_4PSM/` : source de style et de méthode rédactionnelle,
- `Rapport_5PSM_KS/` : livrable final en cours de rédaction.

En pratique :

- la théorie doit venir d'abord de la thèse,
- les détails de conception doivent venir d'abord de `MPTDC/`,
- le ton et la structure doivent s'inspirer du 4PSM,
- le texte final doit être produit dans `Rapport_5PSM_KS/`.

## Ligne éditoriale verrouillée

Décisions validées :

- langue : français,
- ton : très académique et très professionnel,
- niveau attendu : autour de `B2+ / C1-`, sans style trop soutenu ou artificiel,
- usage du `je` : à minimiser fortement,
- recul personnel : très léger, surtout dans quelques bilans ciblés ou fins de chapitre,
- place de la théorie : une partie théorique solide doit précéder la description de l'implémentation,
- contexte `SPADMIC` : bref, puis transition rapide vers les parties déjà maîtrisées,
- taille visée : environ `45 à 60 pages` pour le corps principal.

## Règles de rédaction à respecter

1. Ne jamais écrire comme si `SPADMIC` était déjà totalement finalisé.
2. Bien distinguer :
   - la théorie issue de la thèse,
   - l'implémentation documentée dans `MPTDC`,
   - le contexte plus large du chip `SPADMIC`.
3. Sourcer systématiquement :
   - les concepts théoriques,
   - les figures reprises,
   - les chiffres techniques non triviaux.
4. Ne pas copier brutalement le rapport 4PSM, la thèse ou les docs `MPTDC` :
   - reformuler,
   - restructurer,
   - adapter au contexte 5PSM.
5. Garder des paragraphes clairs, denses mais lisibles.
6. Éviter les formulations trop artificielles.
7. Si un passage parle d'une contribution personnelle, le faire sobrement et rarement.
8. Si un élément n'est pas encore certain techniquement, le présenter comme en cours, hypothèse, perspective ou point à confirmer.

## Priorités de rédaction actuelles

Les premières parties à rédiger ou consolider sont :

1. l'introduction générale,
2. la présentation du `CNRS`, de l'`IN2P3`, de l'`IP2I` et de l'équipe,
3. la partie théorique sur le `TDC`,
4. la transition vers l'architecture implémentée,
5. le lien avec `SPADMIC`.

Ordre logique du rapport :

1. contexte institutionnel,
2. fondations théoriques,
3. implémentation technique,
4. positionnement dans `SPADMIC`,
5. résultats, limites et perspectives.

## Ordre de lecture recommandé pour une nouvelle session

1. ce fichier,
2. le `README.md` racine,
3. `Rapport_5PSM_KS/main.tex`,
4. les chapitres déjà présents dans `Rapport_5PSM_KS/chapters/`,
5. la thèse dans `sources/TH2021ANNAGREBAHAMINA.pdf`,
6. `MPTDC/README.md`,
7. `MPTDC/docs/01_ARCHITECTURE.md`,
8. `MPTDC/docs/09_PROJECT_STATUS.md`,
9. les autres docs `MPTDC` selon le besoin,
10. le rapport 4PSM pour retrouver la voix et la structure.

Si un `plan.md` de session existe, il faut aussi le lire avant de modifier le rapport.

## Consignes pratiques pour les futurs agents

- Pour compiler le rapport, utiliser en priorité `./build_pdf.sh` depuis `Rapport_5PSM_KS/`.
- Le script gère la vérification des dépendances, la compilation complète et la copie du PDF final dans `dist/rapport_5psm.pdf`.
- Ajouter les nouvelles références dans `Rapport_5PSM_KS/bibliography/references.bib`.
- Ajouter les nouvelles figures dans `Rapport_5PSM_KS/figures/`.
- Si une figure de la thèse est reprise, mentionner clairement la source dans la légende et dans la bibliographie.
- Préférer une progression par sous-sections claires plutôt qu'un long bloc de texte opaque.
- Vérifier si un passage contient encore des restes de `PICMIC` qui devraient être remplacés ou recontextualisés vers `SPADMIC`.
- Ne pas traiter le rapport 4PSM comme un texte à recycler tel quel.
- Ne pas faire semblant d'avoir des résultats finaux si ce n'est pas documenté.

## Intention générale à conserver

Le rapport 5PSM doit donner l'image d'un travail :

- sérieux,
- maîtrisé,
- bien documenté,
- techniquement crédible,
- honnête sur l'état réel du projet,
- et rédigé dans une voix académique cohérente avec le parcours de Karim.
