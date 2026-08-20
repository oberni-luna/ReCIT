Title: Onboarding — the bilan at the end of a scanning session
Labels: needs-triage
Type: AFK

## Parent

PRD: docs/prd/0007-onboarding-scan-then-sort.md

## What to build

A scanning session that added books does not just close: it reports. `24 livres ajoutés`, one
sentence saying the books are on no étagère and that arranging them happens on the phone,
`Ranger mes livres` leading into the auto-sort review screen that already exists, and
`Plus tard`.

The bilan belongs to the **scanner**, not to the accueil, so a session opened from the search
tab reports exactly like a session opened from the accueil. That is what makes this more than a
first-launch flourish: the moment worth interrupting is the end of a scanning session, and that
moment recurs.

### When it shows

The gate from the previous slice gains its second decision: show the bilan when the session
added at least one book and the user has no étagère.

"Has already arranged their books" is **not** persisted — it is derived from owning at least one
étagère, read from the store like everything else. A user who created an étagère by hand
therefore also stops seeing the bilan; that is accepted, since they have shown they know what
an étagère is. A session that added nothing shows nothing.

### The count

Carried out of the scanner, because no query can derive it: three books added among three
hundred is invisible in any snapshot of the store.

It is owned by the scanner's **pure state machine**, incremented on the add-finished event it
already processes, so it is covered by that module's existing suite from the outset. The view
model holds no counter of its own.

### The mechanics

The bilan **replaces the camera inside the existing modal** rather than stacking a second cover
on it: the camera is torn down, the bilan takes the screen, and dismissing the bilan is what
returns the user where they came from.

Two consequences are to be carried out rather than worked around. Closing becomes two-stage —
the close control ends the session, it does not leave — and the scanner view stops being "the
scanner" and becomes "the scanning session". Its documentation currently describes a modal that
returns control on close; rewrite it rather than leave it lying.

### The screen

Same skeleton as the accueil, same tokens, plank still bare in this slice — the real covers
arrive in the next one. The title pluralises **in the string catalogue**, using its plural
rules: `1 livre ajouté` / `24 livres ajoutés`. The auto-sort screens build plurals with inline
ternaries in Swift; that is not the pattern to copy.

## Acceptance criteria

- [ ] The scanner's pure state machine exposes a count of books added during the session
- [ ] The count increments only on a completed add — a failed add and a barcode rejected by the
      repeat gate leave it untouched
- [ ] The gate decides the bilan from the session count and the user's étagère count, in the
      same pure type as the accueil's decision
- [ ] A session that added nothing closes straight to where it came from, with no bilan
- [ ] A session that added books shows the bilan when the user has no étagère, and does not
      when they have one
- [ ] A session opened from the search tab behaves identically to one opened from the accueil
- [ ] The bilan replaces the camera inside the same modal; no second full-screen cover is
      stacked, and the camera is torn down when it appears
- [ ] Dismissing the bilan returns the user to the screen the session was opened from
- [ ] `Ranger mes livres` pushes the existing auto-sort review screen
- [ ] The title reads `1 livre ajouté` for one book, from a catalogue plural rule, with no
      ternary in Swift
- [ ] The scanner view's documentation no longer claims it returns control on close
- [ ] Test suite extends the state machine's existing suite: count starts at zero, increments
      on a completed add only, survives the row clearing and the next book being offered
- [ ] Test suite on the gate: zero-add session, books added with no étagère, books added with
      an étagère, books added after an étagère was created by hand

## Blocked by

- issues/0026-onboarding-welcome-screen.md
