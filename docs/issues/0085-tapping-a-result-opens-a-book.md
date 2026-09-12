Title: Taper un résultat de recherche ouvre un livre
Labels: needs-triage, feature
Type: AFK

## Parent

`docs/prd/0014-search-results-are-editions.md` — [ADR 0002, Move 3](../adr/0002-unified-book-detail.md)

## What to build

C'est l'issue où la feature se voit. Taper « Dune » dans la recherche de l'inventaire et taper le
premier résultat ouvre **un livre**, pas une liste de 66 éditions.

**Un troisième cas d'anchor**, pas une nouvelle destination :

```swift
case bestEditionOfWork(uri: String, title: String, imageUrl: String?)   // stableId: "work:\(uri)"
```

Le titre et l'image sont ceux que le `SearchResult` porte déjà, donc gratuits — et c'est ce qui
remplit l'en-tête pendant la résolution, au lieu d'un écran blanc avec un spinner. `.item`
transporte déjà un `@Model` entier, donc un payload d'affichage sur un anchor n'est pas nouveau.
`stableId` reste dérivé de la seule uri.

**Attention à la garde d'entrée.** `BookAnchor.editionUri` est synchrone et rendra `nil` pour ce
cas ; `BookViewModel.load` commence aujourd'hui par `guard let editionUri else { viewState =
.noResult; return }`. Il faut brancher **avant** cette garde, sinon le nouveau cas tombe
immédiatement en « aucun résultat ».

**Un seul site de push change** : le `case .works` de
`NavigationDestination.destinationForSearchResult`, dont l'unique appelant est
`InventorySearchResultGroup`. Les listes (`EntityListDetail`) et la page auteur
(`AuthorDetailView`) poussent toujours `.work` et ne changent pas. Pas de garde de provenance, pas
de paramètre « d'où je viens ».

**Le picker change de titre.** `nav.work` (« Œuvre ») laisse place à une clé disant « Éditions » /
« Editions » : il n'est plus atteint que depuis un livre, par « Autres éditions », et le mot que
l'ADR 0002 a passé deux moves à faire disparaître n'a pas de raison de reparaître là. Le contenu de
l'écran ne bouge pas.

Une fois l'édition résolue, la suite est le chemin existant : `refreshEdition`, qui upsert
(ADR 0001, invariant 2), puis `BookDetailView` comme d'habitude — « Ton exemplaire », « Communauté »,
« Autres éditions ».

## Acceptance criteria

- [ ] `BookAnchor.bestEditionOfWork(uri:title:imageUrl:)` existe, avec `stableId == "work:\(uri)"`
- [ ] `editionUri` rend `nil` pour ce cas, et `BookViewModel.load` branche avant sa garde
- [ ] L'en-tête (titre + couverture) est à l'écran **avant** la fin de la résolution
- [ ] Taper un résultat de type `works` ouvre `BookDetailView` sur une édition, jamais le picker
- [ ] Taper un résultat de type `humans` ouvre toujours `AuthorDetailView`
- [ ] Ouvrir une œuvre depuis une liste ou depuis une page d'auteur donne le comportement
      d'aujourd'hui, inchangé
- [ ] « Autres éditions » depuis le livre mène toujours au picker
- [ ] Le picker s'intitule « Éditions » en français et « Editions » en anglais ; `nav.work` n'est
      plus référencée
- [ ] Le retour arrière depuis le livre rend la recherche intacte, avec sa requête et ses résultats
- [ ] Tests `BookViewModel` : résolution réussie, et le cas où l'anchor ne résout rien
- [ ] `xcodebuild -scheme ReCIT_iOS … build` et `-scheme ReCIT_iOSTests … test` passent

## Blocked by

- `docs/issues/0084-work-edition-resolver.md`
