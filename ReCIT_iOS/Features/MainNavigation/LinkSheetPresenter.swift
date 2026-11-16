//
//  LinkSheetPresenter.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import SwiftUI
import UIKit

/// Whether a modal covers the tabs, and the sheet an Ex-libris link opens over it — the one place
/// the app presents through UIKit (issue 143). SwiftUI presents from the view that declares the
/// sheet, and cannot present over a sheet or a cover another view owns; UIKit presents from the
/// last controller presented above the window's root, whoever presented it.
@MainActor
enum LinkSheetPresenter {
    /// Whether anything is presented over the tabs: a sheet, a cover, the Profil.
    static var isModalUp: Bool {
        modalOnTop != nil
    }

    /// The last controller presented above the key window's root, leaving out one on its way
    /// out; `nil` when nothing is.
    private static var modalOnTop: UIViewController? {
        let root: UIViewController? = UIApplication.shared.connectedScenes
            .lazy
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        guard let root else { return nil }
        let presented: [UIViewController] = .init(
            sequence(first: root) { $0.presentedViewController }
                .dropFirst()
                .prefix { $0.isBeingDismissed == false }
        )
        return presented.last
    }

    /// Presents `sheet` as a page sheet over the modal on top.
    /// - Parameter sheet: What the sheet shows.
    /// - Returns: Whether it was presented: `false` when no modal is up to present it from.
    static func present<Sheet: View>(_ sheet: Sheet) -> Bool {
        guard let modalOnTop else { return false }
        let host: UIHostingController<Sheet> = .init(rootView: sheet)
        modalOnTop.present(host, animated: true)
        return true
    }
}
