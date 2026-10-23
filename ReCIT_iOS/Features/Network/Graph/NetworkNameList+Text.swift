//
//  NetworkNameList+Text.swift
//  ReCIT_iOS
//
//  The names of a sheet as a sentence says them: « Inès, Léa, Rémi et Camille », or « Inès, Léa,
//  Rémi et 3 autres » — the list formatted for the language, « et N autres » counted with a plural
//  substitution (PRD 0019, Q29 bis).
//

import Foundation

extension NetworkNameList {
    func text(
        bundle: Bundle = .main,
        locale: Locale = .current
    ) -> String {
        var items: [String] = names
        if others > 0 {
            items.append(String(localized: "network.graph.sheet.others \(others)", bundle: bundle, locale: locale))
        }
        return items.formatted(.list(type: .and).locale(locale))
    }
}
