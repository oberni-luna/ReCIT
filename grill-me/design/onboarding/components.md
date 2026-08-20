# Composants — onboarding option C

| Instance Figma | Contrepartie repo | Statut |
|---|---|---|
| `Button / Large` (`Style=Primary`) | `DesignSystem/ButtonStyles/LargeButtonStyle.swift`, `.buttonStyle(.primary())` | existe |
| `Chrome / Status Bar`, `Chrome / Home Indicator` | chrome système, pas de code | n/a |
| `Shelf Empty Card` (`34:211`, illustration de C1) | `Shelves/ShelfEmptyStateView` | existe — reste la planche + le wash, mot papier et légende masqués |
| Illustration de C2 (planche + livres posés) | `ShelfCoverView` / `ShelfSpineView` + `ShelfPlank` | **à composer** : une vue qui pose N livres sur une planche, animables un par un |
| Le mot papier de `C1b` | `Shelves/ShelfLabelView` + `ShelfEmptyStateView` | existe — le libellé du mot devient variable |
| `Cell / List` + `Separator` (frame C3) | `AutoSortPlanView` | existe, non modifié |
| « Plus tard » | aucun — texte tinté `action300`, pas un `ButtonStyle` du DS | **à trancher** : `Button(role:)` nu ou nouveau style |

## Points de friction relevés à la construction

- **C1 porte une planche nue** (décision du 2026-08-20) : pas de livres inventés, donc pas d'étagère factice à
  fabriquer. C2 porte les vraies couvertures, lues par `@Query`, et les pose une par une.
- `C1b` réutilise la carte d'étagère vide, dont le mot papier dit aujourd'hui « Todo / Ranger mes livres »
  (`ShelfEmptyStateView`). Le mot devient donc conditionnel : « Scanner » tant que l'inventaire est vide,
  « Ranger » dès qu'il y a des livres non rangés.
- Le glyphe `xmark` n'existe pas dans `Icon` (`21:60`) — sans objet pour C, qui n'a pas de croix de fermeture.
