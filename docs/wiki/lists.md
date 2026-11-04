# Listes

Lists of works or authors, mine and my network's. A list opens as a cover flow with a comment per element; Livres | Présentation pages; visibility chosen in the form.

## Code

- `Features/Lists/` — `EntityListView`, `EntityListDetail`
- `AppModels/List/` — `ListModel`, `ListDTO`
- `Model/UserData/EntityList.swift`

## Features

- [0016 Creating a list or an étagère from a book](features/0016-create-a-list-or-shelf-from-a-book.md) — the "…" menu stops going silent when you own nothing yet
- [0022 The empty Lists tab says what a list is for](features/0022-empty-lists-tab-explains-a-list.md) — a paper tag setting a list beside an étagère, and one that creates the first list
- [0023 A list's type, named in words](features/0023-list-type-labels.md) — the list form's picker says Œuvre, Auteur·ice, Maison d'édition instead of inventaire.io's raw values
- [0024 A list's row shows what it holds](features/0024-list-rows-show-their-covers.md) — the Lists tab fans out each list's first covers and counts its elements in words
- [0060 A list as a cover flow, and adding a book from it](features/0060-list-cover-flow.md) — a list of works or authors opens on its covers in a snapping, turned strip over the selected element, which cross-fades: title, « Mon commentaire » saved optimistically, « Voir la fiche », « Retirer de la liste », the day added; « Ajouter un livre » replaces the tab bar — « Scanner » and « Rechercher », one book at a time; inventaire.io refuses duplicates, so « déjà dans la liste » shows it rather than adding; seen on the simulator in light, collection dialog unseen, e2e not run
- [0061 Moving a book to another list](features/0061-move-to-another-list.md) — « Déplacer dans une autre liste » replaces « Voir la fiche » under the comment: a menu of the other lists of the type, those already holding the book greyed; add, comment, remove, server-first, a SnackBar either way; seen on the simulator up to the menu, no move made, e2e not run
- [0068 Lists in my network, in the Lists tab](features/0068-lists-in-my-network.md) — « Mes listes » by name, then « Dans mon réseau », every friend's lists the most recently changed first, read-only, synced at launch in one `by-creators` request per fifty friends; a line above each name with the count, headed by the friend's picture and name; `content200` added; seen only through `ImageRenderer`, e2e not run
- [0073 A list's description, under a Présentation tab](features/0073-a-lists-presentation-tab.md) — « Livres • 8 » | « Présentation » pinned under a list's navigation bar, changed by a touch; the description whole, then type, « Visible par », created and updated; the add bar only on Livres; friends' lists alike; not seen on a simulator, e2e not run
- [0074 Who may see a list, chosen in its form](features/0074-a-lists-visibility-in-its-form.md) — « Visible par » in the list form on iOS and Android, in its three modes: Moi seul·e, Mes amis, Mes groupes, Mes amis et mes groupes, Tout le monde, read and written by `ListVisibility`; `group:<id>` keys not offered; not seen running, e2e not run
- [0075 Tabs picked up as a lens, and a list's pages turned by a swipe](features/0075-lens-tabs-and-a-lists-pager.md) — the capsule of a reader's profile and of a list lifts, magnifies, follows the finger, rubber-bands past the ends and bounces as it settles (`LensTabPicker`, `LensTabTrack`, public API only); `UserProfilePager` becomes the generic `TabPager`, and a list's Livres | Présentation sit in it, the covers keeping their swipe; seen in a harness only, my lists unseen, e2e not run
