Title: L'œuvre est déjà là — on n'ajoute qu'une édition
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0015-creating-a-book-that-inventaire-lacks.md` — frame `C4`.

## What to build

*La Main gauche de la nuit* existe sur inventaire.io ; c'est cette édition-là qui manque. L'app doit
le dire avant d'écrire, sinon elle crée une deuxième œuvre du même nom.

- Avant la publication, un **premier `resolve` sans `create`** part avec le même seed. Sa réponse dit
  ce qui a été reconnu.
- Quand l'œuvre est reconnue, un écran le montre : l'œuvre, son auteur, son nombre d'éditions, et
  deux choix — « une édition de plus » (retenu par défaut) ou « non, c'est un autre livre ».
- Choix par défaut ⇒ le seed d'œuvre est remplacé par une revendication `wdt:P629` pointant l'uri
  reconnue. Choix contraire ⇒ le seed de labels est conservé et une œuvre est créée.
- Quand rien n'est reconnu, l'écran ne s'affiche pas : on publie directement.
- Un `resolve` à blanc en échec **ne bloque pas** : on publie sans la question, le serveur
  dédoublonnera de son côté.

## Acceptance criteria

- [ ] Une œuvre reconnue déclenche l'écran ; rien de reconnu passe outre
- [ ] Le choix par défaut produit `wdt:P629` avec l'uri reconnue et aucun seed d'œuvre
- [ ] Le choix contraire produit un seed d'œuvre et aucune revendication `wdt:P629`
- [ ] Le titre de l'édition reste celui saisi, jamais celui de l'œuvre reconnue
- [ ] Un `resolve` à blanc en erreur laisse la publication se faire
- [ ] Le lecteur de réponse est couvert par des tests purs, sur une réponse avec et sans œuvre
      reconnue
- [ ] Textes en français et en anglais

## Blocked by

- `docs/issues/0093-choose-an-author-that-already-exists.md`
