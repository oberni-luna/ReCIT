//
//  NetworkGroupSummary+Text.swift
//  ReCIT_iOS
//
//  The sentence of a group's sheet (PRD 0019, Q29): « Admin · 12 membres, dont 4 de vos amis :
//  Inès, Léa, Rémi et Camille. », or « 48 membres. » when no friend of mine is in it; an
//  invitation opens on its sender, « Invitation de Camille · 31 membres, dont 2 de vos amis :
//  Camille et Nora. » (issue 0108). The French catalogue puts a narrow no-break space before the
//  colon.
//

import Foundation

extension NetworkGroupSummary {
    func sentence(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        let members: String = lead.text(bundle: bundle, locale: locale)
        let lead: String
        if let invitor {
            lead = String(localized: "groups.invited_by \(invitor)", bundle: bundle, locale: locale) + " · " + members
        } else {
            lead = members
        }
        guard namesFriends else {
            return String(localized: "network.graph.sheet.group_members \(lead)", bundle: bundle, locale: locale)
        }

        let names: String = friendNames.text(bundle: bundle, locale: locale)
        return String(
            localized: "network.graph.sheet.group_friends \(lead) \(friendCount) \(names)",
            bundle: bundle,
            locale: locale
        )
    }
}
