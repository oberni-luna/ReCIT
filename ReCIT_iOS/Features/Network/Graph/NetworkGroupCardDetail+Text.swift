//
//  NetworkGroupCardDetail+Text.swift
//  ReCIT_iOS
//
//  The words of a group card's second line, from the keys the Groupes list already says them
//  with — `groups.role.admin`, `groups.members_count`, `groups.invited_by` — joined by a middle
//  dot. A plain string, read once, rather than a `Text` built by interpolation, which would add a
//  « %@ · %@ » key of its own to the catalogue.
//

import Foundation

extension NetworkGroupCardDetail {
    var text: String {
        text()
    }

    /// The line in the language of `bundle` — the app's own unless a test asks for another.
    func text(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        switch self {
        case .admin(let memberCount):
            String(localized: "groups.role.admin", bundle: bundle, locale: locale)
                + " · "
                + String(localized: "groups.members_count \(memberCount)", bundle: bundle, locale: locale)
        case .members(let count):
            String(localized: "groups.members_count \(count)", bundle: bundle, locale: locale)
        case .invitation(let invitor):
            String(localized: "groups.invited_by \(invitor)", bundle: bundle, locale: locale)
        }
    }
}
