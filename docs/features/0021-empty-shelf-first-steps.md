# The empty shelf says what the first step is

Shipped on 2026-09-22, straight from the Figma section `Inventaire vide · Première étape` (`460:11692`),
frames `C` (`460:11723`) and `D` (`461:11950`). No PRD and no issues: one slice, decided in an autopilot
run whose decision log is summarised below.

## What it does

A user with no étagère used to see one paper note on the empty shelf — « Todo ☐ Scanner mes livres » or
« Todo ☐ Ranger mes livres » — and the whole card was the button. It said what to press, not why, and
with an empty inventory it offered one way in when there are two.

The card now writes the step the user is at above the plank, in two lines, and rests one paper tag per
action on it:

- **Empty inventory** — « Première étape : ajouter vos livres », then two tags: **Scanner** (« le
  code-barres d'un livre ») opens the batch scanner, **Rechercher** (« par titre ou auteur ») raises the
  inventory's own search field.
- **Books, but no étagère** — « Étape suivante : ranger vos livres », then one tag, **Ranger mes livres**
  (« à la main, ou avec un peu d'aide »), which opens the sorting surface.

## Technical surface

- **`ShelfEmptyStateErrand`** keeps deciding the state (`init(ownsBooks:)`), and now carries the heading,
  the sentence and the ordered list of actions instead of a single note string.
- **`ShelfEmptyStateAction`** (`scan` / `search` / `sort`) — one tag: title, detail, SF Symbol,
  accessibility identifier. Both lines are centred on the tag. `ShelvesContent.perform(_:)` is the one switch from an action to its
  destination.
- **`ShelfActionTag`** — the tag itself, a `Button` on paper. **`ShelfEmptyStateCaption`** — the two lines
  above the plank.
- **`ShelfPaperModifier`** (`.shelfPaper(text:)`) — the paper's fill, radius, shadow and lean, lifted out of
  `ShelfLabelView` so the name tag and the action tags share it. `ShelfLabelView` loses its `note` kind,
  its chevron and the parameters only the note used.
- **`ShelvesView`** holds `isSearchPresented` and passes `.searchable(text:isPresented:)` — the only way to
  raise the field from below it — and hands `ShelvesContent` an `onSearch` closure.
- Strings: `shelf.empty.{scan,sort}.{heading,body}` and `shelf.empty.action.{scan,search,sort}.{title,detail}`,
  fr and en. `shelf.empty.note.*` is gone.
- Accessibility identifiers `e2e.shelves.empty.scan`, `.search`, `.sort` on the tags; `e2e.shelves.emptyCard`
  stays on the card. The end-to-end scenario uses none of them.
- Tests: `ShelfEmptyStateErrandTests` — which actions each state offers.

## Notable decisions

- **One tag, one destination, from one value.** The card's rule since PRD 0006 — never open something other
  than what the label says — is kept per tag. The card itself is no longer a button: with two tags side by
  side, a press on the card would have to guess.
- **Nothing is added outside the card.** The sentence and the tags stand in the books' band of
  `ShelfCardMetrics`, so the card keeps a populated shelf's height and the plank stays at the same height when
  the first étagère replaces it. The card is centred on the screen rather than parked where the carousel's first
  card sits — alone, the parked card read as off-centre — so that replacement is a small step sideways. Consequence: at the largest Dynamic Type sizes the band can run out of room.
- **The tags may use the plank's width**, not the books' — two tags inside the 24 pt book margins leave too
  little for either on a small phone. Titles shrink to 80 % before truncating; details wrap to two lines.
- **Rechercher opens the existing field, not a new screen.** The unified search (feature 0014) is where a
  book is looked up; the tag is a shortcut to it.

### Divergences from the Figma frames (the code is the source of truth)

| Point | Figma `C` / `D` | Code |
|---|---|---|
| Lean | 2°, −1,5°, 1,5°, drawn by hand | `ShelfLabelTilt`, ±1° derived from the title |
| Sort glyph | `Icon/book` (no `books.vertical.fill` in the set) | `books.vertical.fill`, as in the navigation bar |
| Chrome | 4-tab bar, one bar action (cloned frames) | the app's 3 tabs and two bar actions, unchanged |

## Not done / not verified

- Not seen in the running app: the simulator was signed out. The two states were rendered with
  `ImageRenderer` in both appearances and match the frames; a pass on a device, with a real account, is
  still owed — including the search field actually rising from the « Rechercher » tag.
- The end-to-end scenario was not played (on request only).
