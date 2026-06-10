# Checklist priorisée pour les prochaines 48 heures

## Premières 6 heures : verrouiller le récit

- Figer la colonne vertébrale des 18 slides dans `01_final_18_slide_main_deck_plan.md`.
- Décider si le support cite seulement le résultat du rapport `18.56 ps`, ou s'il ajoute une note interne sur la valeur plus récente du dépôt autour de `24.64 ps`.
- Associer à chaque diapositive un objet de preuve principal et une phrase orale à retenir.
- Supprimer tout titre de diapositive qui ressemble à un simple thème plutôt qu'à une affirmation.

## Heures 6 à 18 : produire les figures P0

- F03 : architecture SPADMIC simplifiée.
- F06 : chronogramme de principe Vernier.
- F09 : comparaison référence versus implémentation active.
- F11 : wrapper MPTDC/ASIC avec interfaces.
- F12 : diagramme fonctionnel du coeur MPTDC.
- F14 : chronogramme reset versus clear.
- F15 : chronogramme du protocole de mesure.
- F16 : flux double contexte et export.
- F19 : pipeline de calibration.
- F20 : figure de synthèse des résultats.

## Heures 18 à 30 : assembler le support

- Construire les 18 diapositives principales avec des corps de diapositive visuels.
- Limiter CNRS/IP2I/équipe à une diapositive compacte.
- Ne pas coller les figures denses du rapport si elles sont illisibles en salle.
- Placer les bitfields, DNL/INL, clé LUT et inventaire de vérification dans les backups.
- Ajouter des notes orales qui expliquent chaque figure non triviale.

## Heures 30 à 38 : construire les backups et la Q&A

- Créer les 10 diapositives de secours à partir de `02_backup_deck_plan.md`.
- Intégrer les réponses de `40_jury_qa_pack.md` dans les notes ou dans un support de préparation.
- Ajouter une diapositive de secours "limites" qui sépare explicitement RTL, post-layout et silicium.
- Garder une note interne sur l'ambiguïté `18.56 ps` versus valeurs plus récentes, pour savoir quel chiffre appartient à quelle source.

## Heures 38 à 44 : répéter

- Faire une répétition complète de 30 minutes avec chronomètre.
- Faire une répétition de la version courte de 20 minutes.
- Travailler les réponses exactes sur calibration, CDC, statut silicium et moyennage.
- Raccourcir toute diapositive qui dépasse son temps cible de plus de 20 secondes.

## Heures 44 à 48 : contrôle qualité

- Test en planche-contact : chaque diapositive doit avoir un rythme visuel lisible et un objet de preuve clair.
- Test plein écran : pas de labels illisibles, pas de mur de texte, pas d'image décorative.
- Test des affirmations : aucune diapositive ne doit confondre preuve RTL/Xcelium et performance silicium.
- Test oral : chaque figure importante doit pouvoir être expliquée en une phrase claire.
- Test des secours : chaque question critique probable doit avoir une réponse prête ou une diapositive de secours.
