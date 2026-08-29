# PRDs

A PRD says what a feature is meant to be, before it exists. Once the feature ships, the write-up
in `docs/features/` says what it turned out to be — which is the version worth reading, because it
is the one the code agrees with.

So a PRD is deleted once its feature document exists. This directory is empty of them by design,
not by accident. Nothing is lost: git has every one.

```sh
git log --diff-filter=D --oneline -- docs/prd/ prd/   # find the commit that removed one
git show <commit>^:docs/prd/0008-manual-shelf-sorting.md
```

New PRDs land here. The `to-prd` and `to-issues` skills write to the repository root by default,
which is how two duplicate trees appeared in the first place — move what they produce into
`docs/`.

## One feature has no write-up

`docs/prd/0007-onboarding-scan-then-sort.md` was deleted on 2026-08-29 without a feature document
ever being written for it — issue 0032, which was to write it, was abandoned the same day. The
scan-then-sort onboarding is therefore documented nowhere but the code and git history. That was
deliberate: the flow is muddled and is to be reworked, and documenting it as it stands would only
fix the muddle in writing. When it is reworked, the new PRD starts from a blank page.

The shipped behaviour it covered is partly described in
[0011 — pre-login onboarding](../features/0011-ex-libris-pre-login-onboarding.md) and
[0010 — the grid sorting surface](../features/0010-grid-shelf-sorting.md), neither of which is
about the scan-then-sort flow itself.
