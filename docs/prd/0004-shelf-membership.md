# PRD — Adding and removing books from étagères

Status: needs-triage
Area: Inventory / Étagères (see ADR 0001 / 0003 / 0004)

## Problem Statement

Étagères can be created, renamed and looked at, but their contents are read-only. Membership
arrives from inventaire.io and can only be changed on the website. A user who has just added
a book to their inventory, or who realises a book is on the wrong shelf, has no way to act on
it from the app at all — the shelf they are looking at is a display of someone else's
decision, made elsewhere.

This is the gap that makes the whole bookshelf feel like a viewer rather than a place you
arrange things. The carousel, the painted spines, the press-to-pick gesture and now the paper
labels all present étagères as physical objects you handle, and then nothing can actually be
put on them or taken off.

## Solution

Two entry points, both where the user already is.

From a book, the existing "..." menu gains the ability to file that book onto one of your
étagères, or take it off one it is currently on. When there is only one sensible target the
menu says so outright — *Ajouter à Classiques français* — and only fans out into a submenu
when there is a real choice to make.

From inside an étagère, swiping a book's row offers to take it off that shelf. The book stays
in the inventory; it just stops living there.

Both act immediately: the shelf updates as you watch, and the write goes to inventaire.io in
the background.

## User Stories

1. As a RECITs collector, I want to add a book to an étagère from the book's own screen, so
   that I can file it the moment I am looking at it.
2. As a collector with exactly one étagère the book could go on, I want the menu to name that
   étagère directly, so that filing takes one tap instead of two.
3. As a collector with several étagères, I want a submenu listing them, so that I can pick
   the right one.
4. As a collector, I want étagères the book is already on left out of the add list, so that I
   am never offered an action that would do nothing.
5. As a collector whose book is already on every étagère, I want no add entry at all, so that
   the menu doesn't carry a dead option.
6. As a collector, I want to remove a book from an étagère from the book's own screen, so
   that I can correct a filing mistake without hunting for the shelf.
7. As a collector whose book is on exactly one étagère, I want the menu to name it directly,
   so that removing takes one tap.
8. As a collector whose book is on several étagères, I want a submenu of just those, so that
   I remove it from the right one.
9. As a collector whose book is on no étagère, I want no remove entry, so that the menu stays
   honest about what is possible.
10. As a collector, I want these entries only when I actually own a copy of the book, so that
    the app never offers to shelve something that isn't mine.
11. As a collector with no étagères at all, I want no add entry, so that the menu doesn't
    hint at a feature I have not set up.
12. As a collector browsing an étagère, I want to swipe a book's row to take it off that
    shelf, so that tidying a shelf is a gesture rather than a trip through a menu.
13. As a collector, I want that swipe to make clear the book is being un-shelved and not
    deleted, so that I am not afraid to use it.
14. As a collector, I want the swipe to complete on a long swipe without a second tap, so
    that clearing several books off a shelf is quick.
15. As a collector, I want a removed book to stay in my inventory, so that un-shelving never
    costs me the record of owning it.
16. As a collector, I want the shelf to update the instant I act, so that the app feels like
    it is responding to me rather than to a server.
17. As a collector, I want the book to appear on the étagère's card in the carousel right
    away, so that the shelf I just filled looks filled.
18. As a collector whose network write fails, I want the change rolled back and an error
    shown, so that I never believe a book is filed when it isn't.
19. As a collector, I want a background sync that runs while my change is still in flight not
    to undo it on screen, so that books don't flicker off shelves I just put them on.
20. As a collector, I want a book to be allowed on several étagères at once, so that a book
    that is both science-fiction and a favourite can live on both.
21. As a collector who removes a book from one étagère, I want its membership of other
    étagères untouched, so that one removal doesn't cascade.
22. As a collector, I want the same action available whether I reach the book from my
    inventory, from a shelf, or from search, so that the behaviour is consistent.
23. As a collector using the app in French, I want the menu entries to name my étagères
    exactly as I named them, so that I recognise them.
24. As a collector with a long étagère name, I want the menu entry to remain readable, so
    that I can tell my shelves apart.
25. As a developer, I want the menu's contents derived by a pure function, so that the
    filtering and the 0/1/many shape can be tested without a view.
26. As a developer, I want the write to go through the existing optimistic-mutation helper,
    so that it behaves like every other user-initiated write in the app.
27. As a developer, I want failures surfaced through the shared error reporter rather than
    swallowed, so that a failed removal is visible.

## Implementation Decisions

