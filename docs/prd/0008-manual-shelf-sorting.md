# PRD — Sorting books into étagères, by hand and with help

Status: needs-triage
Area: Inventory / Étagères (see ADR 0001 / 0003 / 0004)
Depends on: PRD 0004 (shelf membership writes), PRD 0006 (auto-sort — this PRD replaces its apply half)
Design: Figma `Nouveau récits`, section `Ranger mes livres` — `Tri manuel · Light` (`115:3276`),
`Tri manuel · Dark` (`120:3636`), `Tri manuel · Appliqué · Light` (`126:3672`), spec panel `117:3526`

## Problem Statement

A collector who has just scanned their library has a flat list of books and, at best, a handful
of étagères. Auto-sort proposes a whole arrangement and asks for a yes or a no: they cannot move
one book, cannot add an étagère the model did not think of, and cannot touch anything the run
left alone. The proposal only ever considers books that are on no étagère, so the shelves they
already built are invisible to it — and where genre coverage is thin, or where Apple
Intelligence cannot run at all, the feature has nothing to offer.

Filing by hand is the fallback, and today it costs one menu per book, from a screen that shows
one étagère at a time. There is nowhere in the app to see every étagère, see what is in none of
them, and move books between the two. So the bookshelf — the app's whole identity — stays half
empty, and the books nobody could classify stay invisible.

## Solution

One screen where the whole library is laid out as it will be filed: every étagère with the books
it holds, and, last, a section titled « À ranger » holding every book that is on no étagère.

Every row has a drag handle. A book is filed by dragging it from one section to another, in
either direction, including straight from one étagère to another. A « + » in the navigation bar
creates an étagère on the spot, so the scheme can grow while sorting. A button asks the on-device
model for a proposal, which arrives as more changes on the same pile — nothing special, just a
faster way of dragging.

**Nothing is written while sorting.** The screen opens on a snapshot of the library and
accumulates a stack of changes on top of it; what it shows is the snapshot with the stack
applied. « Appliquer le rangement » executes the stack — creating the new étagères and moving the
books — and rebuilds a fresh snapshot from what landed. « Annuler » throws the stack away.

Each étagère says which side of that pending work it is on: no pill when it exists on the server
and nothing touches it, « Nouvelle » when it does not exist yet, « Modifiée » when it exists and
its contents have changed. Absence carries the normal state, so what is pending reads at a glance
without counting anything. A one-line recap above the buttons says the same thing in words.

The third button reads « Annuler » while there is something to discard, and « Terminer » when
there is not — so a successful apply turns it into « Terminer » on its own, and taking up sorting
again turns it back.

Because the model is optional, the screen works on any device. Without Apple Intelligence it has
one button fewer, not a wall.

## User Stories

1. As a collector, I want to see all my étagères and their books on a single screen, so that I
   can sort without opening them one at a time.
2. As a collector, I want every book that is on no étagère gathered in one section, so that I can
   see what is left to do.
3. As a collector, I want that section to sit last, so that it reads as the pile that empties
   rather than as an étagère.
4. As a collector, I want to drag a book from « À ranger » onto an étagère, so that filing a book
   is one gesture instead of a menu.
5. As a collector, I want to drag a book off an étagère back into « À ranger », so that a mistake
   is undone the same way it was made.
6. As a collector, I want to drag a book straight from one étagère to another, so that correcting
   a misfiling is one gesture and not two.
7. As a collector, I want every row to carry the same handle, so that the gesture is symmetric
   and I never have to guess which books can move.
8. As a collector, I want to create an étagère while sorting, so that I do not have to leave the
   screen and come back when my scheme needs a shelf it does not have.
9. As a collector, I want a newly created étagère to be usable as a drop target immediately, so
   that creating and filling it is one movement.
10. As a collector, I want to be stopped from naming a new étagère like one I already have, so
    that I do not end up with two shelves I read as the same.
11. As a collector, I want the app to propose an arrangement when I ask for it, so that I do not
    have to start from an empty scheme.
12. As a collector, I want that proposal to land as ordinary changes I can adjust, so that a
    scheme I mostly like is not all-or-nothing.
13. As a collector, I want to ask for a proposal again after sorting by hand, so that the help is
    available at any point and not only on arrival.
14. As a collector, I want a proposal that names an étagère I already have to file books into
    that étagère, so that asking for help does not duplicate my shelves.
