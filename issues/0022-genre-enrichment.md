Title: Fetch and persist genres for works
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0006-ai-auto-sort.md

## What to build

The app stores no genre or subject data for any book. Works carry title, subtitle, original
language, image, publication date, extract and relations; editions add series, language,
author names and page count. A genre Wikidata property exists as an enum case but is never
persisted anywhere.

That makes the auto-sort feature impossible as designed — its whole premise is that the model
groups *known facts* rather than recalling half-known ones — so this slice supplies the facts.

**Schema.** Add a genre property to the work model. Additive with a default, so SwiftData's
lightweight migration covers it: no versioned schema, no migration plan.

**Fetch.** Populate it from the entity endpoint, **batched** — the by-uris call takes many uris
at once, so a few hundred works is a handful of calls, not hundreds. Run it on demand, over
the works behind the user's unshelved books, immediately before the first auto-sort run.
Persist the result so it is paid once.

Folding this into the regular entity sync is the better end state, but that sync path already
contends with optimistic membership writes (see PRD 0004), and an on-demand backfill is needed
regardless for works already synced. On-demand first.

**Surface it as its own step.** The first run will be visibly slower than later ones because
it is doing the backfill. Present that as "Analyse de votre bibliothèque…" with progress,
rather than letting it look like a slow model.

**Expect patchy coverage.** Wikidata's genre data for French mid-list titles is thin. Works
that come back with nothing keep an empty genre list — that is a valid, expected outcome, not
an error, and the auto-sort feature deliberately leaves such books unshelved rather than
guessing.

This slice ships no user-visible sorting. It is verifiable on its own: run the enrichment and
inspect how many works came back with genres and how many did not — which is also the number
that tells you whether the auto-sort feature is going to be any good.

## Acceptance criteria

- [ ] The work model carries a genre list, defaulted, with no versioned migration required.
- [ ] Existing installs migrate without data loss and without a manual reset.
- [ ] Genres are fetched in batched calls, not one call per work.
- [ ] Only works behind the user's unshelved books are enriched.
- [ ] Results are persisted and a second run does not re-fetch what is already known.
- [ ] Works with no genre data end with an empty list and are not treated as an error.
- [ ] The enrichment reports progress and is presented as analysing the library.
- [ ] A network failure mid-enrichment keeps what was already fetched and surfaces the error.
- [ ] The number of works enriched versus left empty is observable, so coverage can be judged.

## Blocked by

None - can start immediately.