- **Server contract.** inventaire.io exposes `add-items` and `remove-items` as POST actions on
  the shelves endpoint, each taking the shelf id and a list of item ids, and returning the
  affected shelves keyed by id — a shape the existing shelves response DTO already decodes.
  This was read from the project's last public source, which was archived in May 2025, so it
  must be confirmed with one live call before the implementation is built on it.
- **The menu lives in the book detail screen's existing "..." toolbar menu.** That is the only
  ellipsis menu in the app, and it already resolves whether the current user owns a copy of
  the edition — which is exactly the gate both new entries need, since étagères hold items
  (a specific copy), not editions.
- **Eligibility drives the menu shape.** The add list is the user's shelves minus the ones the
  item is already on; the remove list is the item's current shelves. The "one entry vs
  submenu" rule applies to those filtered lists, not to the raw shelf list. The two lists are
  complements over the same set, so no entry is ever offered that would be a no-op.
- **The menu's contents come from a pure function** taking all shelves plus the item's shelves
  and returning both lists and their presentation shape. No SwiftUI, no network, no context.
- **Writes are optimistic**, per ADR 0001: the local relation is mutated and saved first, the
  network call runs in a model-owned background task, and the change is reverted with the
  error surfaced through the shared reporter if it fails. Success reconciles from the
  response, which carries the server's post-write shelf state.
- **Syncs must not clobber pending writes.** Shelf membership currently has *two* independent
  wholesale writers — the shelf sync's item-linking pass and the inventory sync's per-item
  shelf assignment — both of which assign the relation outright from server state. A sync
  landing between an optimistic write and its confirmation would visibly undo it. Syncs are
  therefore gated while a membership mutation is in flight. The model already tracks its most
  recent in-flight task; note this covers one mutation at a time, which suits menu-driven
  single-book actions and would need a counter if bulk membership writes are added later.
- **The relation is a genuine many-to-many** with a declared inverse, so mutating either side
  moves both. A book may sit on several étagères; removing it from one leaves the others
  alone.
- **The swipe in the étagère detail screen** removes from the shelf being viewed. It is not
  marked destructive and is not red — nothing is deleted, the item stays in the inventory,
  and red would train users to fear a reversible action. Its icon says "off the stack", not
  "trash". Full swipe stays enabled, since the action is cheap and reversible.
- **Errors surface through the shared reporter.** The comparable swipe actions in the lists
  feature discard their errors, which is a pre-existing bug this PRD deliberately does not
  copy; fixing those is worth its own issue.
- **No SwiftData schema change.** The relation already exists and is already populated by both
  syncs.

## Testing Decisions

- **What makes a good test here:** it drives a module's public interface and asserts what
  comes out, not how it got there. Pure, deterministic, no network, no SwiftUI rendering, no
  SwiftData context. It survives a rewrite of the implementation and fails on a change of
  behaviour.
- **Tested: the menu-shape function.** Given the user's shelves and the item's shelves,
  assert the add list excludes what the item is already on; the remove list is exactly the
  item's shelves; each list's 0 / 1 / many form is correct at its boundaries; a book on every
  shelf yields no add entry; a book on none yields no remove entry; a user with no shelves
  yields neither; and the two lists never overlap.
- **Not tested:** the menu view itself, the swipe action, the network layer, and the
  optimistic helper (already exercised by the transaction and list flows).
- Prior art: the shelf books layout suite — pure, seeded, network-free, in the unit test
  target rather than the integration suite that hits the production server.

## Out of Scope

- Bulk membership changes — filing many books onto a shelf in one action. The batch scanner
  and the AI auto-sort PRDs each need their own version of this, and both are separate.
- Choosing an étagère at the moment a book is added to the inventory.
- Reordering books within an étagère.
- Deleting an étagère (covered as a prerequisite in the AI auto-sort PRD).
- Fixing the lists feature's error-swallowing swipe actions.
- Any change to how étagères sync, beyond gating them while a write is pending.
- A context menu or swipe on inventory rows outside the étagère detail screen.

## Further Notes

- The book detail menu will read *Ajouter à une liste* and *Ajouter à une étagère* next to
  each other. Lists and étagères are genuinely different objects here, and the near-identical
  wording is how users will conclude they are the same thing. Accepted for now; the labels
  are worth revisiting once both features have been used.
- Because the item-side and shelf-side syncs both assign membership wholesale, this is the
  first feature where a local write and a sync genuinely contend. If more membership writes
  arrive later, the single in-flight task should become a proper pending-mutation set.