15. As a collector on a device without Apple Intelligence, I want the rest of the screen to work,
    so that the feature degrades instead of disappearing.
16. As a collector whose model is still downloading, I want to be told that it is temporary, so
    that I know to come back rather than assume my device cannot do it.
17. As a collector who has switched Apple Intelligence off, I want a route to the setting, so
    that turning it on is one tap away.
18. As a collector, I want my library never to leave my phone, so that what I read stays private.
19. As a collector, I want to see which étagères already exist and which I am about to create, so
    that I know what applying will do to my library.
20. As a collector, I want to see which existing étagères I have changed, so that I can tell an
    untouched shelf from one I have been rearranging.
21. As a collector who drags a book out of an étagère and puts it back, I want that étagère to
    stop being marked as changed, so that the marks describe reality and not my hesitation.
22. As a collector, I want a plain-language recap of what will be saved, so that I can check it
    before committing without scrolling back through the list.
23. As a collector, I want to be told how many books will still be on no étagère, so that I know
    what the session did not solve.
24. As a collector, I want nothing written until I say so, so that sorting is free to experiment
    with.
25. As a collector, I want to abandon the whole session, so that a sorting spree I dislike costs
    me nothing.
26. As a collector, I want the abandon button to be plainly named while there is something to
    abandon, so that I never destroy work believing I am closing a screen.
27. As a collector who has applied everything, I want the same button to become a way out, so
    that finishing is one tap and not a hunt for the back arrow.
28. As a collector who resumes sorting after applying, I want the button to become an abandon
    again, so that it never lies about what it would do.
29. As a collector, I want the apply button inert when there is nothing to apply, so that I
    cannot fire a write that would do nothing.
30. As a collector, I want only what I actually changed to be written, so that untouched étagères
    are not rewritten and a book I moved three times is moved once.
31. As a collector, I want to watch each étagère complete as it is written, so that progress is
    legible without a progress bar.
32. As a collector whose apply fails partway, I want to be told which étagères landed and which
    did not, so that I know the real state of my library.
33. As a collector whose apply fails partway, I want to press the button again and have it finish
    the rest, so that recovery is one tap and never re-does what already landed.
34. As a collector, I want an étagère I emptied to stay in place rather than disappear, so that a
    drag never deletes a shelf behind my back.
35. As a collector, I want a new étagère I left empty not to be created, so that I am not left
    with a shelf to go and delete.
36. As a collector, I want the screen to show what the server actually holds when it opens, so
    that I am not sorting a stale library.
37. As a collector, I want books not to move under my fingers while I sort, so that a background
    sync cannot undo a gesture I am in the middle of.
38. As a collector who leaves mid-save, I want the writing to carry on and the account of it to
    still be there when I come back, so that navigating away cannot lose the record.
39. As a collector, I want the whole screen in my own language, so that it reads like the rest of
    the app.

## Implementation Decisions

**One screen, one write path.** The existing auto-sort review screen is renamed and repurposed
rather than duplicated: it stops being a review-and-apply flow and becomes a working surface. Its
input is the current state of the library plus an *optional* set of changes proposed by the
model. The auto-sort orchestration model stops writing entirely — it keeps its pure pipeline
(genre histogram, mapping validator, plan) and gains a conversion to changes; its apply, its
ledger and its applying/applied phases are removed. The app is left with exactly one
implementation of "create étagères and fill them".

**The working state is an ordered stack of changes**, not a mutable target state. Two cases
suffice: creating an étagère, and moving a book from one section to another, where a section is
an existing étagère, a draft étagère, or the unshelved pile. The move carries its origin as well
as its destination, so coalescing — and any future undo — is a pure function of the stack alone.
A draft étagère carries a prefixed client id, mirroring the optimistic-placeholder convention of
ADR 0001, so a placeholder is never mistaken for a server document.

**The session state is app-scoped, observable, and injected like the other models.** The writes
must outlive the screen, and the ledger that says what landed must still be there when the user
comes back. While an apply is running the screen withdraws its own escape hatch, exactly as the
auto-sort screen already does.

**The snapshot is frozen, behind an opening sync.** The screen syncs shelves and inventory
against the server on open, with a progress indicator, and only then reads the store — once —
into value types. Nothing on the screen observes SwiftData afterwards. This is a deliberate
departure from ADR 0001's rule that the UI is bound to SwiftData and reactive: this screen is a
draft, not a display. The membership gate only stands syncs down *during a write*; across a
sorting session lasting minutes, a sync triggered elsewhere would otherwise rewrite the
shelf-to-item relation wholesale and move books under the user's fingers. Freezing also makes the
projection pure, and therefore testable without a store.

