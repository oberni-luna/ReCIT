Title: La langue de l'édition se déduit de l'ISBN
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0015-creating-a-book-that-inventaire-lacks.md` — frame `C2`.

## What to build

Le code-barres sait déjà dans quelle langue est le livre : `GET /api/data/isbn?isbn=…` est **public**
et rend `groupLang` (`fr` → `wd:Q150`). On ne pose donc pas la question.

- Appel public, sans session, au moment où la feuille s'ouvre.
- La langue obtenue devient `wdt:P407` dans le seed d'édition, et s'affiche en une ligne sous
  l'ISBN — « Langue déduite : français ».
- **Échec, langue inconnue ou groupe sans langue ⇒ la revendication est omise**, jamais devinée, et
  la ligne disparaît. La publication n'est pas bloquée pour autant.

## Acceptance criteria

- [ ] L'appel part sans cookie de session
- [ ] Un ISBN français produit `wdt:P407 = wd:Q150` dans la requête `resolve`
- [ ] Un appel en échec ne produit aucune revendication de langue et n'empêche pas de publier
- [ ] La ligne n'apparaît que quand une langue a été trouvée
- [ ] La règle « uri connue ou rien » est couverte par un test pur du constructeur de payload

## Blocked by

- `docs/issues/0091-publish-a-minimal-edition.md`
