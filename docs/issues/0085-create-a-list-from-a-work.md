# 0085 — La ligne de création sur l'écran d'une œuvre

## Parent

`docs/prd/0014-create-a-list-or-shelf-from-a-book.md`

## What to build

L'écran d'une œuvre porte le même sous-menu d'appartenance aux listes que l'écran d'un livre. La
ligne « Ajouter à une nouvelle liste » y apparaît donc aussi, avec le même comportement : formulaire
de création, « Créer et ajouter », l'œuvre entre dans la liste créée, SnackBar.

Le comportement vient du composant partagé et de l'enchaînement de modèle posés par la tranche
liste : il ne reste qu'à monter le modifier de feuille sur cet écran, lui passer le binding, et
donner à la nouvelle ligne son propre identifiant d'accessibilité. La règle ne doit pas dépendre de
l'écran d'où l'utilisateur arrive.

## Acceptance criteria

- [ ] Avec zéro liste, le sous-menu « Listes » apparaît sur l'écran d'une œuvre et contient la ligne de création
- [ ] La ligne ouvre le formulaire, et valider crée la liste avec l'œuvre dedans
- [ ] Le SnackBar nomme la liste créée
- [ ] La ligne porte un identifiant d'accessibilité dérivé de celui du sous-menu de cet écran
- [ ] Le comportement est identique à celui de l'écran d'un livre, sans logique dupliquée

## Blocked by

- `docs/issues/0083-create-a-list-from-a-book.md`
