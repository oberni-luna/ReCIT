# Creating a list or an étagère from a book

Shipped on 2026-09-11 from PRD `docs/prd/0014-create-a-list-or-shelf-from-a-book.md` (deleted —
see `docs/prd/README.md`). Three issues, 0083 to 0085.

## What it does

The « … » menu used to go silent exactly when it had the most to say. With no list and no étagère,
both entries simply vanished: nothing said the features existed, nothing said where to find them.
Filing your very first book meant guessing that somewhere else in the app there was a place to
create a shelf, going there, creating it, coming back to the book, and reopening the menu.

Now neither entry disappears for want of content. Each carries, under its existing containers and
separated from them, a last line — « Ajouter à une nouvelle liste », « Ajouter à une nouvelle
étagère ». With zero containers that line is the only one, and the submenu exists anyway.

Touching it opens the usual creation form, the same one the lists screen and the shelf carousel
use. Its button says « Créer et ajouter », because that is what it does: the container is created,
the book goes into it, the sheet closes, and a SnackBar names where the book landed.

A work screen gets the same line, so the rule does not depend on which screen you came from.

## Technical surface

- **`Features/Components/ContainerCreationRequest`** — a pure type describing the demand: file a
  work into a list yet to be created, file a copy onto an étagère yet to be created.
- **`Features/Components/ContainerCreationSheet`** — one modifier, mounted by each carrier screen,
  reading a binding and mounting the right form. **A `.sheet` placed inside a `Menu`'s content does
  not present reliably**, which is why the screen owns it and the submenu only writes to a binding.
- **`MembershipMenu`** gains an optional creation title and action; supplying the action lifts the
  guard that hides an empty submenu. That is where the rule « jamais de sous-menu vide » lives,
  written **once** for both carriers, with the separator, the last position, and the row's
  `"\(identifier).create"` accessibility identifier.
- **`ListModel.createListAndAddWork`** and **`ShelfModel.createShelfAndAddItem`** — one method
  each. The form calls it and knows neither the order of the server calls, nor the asymmetry of
  optimism, nor the failure rule.
- **The two forms each gain one mode**, through a single optional parameter rather than a pair of
  flags, on the shape of the shelf form's existing draft mode — so a mode cannot be half-enabled.

Carriers: `BookDetailView` (lists and shelves) and `WorkEditionPicker` (lists).

## Notable decisions

- **Creation is awaited, filing is optimistic.** Filing needs the container's *server* id and must
  never post toward an `optimistic:` one, so the button waits for one round trip and shows its
  progress, then files optimistically.
- **The failure rule is asymmetric, and deliberately so.** Creation fails: nothing is created, the
  sheet stays open with its input, the error goes through the SnackBar. Creation succeeds and
  filing fails: **the container stays.** The optimistic filing reverts itself and reports through
  `AppErrorReporter`. An object the user watched being born is never destroyed to make up for a
  second request.
- **`ListModel.createList` now returns the list it inserts**, and throws on an answerless response
  instead of silently doing nothing — a caller chaining a second write must not be handed nothing.
- **The copy is taken by id and resolved after the round trip**, behind `isStillInTheStore`: it can
  be deleted while the sheet is open, and a row that has gone leaves the new étagère standing and
  empty rather than crashing on an invalidated model (issue 0065's pattern).
- **A list created from a book is a works list**, type picker hidden and value forced — the book
  imposes the answer, and a choice betrayed afterwards is worse than a choice absent. Description
  and visibility stay visible on the shelf side, unlike the draft mode, because here they are
  really written.
- **The shelf form's button is asynchronous in this mode only.** That is the feature's single loss
  of liveliness; the carousel path stays optimistic and instant, and the sorting surface's draft
  mode is untouched.
- **One string more than the PRD budgeted.** Story 15 wants a SnackBar *naming* the container and no
  existing key does — `inventory.item.added_to_list` is stale and has no `%@` — so
  `list.added_to_named %@` was added rather than shipping copy that reads as broken French.
- **The creation row is last, not first**, which is a muscle-memory choice: existing containers keep
  their rank, and creation is the way out you look for when none of them fits.

## Known

- On a **work** screen the line appears for a multi-edition work, which is the only case that
  renders `WorkEditionPicker`; a single-edition work renders `BookDetailView`, where 0083 covers it
  behind the pre-existing `edition.workUris.count == 1` rule. That rule is the existing display
  rule the PRD said not to move, and it did not move.
- The PRD put **all new tests, unit or UI, out of scope**, and none were written. The end-to-end
  scenario is unmodified. The accessibility identifiers are laid so the path is coverable later
  without touching the interface.
- The shelf form still writes its French in hard-coded strings. Converting it was explicitly out of
  scope; no new debt was added to it.

## Issues

- `docs/issues/0083-create-a-list-from-a-book.md` — the list path, and the shared infrastructure — f740fa2
- `docs/issues/0084-create-a-shelf-from-a-book.md` — the étagère path — 2ce5383
- `docs/issues/0085-create-a-list-from-a-work.md` — the same line on a work screen — c42a24a
