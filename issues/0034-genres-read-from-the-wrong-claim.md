Title: Auto-sort finds no genres because it reads a claim inventaire's own works do not carry
Labels: needs-triage, bug
Type: AFK

## Parent

Feature: docs/features/0008-ai-auto-sort.md

## What to build

Reported from a device on 2026-08-20: an 8-book inventory, 6 of them unshelved, and the
arrangement screen answers "Aucun genre n'a pu être identifié dans vos livres non rangés" —
which reads as a broken feature rather than as thin data.

It is not a code defect. It is the wrong property.

## What the data actually says

`GenreEnrichmentModel` reads exactly one claim, `wdt:P136` (genre). Checked against the live
API on 2026-08-20:

| Work | uri | `wdt:P136` | `wdt:P921` |
|---|---|---|---|
| Les Misérables | `wd:Q180736` | yes | no |
| Germinal | `wd:Q137869` | yes | yes |
| Le ministère des rêves | `wd:Q102036201` | yes | yes |
| Dune | `wd:Q190192` | yes | yes |
| La constellation du chien | `inv:253f8e9e…` | **no** | **no** |
| La fin de la mégamachine | `inv:9cf5fbb9…` | **no** | yes (`capitalisme`, `figure d'autorité`) |

The pattern: a work mapped to Wikidata (`wd:`) almost always carries a genre. A work that only
exists in inventaire (`inv:`) carries `wdt:P31` and little else — sometimes `wdt:P921` (main
subject), never `wdt:P136`. Recent and French-language titles are exactly the ones that tend to
be `inv:` only, so the property the enrichment reads is the property this library does not have.

The feature doc already anticipated thin coverage. What it did not anticipate is that the thin
half is *structural* — tied to which entity namespace a work lives in — rather than random.

## First, confirm the scope is not also empty

There are two ways to arrive at "no genres", and they need different fixes. The enrichment
already prints its own answer on every run:

```
## Genre enrichment finished: N work(s) with genres, N without, N pending, out of N
```

If the last number is **0**, the works were never reached at all — `unshelvedWorks` walks
`item.edition?.works`, so an edition whose work link was never synced contributes nothing, and
the claim discussion below is beside the point. Read that line before writing any code.

## What to change

- **Read `wdt:P921` as well as `wdt:P136`**, genre first and subject as a fallback, through the
  same second pass that resolves uris to French labels. It is the data that is actually there.
- **Keep them distinguishable.** A subject is not a genre: `capitalisme` and `figure d'autorité`
  are what one book above answers, and a taxonomy built from those will name shelves that read
  oddly. Whether the fallback feeds the model on equal footing, or only when a work has no
  genre at all, is the decision this issue has to make and record — not gloss over.
- **Make the empty message diagnosable.** "Aucun genre n'a pu être identifié" should say how
  many works were consulted and how many came back empty, so the next report distinguishes an
  unsynced scope from genuinely bare data. The coverage is already computed; only the wording
  is missing.
- The enrichment timestamp still records that a work was *asked about*, so re-running stays
  cheap. A work asked under the old single-claim rule has a timestamp and would be skipped —
  decide whether the fix invalidates those, and say so in the commit.

## Out of scope

- Asking the on-device model to guess a genre from a title. That is a different feature and it
  contradicts the decision in features/0008 that the model never sees a book.
- Falling back to the author's own genre claims. Plausible, cheaper than it looks, and worth its
  own issue if `wdt:P921` turns out not to be enough.

## Acceptance criteria

- [ ] The coverage log's meaning is confirmed on the reporter's own library before any change,
      and the finding recorded in the fix's commit message
- [ ] `wdt:P921` is read alongside `wdt:P136`, resolved to labels through the existing batched
      second pass
- [ ] The choice between "subjects on equal footing" and "subjects only where no genre exists"
      is implemented and its reasoning written where the reader of the code will find it
- [ ] The empty-plan message names the counts it is talking about
- [ ] Works already stamped by the old rule are re-asked, or it is documented why not
- [ ] A test covers the claim extraction: a work with only `wdt:P921` yields genres, one with
      neither yields none. Prior art: `GenreHistogramTests`, `ShelfMappingValidatorTests`
- [ ] `docs/features/0008-ai-auto-sort.md` records that `inv:` works carry no `wdt:P136`, since
      that is the fact the original design was missing

## Blocked by

None - can start immediately
