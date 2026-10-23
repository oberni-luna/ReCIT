//
//  NetworkReaderSummary+Text.swift
//  ReCIT_iOS
//
//  The lines of a reader's sheet (PRD 0019, Q27): « Membre depuis mars 2021 », in the words and
//  the format of the reader rows of the lists, and « 1 groupe en commun : Club de Belleville. »;
//  for a reader who asked to be my friend, what their profile says of the request (issue 0108).
//

import Foundation

extension NetworkReaderSummary {
    /// « Membre depuis mars 2021 », or `nil` when the server has not said.
    func memberSinceText(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String? {
        guard let memberSince else { return nil }

        let date: String = memberSince.formatted(.dateTime.month(.wide).year().locale(locale))
        return String(localized: "user.member_since \(date)", bundle: bundle, locale: locale)
    }

    /// « 2 groupes en commun : Club de Belleville et BD & romans graphiques. », or `nil` when we
    /// share none.
    func commonGroupsText(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String? {
        guard hasCommonGroups else { return nil }

        let names: String = commonGroupNames.text(bundle: bundle, locale: locale)
        return String(
            localized: "network.graph.sheet.common_groups \(commonGroupCount) \(names)",
            bundle: bundle,
            locale: locale
        )
    }

    /// « Camille vous a demandé de rejoindre son réseau. Refuser ne le prévient pas… », the
    /// sentence of the requester's profile, or `nil` for a friend.
    func explanationText(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String? {
        guard isRequest else { return nil }

        return String(
            localized: "network.invitation.explanation \(reader.username)",
            bundle: bundle,
            locale: locale
        )
    }
}