**Two derivations, both pure, both recomputed rather than tracked.**

- *The projection* takes the snapshot and the stack and produces the sections the screen renders.
  It enforces the invariant that every book is in exactly one section — a drop removes before it
  adds — the same partition rule the auto-sort plan keeps by filing a multi-genre book under its
  first genre, and for the same reason: a book in two sections would be written twice.
- *The write plan* takes the same two inputs and coalesces them into the operations to send. A
  book moved three times yields one removal and one addition against the endpoints; a book taken
  off a shelf and put back yields nothing; a draft that ends up empty is not created.

**The write plan is a single deep module, and it is also what feeds the pills and the recap.** It
exposes three readings of one reduction: the operations to execute, the per-étagère status
(new / modified / untouched) that draws the pills, and the counts the recap sentence is built
from. One reduction means pill, recap and write cannot contradict each other — which is the whole
argument for deriving rather than tracking. Writing the "an empty draft is not created" rule
twice, in two modules, is how they would eventually disagree.

**Operations are grouped per étagère**: create if it is a draft, then removals, then additions.
Removals before additions so a book is never on two étagères, even momentarily. A move between
two étagères is therefore split across two groups; if the removal lands and the addition fails,
the book falls back into the unshelved pile — an honest intermediate state, never a lost book.

**Writes are awaited, not optimistic**, the same documented departure from ADR 0001 as the
auto-sort apply and the batch scanner's add: the user has just approved a batch and has to be
able to trust what landed. Only single, user-initiated gestures stay optimistic. Progress is one
mark per étagère, reusing the existing apply-ledger vocabulary (pending, applying, landed,
failed) and the mark already provided for on the design's section header. A tick means both the
creation and the membership write landed; an étagère created but not filled is a failure, not a
partial success.

**Failure stops, keeps what landed, and leaves the rest in the stack.** Every coalesced operation
the server confirmed is removed from the stack and the snapshot is rebuilt as it goes. What
remains in the stack is exactly the work that is left, so the pills are correct again with no
special case, the button rule keeps telling the truth, and pressing apply again resumes.
Re-sending the whole stack would be wrong: the bulk add already drops items a shelf holds and is
therefore idempotent, but the create is not — replaying a creation that succeeded makes a second
étagère of the same name.

**The button rule is derived from whether the stack is empty**, with no "has applied" flag. Stack
not empty: the apply button is live and the third button says « Annuler » and discards. Stack
empty: the apply button is inert and the third button says « Terminer » and closes. A successful
apply empties the stack, so « Terminer » appears by itself; resuming sorting turns it back into
« Annuler », which is true, because there is once more something to discard. A sticky flag would
leave the screen's only destructive button labelled « Terminer ».

**The model's proposal is reconciled against existing étagères at conversion time**, in plain
code: a proposed name whose comparison key matches an existing étagère becomes a move *into* that
étagère instead of a creation. The comparison reuses the auto-sort name key — trimmed, case- and
diacritic-insensitive — which is already written and tested. The prompt is left alone: it took
five rounds to settle and is documented as drifting whenever a constraint is added.

**Availability stops being a wall and becomes a button.** The existing entry-point rule keeps
deciding which of the three unavailability reasons is worth saying and whether a route to
Settings helps; it now governs one button rather than the whole screen.

**Creating an étagère on the spot does not write.** The « + » opens the existing shelf form and
returns a draft onto the stack. That is the one behavioural difference from the carousel's create
action, and it is what makes "create, fill, then save" a single movement. A draft named like an
existing étagère, or like another draft, is refused at the form.

**Dragging crosses sections, so the list's built-in move cannot be used.** Moving a row between
sections needs draggable rows and drop destinations with a typed transfer carrying the book's
identity, the target being a section. There is consequently no edit mode, and the handle is a
visual affordance for the drag rather than a reorder grip. Order within an étagère is not part of
the stack: the membership model carries no user-facing order today. If one is added, reordering
becomes a third kind of change.

**One missing piece in the shelf model**: an awaiting counterpart to the optimistic
remove-from-shelf, so that removals can be part of a batch whose outcome is known per étagère.
The membership call is already shared between the two actions and the sync gate helpers already
exist, so it mirrors the awaiting bulk add.

