# Design capture — onboarding (option C, retenue)

Source : Figma `Nouveau récits`, file key `S7IvC6GvlcUFe5IgbtvQq6`, page `Screens` (`20:4`).
Section : `Onboarding` (`73:2829`).
Lien : https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=73-2829

Trois propositions ont été maquettées le 2026-08-20 ; **C est retenue**. A (`81:2863`) et B (`81:2877`)
restent dans la section comme trace des arbitrages.

## Frames en scope

| Frame | id | x,y | Rôle |
|---|---|---|---|
| `C1 · Bienvenue` | `80:2852` | 80, 2380 | Premier lancement, inventaire vide |
| `C1 · Bienvenue · Sombre` | `87:3011` | 2445, 2380 | Mode `Dark` épinglé, chrome `Theme=Dark` |
| `C1b · Après « Plus tard »` | `87:2880` | 553, 2380 | Inventaire vide, invitation retombée sur la planche |
| `C2 · Bilan du scan` | `80:2895` | 1026, 2380 | Fermeture du scanner, ≥ 1 livre ajouté |
| `C2 · Bilan du scan · Sombre` | `87:3064` | 2918, 2380 | idem, mode `Dark` |
| `C2b · Rangement indisponible` | `87:2960` | 1499, 2380 | Apple Intelligence désactivée |
| `C3 · Rangement proposé` | `80:2708` | 1972, 2380 | Approximation de `AutoSortPlanView` — **existant**, cible du CTA |
| `Commun · Scanner par lot` | `81:2847` | 2100, 160 | Clone de `57:2401`, non modifié |
| `Spec · C` | `81:2891` | 3450, 2380 | Déclencheurs, flags, indisponibilité, questions ouvertes |

Pas de variante sombre pour `C1b` et `C2b` : états dérivés, à décliner à l'implémentation.

## Le flux maquetté

```
lancement + inventaire vide + accueil jamais répondu
      └─ C1 ── « Scanner mes livres » ─→ scanner par lot (existant, 0007)
      │                                        └─ fermeture, ≥1 livre ajouté ─→ C2
      │                                                                          ├─ « Ranger mes livres » ─→ C3 (AutoSortPlanView)
      │                                                                          └─ « Plus tard » ─→ inventaire
      └─ « Plus tard » ─→ C1b (inventaire vide, mot sur la planche)

IA indisponible au moment de C2 ─→ C2b (raison + Réglages)
```

## Ce que la maquette ne dit pas

- Rien sur la permission caméra : le scanner a son propre écran de refus (`scanner.permission.*`), non maquetté.
- Rien sur le premier lancement d'un compte **qui a déjà des livres** (connexion sur un inventaire existant).
- Rien sur l'animation / la transition entre le scanner et C2.
