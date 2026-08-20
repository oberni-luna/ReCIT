# Tokens — C1 (`80:2852`), sortie brute de `get_variable_defs`

| Variable Figma | Valeur (mode Light) | Symbole Swift |
|---|---|---|
| `background/default` | `#ffffff` | `.backgroundDefault` |
| `foreground/default` | `#191919` | `.foregroundDefault` |
| `foreground/secondary` | `#7e837c` | `.foregroundSecondary` |
| `foreground/tinted` | `#558154` | `.foregroundTinted` |
| `foreground/tinted-inverse` | `#f2fae9` | `.foregroundTintedInverse` |
| `background/tinted-inverse` | `#3a5a40` | `.backgroundTintedInverse` — fond du bouton primaire |
| `Title/title200` | Open Sans ExtraBold 32 | `.textStyle(.title200)` |
| `Content/content300` | Alegreya Medium 17 | `.textStyle(.content300)` |
| `Action/action300` | Open Sans SemiBold 17 | `.textStyle(.action300)` |
| `Footnote/footnote200` | Alegreya Regular 12 | `.textStyle(.footnote200)` |
| `Footnote/footnote200Bold` | Alegreya Bold 12 | `.textStyle(.footnote200Bold)` |
| `spacing/large` | 24 | `.large` |
| `spacing/medium` | 16 | `.medium` |
| `radius/full` | 360 | `.full` |
| `opacity/surface/plank` | 92 % | planche de l'illustration |

Aucune couleur littérale dans les frames C : tout est bindé, donc le mode sombre est obtenu en épinglant
le mode sur la frame. Rappel D6 : `OpenSans-SemiBold` et `OpenSans-Regular` **ne se chargent pas** en
production (`DesignSystem.swift:24`) — `Action/action300` retombe sur la police système sur l'appareil.
