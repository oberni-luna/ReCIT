# The empty Lists tab says what a list is for

Shipped on 2026-09-26, straight from the Figma section `Listes vides · Étiquette` (`462:12178`), frame
`A · Une étiquette qui explique` (`462:12186`). No PRD and no issues: one slice, decided in an autopilot run
whose decision log is summarised below.

## What it does

A user with no list used to open the Lists tab onto an empty `List` — a grey screen with no sentence and no way
out but the « + » in the navigation bar (D54 in the Figma library document).

The tab now says the step, « Pas encore de liste · Vos envies de lecture ont leur place ici. », and rests two
paper tags under it, on the same paper as the empty shelf (feature 0021):

- **Liste ou étagère ?** — not a button. « **Une étagère** range les livres que vous avez. » then « **Une liste**
  garde en mémoire ceux que vous n'avez pas : ceux que vous aimeriez acheter, ceux que vous aimeriez lire, ceux
  qu'on vous a conseillés… »
- **Créer une liste** (« à lire, à acheter, à offrir ») — opens `ListFormView`, the same sheet as the « + ».

## Technical surface

- **`ListsEmptyStateView`** (`Features/Lists/`) — the caption and the two tags, centred in the tab; reports the
  create press through a closure.
- **`ListsExplanationTag`** — the explanatory paper, one combined accessibility element.
- **`ListsCreateTag`** — a `Button` on paper, built like `ShelfActionTag`.
- Both tags use `.shelfPaper(text:)` and `ShelfPalette.labelInk`, so the paper, radius, shadow and lean are the
  shelf's, and stay light in dark mode.
- **`EntityListView`** shows the state when the sync placeholder is not up, there is no list, and the search field
  is empty.
- Strings: `lists.empty.{heading,body}`, `lists.empty.explain.{title,shelf,list}` (the bold lead words are
  Markdown in the string), `lists.empty.action.create.{title,detail}`, fr and en.
- Accessibility identifiers `e2e.lists.empty` on the state and `e2e.lists.empty.create` on the tag. The end-to-end
  scenario uses neither.

## Notable decisions

- **Not `ShelfActionTag`.** It is typed by `ShelfEmptyStateAction` (scan / search / sort); a `createList` case would
  have mixed the shelf's errands with the Lists tab. The paper is shared through the modifier instead, which is
  what keeps the two looking alike.
- **No plank.** A list is not a piece of furniture; only the paper carries over from the shelf.
- **A search with no result keeps its empty `List`.** « Pas encore de liste » would be false there. That half of
  D54 stays open.
- **No test.** There is no logic to pin — one `isEmpty` condition. The view was rendered with `ImageRenderer` in
  both appearances and matches the frame.

### Divergences from the Figma frame (the code is the source of truth)

| Point | Figma `A` | Code |
|---|---|---|
| Lean | −1° and 1,5°, drawn by hand | `ShelfLabelTilt`, ±1° derived from each tag's title |
| Gaps | 32 caption → tag, 36 tag → action | `spacing/x-large` (32) for both |
| Chrome | 4-tab bar (cloned frame) | the app's tabs, unchanged |

## Not done / not verified

- Not seen in the running app with a real account: rendered only. A pass on a device is still owed, including the
  sheet rising from « Créer une liste ».
- The end-to-end scenario was not played (on request only).
