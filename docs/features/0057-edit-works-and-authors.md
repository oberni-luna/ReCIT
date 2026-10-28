# Modifier une œuvre et un·e auteur·ice, chacun avec son « Enregistrer »

Shipped on 2026-10-28, on `main`, in autopilot: three slices (PRD 0030, issues 0145 to 0147, deleted since), three
commits. Design: the Figma section `Modifier l'édition, l'œuvre et l'auteur·ice · V2` (`814:5090`, page
`Inventaire`) — `W1` « Modifier l'œuvre » (`815:6686` light, `815:7640` dark), `A1` « Modifier l'auteur·ice »
(`815:7335` light, `815:8028` dark), spec `814:5215`. It follows [feature 0050](0050-every-bibliographic-datum.md),
whose « Modifier l'œuvre » only changed a title and authors, and sent them with the edition's « Enregistrer ».

## What it does

**« Modifier l'œuvre »** opens when a work of « Édition de » that inventaire.io has is touched. It shows everything
inventaire.io accepts on a work:

- **L'œuvre** — the title, one field per language the work has, then « Ajouter le titre dans une autre langue », a
  menu of the languages it has none in; the type, from a menu of six (œuvre littéraire, œuvre écrite, bande dessinée,
  roman graphique, manga, manhwa); the form, pushed list of thirty-one (roman, nouvelle, pièce de théâtre, recueil de
  poèmes…); the original language; the date of first publication.
- **Auteur·ices** — added from the search, swiped away; a person inventaire.io has carries a chevron to « Modifier
  l'auteur·ice ».
- **Ont aussi fait cette œuvre** — script, illustrations, editorial direction. **Bande dessinée** — pencils, inks,
  colours, lettering. Every role is shown, whatever the type.
- **Série** and the rank in it, typed. **Genre et sujet** — genres, main subjects. **Liens avec d'autres œuvres** —
  based on, inspired by, published in, in reply to.
- **Bases bibliographiques** (twenty catalogues), **Sur le web** (ten kinds of link), **Autres données** — « À ne pas
  confondre avec ».

**« Modifier l'auteur·ice »** opens from a work's authors, and from the list of any role — the edition's translators,
illustrators, preface writers, the work's script or pencils — for a person inventaire.io has. It shows their name per
language and one more; pseudonyms, typed in place and swiped away; writing languages; dates of birth and death; their
movement and who influenced them; twenty-nine catalogues; eleven kinds of link (LinkedIn added); « À ne pas confondre
avec ».

**Each screen has its own « Enregistrer »**, pinned at the foot, greyed while nothing has changed. It sends that entity
alone, then goes back one screen; what was being changed underneath stays as it was, not yet saved. A failure stays on
the screen, with the edition's banner, and « Réessayer » sends only what has not gone through. A note under the first
section says the change applies to every edition of the work, or every work of the person.

**Going back over unsaved changes** asks « Quitter sans enregistrer ? » — « Quitter » drops them. The system's back
button is replaced while there is something to lose, which also takes the edge swipe away.

A saved work's new title and authors show at once in its row of « Édition de »; a saved name shows at once among the
work's authors and the edition's people. The book screen's store is refreshed (`refreshWork`, `refreshAuthor`).

A work being created from « Édition de », or a Wikidata work, keeps the former screen: title and authors, sent with the
edition.

## Technical surface

**On the wire.**
- Reading: `GET /api/entities/by-uris?attributes=info|claims|labels` for the entity, then one call with
  `attributes=labels` for every entity its claims name. No `relatives`: it does not know every property a work or a
  person can name.
- Saving: `POST /api/entities` for each person to create (`wdt:P31` `wd:Q5`), then one
  `PUT /api/entities/update-claim` per value added or removed, then one `PUT /api/entities/update-label` per label
  changed or added. Not optimistic, like feature 0049.
- A rank in a series (`wdt:P1545`) goes out as a string; the server's datatype is `positive-integer-string`.

