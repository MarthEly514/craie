# Craie

Maquette `.god2` de l’application mobile de gestion des salles et du matériel
pédagogique (cahier des charges du Groupe 1). Elle s’ouvre dans god2-design.

```
python3 maquette/build.py   # regénère craie.god2 (35 écrans, téléphone 390×844)
```

`refs/UI_base.jpg` est la référence graphique. Palette relevée dessus :

| jeton | valeur | rôle |
|---|---|---|
| `--encre` | `#173300` | texte des titres, bouton principal, onglet et segment actifs |
| `--lime` | `#9fe970` | accent : bouton d’appui, « Libre », onglet actif, bouton flottant |
| `--lime-clair` | `#e6f8d8` | notes, ligne choisie |
| `--surface` | `#f0f3ec` | lignes, cartes, champs de recherche, boutons secondaires |
| `--fond` | `#ffffff` | les écrans |
| `--toile` | `#e3e2de` | le fond autour des téléphones |
| `--discret` | `#66735d` | texte secondaire |
| `--corail` | `#c4432b` | pris, refusé, suppression (seule couleur hors du vert) |

Formes : boutons et champs en pilule, cartes à 26–28 px de rayon, icônes au
trait de 1,7, illustrations d’accueil en noir et blanc.

Ajout du dossier "pages"