**Copy enters the string catalogue as real keys with French and English translations**, and
plurals use plural rules rather than ternaries inside interpolations. This deliberately does not
repeat the two divergences recorded against the existing auto-sort screens, whose French literals
are used as keys in a project whose source language is English. Fixing those stays a separate
chore: doing it here would mix a screen rewrite and a localisation pass in one diff.

## Testing Decisions

**Only the pure modules are tested**, which is where every rule that could make the screen lie to
the user lives. A good test here states an external behaviour — given a snapshot and a stack,
this is what the screen shows, this is what gets written, this is what the pill says — and never
reaches into how the reduction is implemented. No test asserts a call order inside a module, a
private helper, or an intermediate structure; each one is a sentence a user could have said.

Modules under test: the projection, the write plan (with its status and summary readings), the
conversion from a model proposal to changes, and the apply ledger.

Prior art, all Swift Testing suites over pure modules of the same shape: the genre histogram, the
shelf mapping validator, the auto-sort plan assignment, the apply ledger, the entry-point rule,
the batch-scan state machine, the transaction state machine, the shelf books layout. The apply
ledger's existing suite moves with the module rather than being rewritten. Where an impure test
is eventually wanted, the repository already has the harness for it — the shelf model's suite
drives the optimistic create against a mocked API service and an in-memory container.

Cases that must be covered, each of them a way the screen could mislead:

1. An empty stack shows an empty recap, an inert apply button, and a third button reading
   « Terminer ».
2. One move makes the apply button live and the third button read « Annuler ».
3. A book dragged out of an étagère and back leaves a non-empty stack that coalesces to nothing:
   no operations at all, and no « Modifiée » pill.
4. A book moved across three sections yields one removal and one addition, against the endpoints
   only.
5. A draft holding books yields one creation carrying its members.
6. A draft left empty yields no creation, and the recap names it as dropped.
7. An existing étagère that loses its last book yields a modification and no deletion.
8. A move from one étagère to another removes once on one side and adds once on the other.
9. A book dropped into the unshelved pile yields a removal and nothing else.
10. Two drafts with the same name, or a draft named like an existing étagère, are refused before
    reaching the stack.
11. A proposal naming an existing étagère produces moves into it, never a creation.
12. A proposal for a device that produced nothing leaves the stack untouched.
13. A creation that lands followed by a membership failure is reported as created-but-not-filled,
    not as not-created.
14. After a partial failure the stack holds exactly the unlanded work, and applying again
    finishes it without repeating anything.
15. The projection keeps every book in exactly one section, whatever the stack.
16. The pills, the recap and the operations always agree — asserted on the same fixtures, since
    they come from one reduction.

## Out of Scope

- Undoing a single change. The stack is ordered, so undo stays cheap to add later; in v1 the
  gesture is its own inverse and « Annuler » is the escape hatch.
- Renaming or deleting an étagère from this screen — both exist elsewhere and both are
  destructive in ways a sorting gesture should not be.
- Reordering étagères, or ordering books within one.
- Multi-select drag.
- Undoing an applied change set. « Annuler » only discards unapplied work.
- Offline queueing: applying needs the server, and says so when it cannot reach it.
- Tests for the session model, the writes and the view. The repository has the harness for them
  if that changes.
- Fixing the existing auto-sort localisation debt.

## Further Notes

The mockups show five sections — two étagères marked « Nouvelle », one existing étagère marked
« Modifiée », one existing étagère with no pill, and « À ranger » with three books — with the
recap and the three buttons at the foot. A third frame shows the same library once applied: no
pills, the recap turned into a report of what landed, the apply button inert, the third button
reading « Terminer ».

Still to design: the row while it is being dragged, the section highlighted as a drop target, the
sync running on open, the proposal being generated, the create form reached from the « + », the
unshelved section when it is empty, and the partial-failure report.

Open questions, none of which block the modules above:

- Is the whole unshelved inventory listed, or a windowed page of it? On a freshly scanned library
  that section is the entire collection.
- What does the recap say when the stack is not empty but coalesces to nothing? "Nothing to save"
  is accurate and may read as a bug.
- Does the opening sync block the whole screen, or show the last known state behind it?
- Does the étagères screen gain an entry point, now that this screen is useful without the model?
