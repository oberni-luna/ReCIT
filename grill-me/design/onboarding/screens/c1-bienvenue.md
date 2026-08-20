# C1 · Bienvenue — `80:2852` (sombre : `87:3011`)

Frame 393 × 852, fond `background/default`, safe areas 59 / 34. **Pas de barre d'onglets** : c'est un
plein-écran de premier lancement, pas un onglet.

| Élément | Géométrie | Style |
|---|---|---|
| `status bar` | 0,0 393×59 | instance, `Theme=Light` / `Dark` |
| `illustration` | 27,130 338×327 | instance `Shelf Empty Card`, **mot papier et légende masqués** — planche + wash, aucun livre |
| `title` | 24,490 345×88 | `Title/title200`, centré, `foreground/default` — « Vos livres, sur vos étagères » |
| `body` | 32,594 329×69 | `Content/content300`, centré, `foreground/secondary` — « Scannez les codes-barres à la chaîne : la caméra reste ouverte et les livres s'ajoutent l'un après l'autre. » |
| `cta` | 16,690 361×55 | `Button / Large` `Style=Primary` — « Scanner mes livres » |
| `skip` | 16,760 361×23 | `Action/action300`, centré, `foreground/tinted` — « Plus tard » |
| `home indicator` | 0,818 393×34 | instance |

## États et interactions

- Un seul état visuel. Pas de chargement, pas d'erreur : l'écran ne fait aucun appel réseau.
- « Scanner mes livres » ouvre le scanner par lot (modal plein écran existant, `Features/Scanner/`).
- « Plus tard » ferme l'accueil vers l'inventaire vide → `C1b`.
- Les deux réponses sont équivalentes du point de vue du flag : l'accueil ne revient plus.

## Non maquetté

- Comment l'accueil est présenté (sheet plein écran ? racine conditionnelle de l'onglet ?).
- Ce que voit un compte qui se connecte à un inventaire **non vide**.

## Mouvement

**Aucun.** La planche est nue et le reste : l'inventaire est vide, il n'y a aucun livre à poser. Peindre des
dos inventés ici aurait donné une animation, mais aussi une étagère qui ressemble à des données que
l'utilisateur n'a pas. L'écran promet avec des mots ; c'est C2 qui paie, avec ses vrais livres.
Voir `../motion.md`.
