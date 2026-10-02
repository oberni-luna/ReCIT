# « Enregistrer », and a question before leaving « Ranger mes livres » unsaved

Shipped on 2026-10-02. No PRD and no issues: one slice, decided in an autopilot run whose decision log is
summarised below.

## What it does

- The primary button of the sorting surface's action bar says **« Enregistrer »** (“Save”) instead of
  « Appliquer le rangement ». The sentences that named it or its verb follow: the idle footer (« Rien à enregistrer
  pour le moment. »), the line after a stopped run (« Appuyez à nouveau sur « Enregistrer » pour terminer… »), and
  the astuces SORT-2 and SORT-3.
- The cross at the top left now asks **« Quitter sans enregistrer ? »** when the stack holds changes — « Vos
  changements ne sont pas encore enregistrés. Vous les retrouverez ici en revenant. » — with **« Quitter »** and
  **« Annuler »**.
- Once the user has answered « Quitter », the question is **never asked again on this device**. « Annuler » leaves
  it in place for next time.
- With nothing unsaved, or while a run is writing, the cross closes at once, as before.

## Technical surface

- **`SortLeaveConfirmation`** (`Model/Sorting/`) — `isNeeded(hasPendingChanges:isApplying:isAcknowledged:)`, the
  whole rule, pure. Covered by `SortLeaveConfirmationTests`.
- **`ManualSortView`** — the close button calls `close()`, which asks the rule; a `confirmationDialog` with the
  title visible and a message; `@AppStorage("sort.leaveWithoutSaving.acknowledged")` set by « Quitter ».
- Strings `manual_sort.leave.confirm.{title,message,action}`, fr and en; « Annuler » is the existing
  `action.cancel`. `manual_sort.apply` and the five sentences above reworded in both languages (“Save”).
- The end-to-end scenario's step names say « Enregistrer ». Its close step comes after the run has landed, so it
  never meets the dialog; no identifier changed.

## Notable decisions

- **The question says the draft is kept.** Closing has always kept the session (feature 0010): the stack is
  app-scoped and is found again on return. Asking « lose your changes? » would have been false, so the message says
  they will be there, and « Quitter » is not styled destructive — unlike « Abandonner », which really throws the
  stack away.
- **Asked only when there is something unsaved.** With an empty stack there is nothing the question could be about.
- **Acknowledged per device, in `AppStorage`**, like the Profil's inventaire.io tag (feature 0026): it is about how
  the app behaves, not about an account, so a sign-out does not bring it back.
- **Not while a run is writing**: the writes belong to the session and carry on without the screen.
- **Code comments still say « Appliquer ».** About thirty comments across `Features/Sorting/`, `Model/Sorting/` and
  `Model/Tips/` name the button by its old label, some of them as history (« a trap took the app down on « Appliquer
  le rangement » »). The code's own names (`apply`, `e2e.sort.apply`) never carried the label; the comments were
  left alone rather than rewritten for a wording change.

## Not done, not verified

- Built, unit suite green, end-to-end target builds. **Never seen on a simulator or a device**: the dialog's
  placement (a confirmation dialog anchored to a toolbar button shows as a popover) and the label's width in the
  bar are unchecked by eye — « Enregistrer » is shorter, so the astuce pointers laid out on the button's centre
  move with it.
- The end-to-end scenario was not run.
- The Figma frames still say « Appliquer le rangement »; noted in `docs/design-system/figma-library.md`.
