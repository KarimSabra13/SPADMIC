# Présentation de soutenance SPADMIC / MPTDC

Fichiers principaux :

- `soutenance_spadmic.tex` : présentation Beamer 16:9 avec slides principales, backups et notes `\note{}`.
- `soutenance_notes_orales.md` : notes de répétition lisibles sans compiler LaTeX.
- PDF attendu après compilation : `../dist/soutenance_spadmic.pdf`.

Compilation Windows avec MiKTeX, depuis ce dossier :

```powershell
pdflatex -interaction=nonstopmode -file-line-error -halt-on-error -output-directory=..\build soutenance_spadmic.tex
pdflatex -interaction=nonstopmode -file-line-error -halt-on-error -output-directory=..\build soutenance_spadmic.tex
Copy-Item ..\build\soutenance_spadmic.pdf ..\dist\soutenance_spadmic.pdf -Force
```

La présentation contient 22 slides principales et 12 slides backup. Elle est volontairement sobre : peu de texte par slide, figures du rapport réutilisées, détails RTL fins déplacés en backup.
