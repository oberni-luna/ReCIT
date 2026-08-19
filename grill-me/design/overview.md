# Design capture — batch scan flow

Source: Figma `Nouveau récits`, file key `S7IvC6GvlcUFe5IgbtvQq6`
Node: `57:2401` — frame **"Batch Add"**, 393 × 852 (iPhone at 1×)
Link: https://www.figma.com/design/S7IvC6GvlcUFe5IgbtvQq6/Nouveau-r%C3%A9cits?node-id=57-2401

Only one node was in scope. Features 1 (shelf membership menus) and 3 (AI auto-sort) have
no design — they are platform-standard menu/swipe affordances and a background flow.

## Node tree

| id | name | frame | note |
|---|---|---|---|
| `57:2401` | Batch Add | 0,0 393×852 | the screen |
| `57:2399` | screenshot | 0,0 393×852 | placeholder for the live camera feed |
| `57:2402` | Frame Highlighted Book | 0,678 393×174 | the result overlay, pinned bottom |
| `57:2405` | book/Le Comte de Monte-Cristo | 0,0 393×91 | one scanned-book row |
| `57:2407` | Livre (instance) | 16,8 48×75 | cover thumbnail |
| `57:2409` | Title | 76,22.5 233×26 | `content400Bold` |
| `57:2411` | Authors | 76,52.5 233×16 | `footnote200` |
| `57:2410` | Subtitle | — | **hidden** |
| `57:2412` | meta (Tag + Owner) | — | **hidden** |
| `58:2455` | Button / Circular Icon | 321,17.5 56×56 | the "Ajouter" action |
| `57:2419` | tab bar (instance) | 0,769 393×83 | present in the mockup |
| `57:2420` | home indicator | 0,818 393×34 | |

## Geometry that matters

- The result row occupies **678 → 769** (91pt tall), sitting **directly above the tab bar**,
  which runs 769 → 852.
- `Frame Highlighted Book` is declared 174 tall (678 → 852), i.e. it spans the row *and* the
  tab bar area — the row is its only visible content.
- The circular button's 56pt frame is centred on the row's 91pt height (17.5 top, 17.5 bottom).
- Cover thumbnail is 48 × 75 → aspect ≈ 0.64, close to the app's nominal book aspect.

## Open design questions this capture does not answer

- Whether the tab bar is genuinely visible during the flow, or is mockup furniture. A modal
  scanner would normally cover it.
- What the row does when a **second** book is scanned before the first is added — replace,
  stack, or queue.
- Whether the row has a dismiss/skip affordance. None is drawn.
- The `Overlay Bottom-Top` variable resolved to an empty string, so the gradient behind the
  row is not pinned by this capture — see `tokens.md`.
