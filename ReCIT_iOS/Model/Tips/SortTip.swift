//
//  SortTip.swift
//  ReCIT_iOS
//
//  The three things « Ranger mes livres » has to teach, named once.
//
//  A raw-valued enum rather than three unrelated names, because what the app remembers is
//  *which gesture this account has learned* — and that has to be written to disk, read back,
//  and reasoned about by a pure type that knows nothing of TipKit. The TipKit `Tip` structs
//  are the display of these cases, not their identity.
//
//  The raw values are persisted by `TipsStore`, so they are stable strings rather than the
//  case names' spelling by accident: renaming a case without renaming its raw value hands
//  every account its astuces back.
//
//  Declaration order is the order the astuces are offered in, and the order the surface's
//  `TipGroup(.ordered)` repeats — SORT-1, then SORT-2, then SORT-3. All three cases exist
//  here from the first slice on, because a value type that has to grow a case later is a
//  value type every switch has to be revisited for.
//
//  See PRD 0013.
//

/// One of the sorting surface's astuces.
enum SortTip: String, CaseIterable, Hashable, Sendable {
    /// SORT-1 — take a book from « Livres à ranger » and drop it on an étagère, and the
    /// gesture that puts it back. Learned by the first accepted move out of the carousel.
    case dragToFile = "sort.dragToFile"
    /// SORT-2 — nothing is written until « Appliquer ». Due as soon as there is something
    /// to save, learned by the first apply launched.
    case nothingSavedYet = "sort.nothingSavedYet"
    /// SORT-3 — the iPhone can fill the étagères on its own, and its proposal is corrected
    /// before it is applied. Due only where the control is live and once SORT-1 has served,
    /// learned by the first proposal asked for.
    case letItPropose = "sort.letItPropose"
}
