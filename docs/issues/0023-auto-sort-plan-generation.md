Title: Auto-sort — generate and review a shelving plan
Labels: needs-triage
Type: HITL

## Parent

PRD: docs/prd/0006-ai-auto-sort.md

## What to build

The heart of the feature: look at the user's unshelved books, work out a set of étagères that
suits the collection, and show the proposed arrangement. **Nothing is written in this slice** —
the user reviews the plan and cancels. Applying it is issue 0024.

Reachable from the settings screen. The empty-state entry point and the availability
differentiation are issue 0025.

### The classifier never sees a book

The on-device model's context window holds a few thousand tokens — far less than a library.
Chunking the inventory and asking the model to sort each chunk fails twice: each chunk invents
its own shelf names, producing near-duplicate étagères, and no chunk ever sees the collection
as a whole, which is exactly what sizing shelves to book counts requires.

So the work splits into three phases, and the model is only ever consulted on small,
high-judgement inputs:

- **Phase 1 — taxonomy.** The distinct genres present in the unshelved books, *with their
  counts*, go in; a set of étagère names suited to that distribution comes out. Small
  regardless of library size. The counts are what let it fold a three-book genre into a
  broader shelf instead of creating a three-book étagère.
- **Phase 2 — mapping.** Each *distinct genre* is mapped to one of the shelves phase 1 named.
  Bounded by genre count, not book count.
- **Phase 3 — assignment.** Plain local code: each book inherits its genre's shelf. No model
  involved.

Cost therefore scales with distinct genres, not with books — a three-thousand-book library
costs what a three-hundred-book one costs.

### The validation seam

Any shelf name in phase 2's output that phase 1 did not declare is a hallucination and is
**rejected before it can reach the plan**. Because phase 3 is code, the step that will
eventually mutate the user's data cannot invent anything. This guard matters more than
anything else in the slice.

### Scope

Only books on **no** étagère are considered — the feature is purely additive and cannot
disturb hand-curated shelves. Books whose genre enrichment came back empty **stay unshelved**;
falling back to asking the model per book from title and author is precisely the
recall-dependent path this design avoids.

Prompts are written in French so shelf names come out French. Everything runs **on-device** —
no part of the library is sent anywhere.

### The review

A screen listing each proposed étagère, how many books it would hold, and which books. Cancel
discards everything. There is no partial approval and no editing in this version.

### Why HITL

The acceptance criteria below can assert that the plan is *well-formed*. They cannot assert
that it is *good* — that "Littérature de l'imaginaire" beats three separate shelves for
science-fiction, fantasy and fantastique, or that folding poetry into essays reads as sensible
rather than lazy. Someone has to run this against a real library and judge the output, then
tune the prompts. Budget for several rounds; a small model on patchy metadata will need them.

## Acceptance criteria

- [ ] Triggering auto-sort from settings produces a proposed plan without writing anything.
- [ ] Only books on no étagère are considered.
- [ ] The plan lists each proposed étagère with its book count and its books.
- [ ] Proposed shelf names are French.
- [ ] Shelf sizes reflect the collection: a genre with very few books is folded into a broader shelf rather than given its own.
- [ ] Any shelf name in phase 2's output absent from phase 1's taxonomy is rejected before reaching the plan.
- [ ] Books with no genre data are left out of the plan and remain unshelved.
- [ ] A proposed étagère that would end up empty is dropped from the plan.
- [ ] Cancelling discards the plan and writes nothing.
- [ ] The number of model calls does not grow with the number of books, only with distinct genres.
- [ ] Nothing leaves the device.
- [ ] Unit tests — genre histogram: distinct genres and counts; books with no genre excluded but counted as unclassified; a book with several genres handled per the chosen rule; an empty inventory yields an empty histogram.
- [ ] Unit tests — output validator: a mapping using only declared names passes; an invented name is rejected; an omitted genre is handled; duplicate or case-differing names resolve deterministically; an empty or malformed response is rejected rather than partially accepted.
- [ ] Unit tests — assignment: each book lands on the shelf its genre maps to; books with no genre are left out; books whose genre is absent from the mapping are left out rather than defaulted; plan counts match plan contents; empty shelves are dropped.
- [ ] A human has run this against a real library and judged the proposed taxonomy sensible.

## Blocked by

- issues/0022-genre-enrichment.md — supplies the genre data the whole design rests on.