**Types.**
- `EditionProperty.Catalogue` — `.edition`, `.work`, `.human` — says which properties a form holds. A uri is looked up
  in its form's catalogue: a work's `wdt:P407` is its original language, its `wdt:P648` takes `OL…W` where an edition's
  takes `OL…M` and a person's `OL…A`. The work and human catalogues are in `EditionProperty+Work.swift` and
  `EditionProperty+Human.swift`, read on 2026-10-28 from `/api/data/properties`, `/api/data/property-values` and the
  server's `properties_values_constraints.ts`.
- New kinds of value: `.choice` (fixed uris, `EditionPropertyChoice`), `.text`, `.ordinal`, `.anyEntity` (a search
  among several types: a main subject among genres, movements, people and works; a related work among works and
  series). ISNI spaces are stripped, as the server does.
- `EditionProperties` carries its catalogue and gained `rename(uri:label:)`.
- `EntityEdit` is a work or a person against the server: labels per language and properties, `nextStep` over
  `EditionEditStep`'s `createEntity`, `claim` and `label`. `EntitySaveFailure` carries it as far as it got.
  `EntityCreationModel.editableEntity(uri:)` reads it, `saveEntity(_:)` saves it.
- `EditionEdit.workSaved(_:)` and `rename(uri:label:)` show a saved entity in the edition without anything to send.

**Views.**
- `EditEntityView` — loading, failure banner, save bar, leave dialog — holds `EditWorkFormView` or
  `EditAuthorFormView`. The edits live in `EditEditionFlowView`, keyed by uri, dropped when their screen leaves the
  stack. Two steps: `EditEditionStep.entity(uri:)` and `.entityProperty(uri:step:)`.
- The edition's pushed screens serve the entities: `EditionPropertyDestination` resolves a uri in the catalogue of
  the values it writes into, `PublicationDateView` takes its property, `IdentifierCatalogView` its catalogue,
  `EditionEntityValuesView` opens a person. `EditionPropertyStep.publicationDate` became `.date(property:)`, and
  `.choice(property:)` was added.
- New rows: `EntityLabelRows`, `EditionChoiceMenu`, `EditionChoiceButton`, `EditionChoiceListView`,
  `EditionDateButton`, `EditionLiteralField`, `EditionTextValuesRows`, `EditEntityPropertiesSection`,
  `EditEntityPersonRow`.

## Notable decisions

- **One screen, one entity, one « Enregistrer »** — W1 saves the work, A1 the person, the edition's form the edition,
  works attached or detached included (they are `wdt:P629` claims of the edition).
- **Every role is shown**, comics included, as on the website — for now.
- **A note is enough** to say a change reaches every edition or every work; no warning.
- **An emptied label blocks « Enregistrer »**: `update-label` cannot remove one. An empty new one is not sent.
- **Nothing is created from these screens but people**: not a series, a genre, a movement, a work.
- **The language menu offers twenty-seven languages**; any other is added on the website.

## Not done, not verified

- **Nothing has been saved for real**: every entity is public. Saving is tested against a mock server only (1023
  tests pass).
- **Seen on the simulator, signed in, read only**: W1 for an inventaire.io work, the list of forms, a form chosen,
  « Quitter sans enregistrer ? » and the screen read afresh afterwards; an author added from the search with its
  chevron; A1 opened from it. Not seen: a save, a failure, the date and identifier screens from W1 or A1, a
  pseudonym typed, light mode, the edition's role lists opening A1.
- **e2e not run.**
- **Wikidata works and people stay read-only** — an inventaire.io work's Wikidata author has no chevron.
- **A related work (`wdt:P144`…) does not open W1**, and a person named in « Influencé·e par » opens A1 only from its
  list of values.
- **Dates before the common era** are not handled by the date screen.
- **No portrait**: a person's picture comes from Wikidata; `invp:P2` is an edition's alone.
- **Android not ported.**
- **The committed `EditEntityView` pins its bar with `safeAreaInset`**, the API at the base commit; the working copy,
  on top of the pending `formActionBar(_:)` refactor, uses that instead.

## Divergences with Figma (code is the source of truth)

- The type is a menu, the form a pushed list, as in Figma; the date is a pushed screen, not a menu (as in 0050).
- « Pseudonymes » is a list of typed values, not a single row.
- W1's « Autres données » holds only « À ne pas confondre avec »; its links are in « Sur le web », as the edition's.
- The links section is « Sur le web », with « Ajouter un lien », as in 0050.
