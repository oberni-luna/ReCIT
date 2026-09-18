Title: Publier une édition minimale, et l'avoir dans son inventaire
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0015-creating-a-book-that-inventaire-lacks.md` — frames `C2` et `C5`.

## What to build

La feuille ouverte par l'issue 0090 demande deux choses et publie. C'est la tranche qui fait exister
la feature de bout en bout : un ISBN inconnu, un titre, un nom d'auteur, et le livre existe sur
inventaire.io **et** dans l'inventaire du lecteur.

- Un **constructeur de payload pur** prend un brouillon (ISBN, titre, nom d'auteur) et rend la
  requête `POST /api/entities/resolve` : `edition` avec `wdt:P212` (ISBN normalisé, sans tirets) et
  `wdt:P1476` (le titre saisi), `works` avec le label du titre, `authors` avec le label du nom, plus
  `create: true`, `enrich: true`, `strict: true`. Aucune dépendance au réseau, à SwiftData ni à
  SwiftUI.
- Un **lecteur de réponse pur** en tire l'uri **canonique** de l'édition créée. Jamais `isbn:…` :
  c'est le piège que documente déjà la vérification de possession du scanner.
- Un **modèle de création**, `@Observable @MainActor`, dans la couche service, injecté aux deux
  endroits habituels (le `@State` de `RootView` et l'environnement de `MainTabView`).
- L'écriture **attend le serveur**. Rien d'optimiste : un doublon public ne se reprend pas d'un
  revers. Le bouton montre son attente et ne peut pas être tapé deux fois.
- Au retour, l'item d'inventaire est créé depuis l'uri canonique avec les mêmes valeurs par défaut
  que l'ajout du scanner, la feuille se ferme, la rangée passe en confirmation verte et **le
  compteur de session augmente** — un événement neuf de la machine porte cette fin.
- La feuille dit, avant la saisie, que ce qui est écrit sera public.

## Acceptance criteria

- [ ] Titre et nom d'auteur sont les deux seuls champs obligatoires ; publier est impossible tant
      que l'un manque
- [ ] L'ISBN affiché n'est pas modifiable
- [ ] La requête émise porte `wdt:P212`, `wdt:P1476`, les labels d'œuvre et d'auteur, et les trois
      drapeaux
- [ ] L'item d'inventaire est créé depuis l'uri canonique rendue par le serveur
- [ ] La rangée confirme, puis la caméra reprend
- [ ] Le livre créé compte dans le bilan de fin de session, une fois et une seule
- [ ] Le constructeur de payload et le lecteur de réponse sont couverts par des tests purs
- [ ] Le modèle est couvert par un test adossé à `MockURLProtocol`
- [ ] Textes en français et en anglais

## Blocked by

- `docs/issues/0090-the-unknown-row-becomes-actionable.md`
