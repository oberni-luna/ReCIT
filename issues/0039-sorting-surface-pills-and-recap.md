Title: What is pending, said on each étagère and once in words
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0008-manual-shelf-sorting.md

## What to build

The screen starts telling the user what applying would do, without applying anything.

`SortWritePlan` reduces the snapshot and the stack **once** and exposes three readings of that one
reduction: the operations that would be sent, the status of each étagère, and the counts the
recap is built from. One reduction is the point — the pill, the recap and the write cannot
contradict each other, which two modules deriving the same thing eventually would.

Coalescing rules, all visible in this slice through the pills:

- a book moved three times is one removal and one addition, against the endpoints;
- a book taken off an étagère and put back is **nothing at all**, and the pill goes away;
- an étagère emptied by dragging is *modified*, never deleted.

| Status | Pill |
|---|---|
| Exists on the server, untouched | none |
| Does not exist yet | `Nouvelle`, tinted |
| Exists, contents changed | `Modifiée`, secondary |

Absence carries the normal state, so the pending work reads without counting anything. Above the
buttons, one sentence says the same thing: how many étagères to create, how many modified, how
many books filed, how many will still be on no étagère.

The apply button stays inert — it is wired in the next slice.

## Acceptance criteria

- [ ] An étagère that gains or loses a book shows `Modifiée`; an untouched one shows nothing
- [ ] Dragging a book out of an étagère and back clears the pill and produces no operation
- [ ] A book moved across three sections produces exactly one removal and one addition
- [ ] An étagère emptied by dragging keeps its place, marked `Modifiée`, and is not deleted
- [ ] The recap sentence agrees with the pills and with the operations, on the same fixtures
- [ ] The recap states how many books will remain on no étagère
- [ ] `SortWritePlan` is asserted without a store: operations, status and summary
- [ ] Recap copy uses plural rules from the catalogue, not ternaries inside interpolations

## Blocked by

- issues/0038-sorting-surface-drag-and-drop.md
