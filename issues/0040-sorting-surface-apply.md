Title: Applying the rangement, and surviving a failure halfway
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0008-manual-shelf-sorting.md

## What to build

`Appliquer le rangement` executes the write plan.

Operations are grouped per étagère — create if it is a draft, then removals, then additions.
Removals before additions, so a book is never on two étagères even momentarily. A move between
two étagères is therefore split across two groups: if the removal lands and the addition fails,
the book falls back into `À ranger`, which is an honest intermediate state and never a lost book.

The writes are **awaited, not optimistic** — the same documented departure from ADR 0001 as the
auto-sort apply and the batch scanner's add: the user has just approved a batch and has to be able
to trust what landed. Progress is one mark per étagère, reusing the apply ledger's vocabulary and
the mark already provided for on the header component. A tick means the creation *and* the
membership write landed.

This slice adds the awaiting counterpart of the optimistic remove-from-shelf, so a removal can be
part of a batch whose outcome is known per étagère. The membership call is already shared between
the two actions and the sync gate helpers exist, so it mirrors the awaiting bulk add.

### Failure stops, keeps what landed, and leaves the rest in the stack

Every coalesced operation the server confirmed leaves the stack, and the snapshot is rebuilt as it
goes. What remains in the stack is exactly the work that is left — so the pills are right again
with no special case, the button rule keeps telling the truth, and pressing apply again resumes.

Re-sending the whole stack would be wrong: the bulk add drops items a shelf already holds and is
idempotent, but the create is not — replaying a creation that succeeded makes a second étagère of
the same name.

A successful apply empties the stack, so the third button becomes `Terminer` on its own. Sorting
again turns it back into `Annuler`. While the writing runs, the screen withdraws its escape hatch.

## Acceptance criteria

- [ ] Applying creates the new étagères and files the books, and the marks tick off étagère by
      étagère
- [ ] Nothing is written for an étagère the plan says is untouched
- [ ] A book moved three times before applying costs one removal and one addition
- [ ] A failure stops the run, keeps what landed, and reports the three outcomes: created and
      filled, created but empty, never created
- [ ] After a failure the stack holds exactly the unlanded work, and pressing apply again finishes
      it without repeating anything
- [ ] After a successful apply the stack is empty, the pills are gone, the apply button is inert
      and the third button reads `Terminer`
- [ ] Sorting again after an apply turns the third button back into `Annuler`
- [ ] Leaving the screen mid-apply does not stop the writing, and the account of what landed is
      still there on return
- [ ] The apply ledger is asserted without a store
- [ ] Report copy lives in the catalogue, plurals as plural rules

## Blocked by

- issues/0036-sorting-surface-missing-states.md
- issues/0039-sorting-surface-pills-and-recap.md
