# PRDs

A PRD says what a feature is meant to be, before it exists. Once the feature ships, the write-up
in `docs/features/` says what it turned out to be — which is the version worth reading, because it
is the one the code agrees with.

So a PRD is deleted once its feature document exists. Eight were deleted on 2026-08-29 for that
reason. Nothing is lost: git has them.

```sh
git log --diff-filter=D --oneline -- docs/prd/ prd/   # find the commit that removed one
git show <commit>^:docs/prd/0008-manual-shelf-sorting.md
```

## What is still here, and why

- `0001-bookshelf-carousel-and-create.md` — the shelf carousel and shelf creation. Parts of it are
  superseded by features 0003, 0004 and 0005, but no feature document was ever written for it.
- `0007-onboarding-scan-then-sort.md` — the scan-then-sort onboarding. Its feature document was
  issue 0032, abandoned on 2026-08-29. This is the only written record of that feature.

Both stay until someone writes the missing feature documents. Delete them then, not before.
