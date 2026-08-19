# Tokens — node 57:2402 (Frame Highlighted Book)

Raw output of `get_variable_defs`, mapped to the repo's Swift symbols.

| Figma variable | Value | Swift symbol | Note |
|---|---|---|---|
| `foreground/default` | `#f1f1f1` | `.foregroundDefault` | **resolved in DARK mode** — light ink |
| `foreground/tinted` | `#e7ffce` | `.foregroundTinted` | dark-mode value (`color/green/200`) |
| `background/tinted` | `#344e41` | `.backgroundTinted` | dark-mode value (`color/green/900`) |
| `font/family/serif` | Alegreya | `TextStyle.CustomFont` | |
| `font/size/content-400` | 19 | — | |
| `Content/content400Bold` | Alegreya Bold 19 | `.textStyle(.content400Bold)` | the **title** |
| `font/size/footnote-200` | 12 | — | |
| `Footnote/footnote200` | Alegreya Regular 12 | `.textStyle(.footnote200)` | the **authors** |
| `spacing/x-small` | 4 | `.xSmall` | |
| `spacing/small` | 8 | `.small` | |
| `spacing/s-medium` | 12 | `.sMedium` | |
| `spacing/medium` | 16 | `.medium` | row's leading inset |
| `radius/full` | 360 | `.full` | the circular button |
| `sizing/icon/circular-button` | 24 | — | glyph inside the 56pt button |
| `Overlay Bottom-Top` | *(empty)* | — | **unresolved**, see below |

## The dark-mode resolution is the headline

Every colour came back at its **dark** value: ink `#f1f1f1`, tint `#e7ffce`, tinted surface
`#344e41`. That is not incidental — the row floats over a live camera feed, which is dark
and unpredictable regardless of the user's appearance setting.

Consequence for implementation: this row must **not** follow the app's light/dark tokens the
way ordinary screens do. Like the shelf label in PRD 0003 (mode-independent, because it sits
on a fixed-light illustration), this row is mode-independent for the mirror reason — it sits
on a fixed-dark surface. Same precedent, opposite direction.

## `Overlay Bottom-Top`

Named like a gradient (bottom → top) but resolved to an empty string, so its stops are not
captured here. The screenshot shows the camera feed darkening toward the bottom behind the
row, which is what such a gradient would do — it keeps the title legible over an arbitrary
camera image. Needs confirming against the file before implementation; a scrim of some kind
is required either way, since white text on a live feed is otherwise unreadable.
