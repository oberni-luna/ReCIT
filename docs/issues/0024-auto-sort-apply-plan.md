Title: Auto-sort — apply an approved plan
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0006-ai-auto-sort.md

## What to build

Turn an approved plan into real étagères: create each shelf, then file its books onto it,
while the user watches.

**The review list becomes the progress list.** Each proposed étagère already shows in issue
0023's review screen; give each one an empty checkmark that fills once *both* its creation and
its membership write have landed. A shelf that fails shows an error mark instead. No separate
progress screen, and the partial-failure state explains itself.

**The two stages are sequenced per shelf, not parallel** — the membership call needs the shelf
id the creation call returns.

**Applying waits rather than being optimistic.** A documented departure from ADR 0001,
alongside the batch scanner's add, for the same reason: the user has just approved a large
mutation and has to be able to trust what landed. Eight étagères appearing instantly and then
some silently vanishing is the failure mode being avoided.

**Partial failure stops and keeps what landed.** No rollback. A rollback that itself fails
mid-way leaves a worse state than a clearly reported partial one, and the report tells the
user exactly which étagères were created and which were not.

Re-running after a partial failure does the right thing rather than duplicating, because the
plan only ever considers books on no étagère — the books that already landed are no longer
candidates. That property is why the unshelved-only scoping was chosen, and it is worth
testing explicitly.

The membership write is the one built in issue 0015; this slice does not add a second path to
the same endpoint.

## Acceptance criteria

- [ ] Approving a plan creates the proposed étagères and files their books.
- [ ] Each étagère in the list gains a filled checkmark once both its creation and its membership write complete.
- [ ] A failed étagère shows an error mark rather than a checkmark.
- [ ] The shelf creation and its membership write are sequenced, the second using the id the first returned.
- [ ] The user sees progress throughout rather than a single blocking spinner.
- [ ] A failure partway stops the run and keeps every étagère that already landed.
- [ ] The report states which étagères were created and which were not.
- [ ] Re-running after a partial failure picks up only the books still unshelved and creates no duplicates.
- [ ] Books already on an étagère before the run are untouched.
- [ ] Membership goes through the existing `add-items` write, not a second implementation.
- [ ] The carousel shows the new étagères, filled, without a manual refresh.

## Blocked by

- issues/0023-auto-sort-plan-generation.md — produces the plan this slice applies.
- issues/0015-add-book-to-shelf-from-menu.md — builds the membership write this slice calls.
