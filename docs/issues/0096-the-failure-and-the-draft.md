Title: Quand ça ne passe pas — le brouillon reste, et les mots le disent
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0015-creating-a-book-that-inventaire-lacks.md` — frame `C7`.

## What to build

L'écriture n'est pas optimiste : c'est donc à l'échec d'être soigné. La tranche ferme la feature.

- Un échec de publication pose un encart d'erreur en tête de feuille, dans le ton d'erreur du design
  system, et **garde le brouillon entier** — titre, auteur choisi, photo prise, œuvre rattachée.
- Il dit ce qui compte : rien n'a été créé sur inventaire.io, donc réessayer ne fait pas de doublon.
- Deux sorties : réessayer, ou garder le brouillon et revenir à la caméra.
- Une erreur d'authentification (`401`) dit que contribuer demande un compte, plutôt que d'échouer
  muettement.
- Réessayer est un **geste de l'utilisateur, jamais une boucle** — l'upload d'image est limité à
  cinquante requêtes avec une seconde entre deux.
- Passe finale : libellés d'accessibilité, français et anglais complets, identifiants `e2e.*` sur le
  formulaire, l'erreur et la confirmation.

## Acceptance criteria

- [ ] Une publication en échec laisse la feuille ouverte, tous les champs remplis
- [ ] L'encart dit que rien n'a été créé côté serveur
- [ ] Réessayer republie le même brouillon
- [ ] « Garder le brouillon » revient à la caméra sans rien perdre à la réouverture
- [ ] Un `401` produit un message qui parle de compte
- [ ] Aucune reprise automatique
- [ ] Tous les textes existent en français et en anglais
- [ ] Le scénario end-to-end peut atteindre chaque élément par son identifiant `e2e.*` — **sans que
      `scripts/e2e.sh` soit joué dans cette issue**

## Blocked by

- `docs/issues/0091-publish-a-minimal-edition.md`
