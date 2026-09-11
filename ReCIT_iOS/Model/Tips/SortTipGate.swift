//
//  SortTipGate.swift
//  ReCIT_iOS
//
//  Which astuce « Ranger mes livres » owes the user, if any. Pure: no TipKit, no SwiftUI,
//  no SwiftData, no `UserDefaults`, on the pattern of `OnboardingGate` and the
//  `Model/AutoSort/` types. The conditions *are* the feature, so they live in one readable
//  place and the view asks the question instead of deciding it.
//
//  **One answer rather than three predicates.** The surface may never show two astuces at
//  once (PRD 0013): two cards over three étagère cards leave nothing to sort. The
//  `TipGroup(.ordered)` on the screen enforces that on TipKit's side; returning a single
//  case enforces it here, where it can be read — and makes "which one comes first" a fact
//  of `SortTip`'s declaration order rather than a race between three booleans.
//
//  **Nothing is owed while the screen is working.** `syncing` points at a carousel that is
//  not there yet, and `isApplying` / `isProposing` would lay a card over cards that are
//  breathing under a run the user is watching. Both are one guard rather than a clause
//  repeated per astuce, so a future fourth astuce cannot forget them.
//
//  See PRD 0013 and issues 0077, 0079 and 0080.
//

/// The rule that decides which astuce the sorting surface owes the user.
enum SortTipGate {

    /// The astuce due right now, or `nil` for none.
    ///
    /// Every input is a value the caller already holds — `SortSessionModel` exposes the
    /// session's, `AutoSortEntryPoint` carries Apple Intelligence's, `TipsStore` carries
    /// what the account has learned. Nothing is fetched here, which is what makes the whole
    /// ruleset readable in one screen and assertable without an app.
    ///
    /// - Parameters:
    ///   - isReady: whether the surface's opening sync has finished. An astuce raised over
    ///     `syncing` would point at a carousel whose books have not arrived.
    ///   - unshelvedBookCount: how many books sit in « Livres à ranger ». SORT-1 aims at the
    ///     first of them, so with none there is nothing to aim at.
    ///   - hasPendingChanges: whether the stack holds work that « Appliquer » would write.
    ///     SORT-2's own clause: the astuce speaks about a button that has something to do.
    ///   - proposalEntryPoint: the shape the proposal control takes on this device, derived
    ///     from `AutoSortModel.availability` exactly as the button itself derives it — so
    ///     the astuce and the control it describes cannot disagree. SORT-3's own clause.
    ///   - isApplying: whether a run is writing right now.
    ///   - isProposing: whether the on-device model is working out a rangement right now.
    ///   - learnedTips: what this account has already been taught, by doing the gesture.
    static func dueTip(
        isReady: Bool,
        unshelvedBookCount: Int,
        hasPendingChanges: Bool,
        proposalEntryPoint: AutoSortEntryPoint,
        isApplying: Bool,
        isProposing: Bool,
        learnedTips: Set<SortTip>
    ) -> SortTip? {
        guard isReady else { return nil }
        guard isApplying == false, isProposing == false else { return nil }

        for tip in SortTip.allCases where learnedTips.contains(tip) == false {
            switch tip {
            case .dragToFile:
                // The gesture the whole screen is made of, offered as soon as there is a
                // book to make it with — and only then, since the card points at the first
                // one. A user who has filed everything is not offered a drag they cannot do.
                if unshelvedBookCount > 0 { return tip }

            case .nothingSavedYet:
                // The screen's most important decision — nothing leaves before « Appliquer »
                // — said once it concerns the reader, and not a moment before: with an empty
                // stack there is nothing at stake and the card would point at an inert
                // button. It is the same clause that silences it again when everything is
                // discarded. Work worth saving also means SORT-1 has served, so the two
                // cannot compete for the same visit.
                if hasPendingChanges { return tip }

            case .letItPropose:
                // SORT-3 only exists where the control it describes can be pressed, and only
                // once the drag has been learned — the proposal is help with a gesture, not a
                // way round it, and offering it first would teach the user never to file
                // anything themselves.
                //
                // `isEnabled` rather than `isVisible`: a greyed button explains itself with
                // its own alert, and a card promising that the iPhone reads the titles would
                // be promising something the device cannot do right now. Switching Apple
                // Intelligence on, or finishing the download, therefore brings the astuce and
                // the live button together — the caller derives this entry point from the
                // observable `AutoSortModel.availability` in its body, so neither waits for a
                // relaunch.
                if proposalEntryPoint.isEnabled, learnedTips.contains(.dragToFile) { return tip }
            }
        }

        return nil
    }
}
