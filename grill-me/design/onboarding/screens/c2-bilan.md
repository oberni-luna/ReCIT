# C2 · Bilan du scan — `80:2895` (sombre : `87:3064`)

Même squelette que C1, même géométrie de bouton et de « Plus tard ».

| Élément | Contenu |
|---|---|
| `illustration` | instance `Shelf Card` `Paint=Illustrative`, label masqué |
| `title` | 24,490 345×44 — « 24 livres ajoutés » (`Title/title200`) — **le compte vient de la session de scan** |
| `body` | 32,550 329×69 — « Ils ne sont sur aucune étagère. RECITs peut les répartir pour vous — tout se passe sur votre téléphone, votre liste ne part nulle part. » |
| `cta` | 16,690 361×55 — `Style=Primary` — « Ranger mes livres » |
| `skip` | 16,760 361×23 — « Plus tard » |

## Conditions d'affichage (panneau de spec)

- À la **fermeture du scanner**, si la session a ajouté au moins un livre.
- Et si aucun rangement n'a encore été lancé (flag).
- Session sans ajout → pas de bilan du tout.

## Ce que ça exige du scanner

Le modal de scan doit **compter ses ajouts** et présenter le bilan lui-même à sa fermeture. Aujourd'hui il
ne compte rien : `BatchScanStateMachine` gère un résultat à la fois.

## Titre au singulier

« 1 livre ajouté » / « 24 livres ajoutés » : pluralisation à faire dans le catalogue, pas en Swift
(le code du rangement fait aujourd'hui des `\(n > 1 ? "s" : "")` en dur — à ne pas reproduire).

## Mouvement

Même animation que C1 — les livres se posent un par un (opacité `0 → 1`, `-32 → 0` pt, `easeOut 0.32 s`,
échelon `0.08 s`). Ici elle se lit comme les livres qu'on vient de scanner qui trouvent leur place.
Voir `../motion.md`.
