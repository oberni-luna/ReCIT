# Scanner et « Ranger mes livres »

Books come in by the pile: the scanner stays open and accumulates, then « Ranger mes livres » files them into étagères by hand, with an optional on-device AI proposal. Nothing is written until « Enregistrer ».

## Code

- `Features/Scanner/` — `BatchScanCameraView`
- `Features/Sorting/` — `SortFlowView`
- `Features/AutoSort/`
- `Model/Sorting/SortWritePlan.swift`

## Decisions

- [ADR 0007](adr/0007-modal-sorting-flow.md)

## Features

- [0007 Batch scanning books into the inventory](features/0007-batch-scanner.md) — the camera stays open and books accumulate; supersedes the single-shot scanner
- [0008 Automatic shelving with on-device AI](features/0008-ai-auto-sort.md) — proposes étagères sized to the collection; its review-and-apply half is superseded by 0009
- [0009 Sorting books into étagères, by hand and with help](features/0009-manual-shelf-sorting.md) — drag books between étagères and « À ranger », nothing written until you apply; its surface is superseded by 0010
- [0010 Ranger mes livres, in a grid](features/0010-grid-shelf-sorting.md) — étagères as cards over an anchored panel of books to file, drag both ways, one modal flow
- [0015 The tips of « Ranger mes livres »](features/0015-sorting-tips.md) — three TipKit cards, each killed by the gesture it teaches; device pass still owed
- [0032 « Enregistrer », and a question before leaving « Ranger mes livres » unsaved](features/0032-sorting-save-and-leave.md) — the primary button renamed; the cross asks « Quitter sans enregistrer ? » over unsaved changes until answered « Quitter » once
