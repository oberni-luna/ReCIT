//
//  ListVisibilityLabel.swift
//  ReCIT_iOS
//
//  Who may see a list, in words, from inventaire.io's visibility keys: none is « Moi seul·e »,
//  `public` wins over the rest, `friends` and `groups` together are « Mes amis et mes groupes ».
//  The reading itself is `ListVisibility`'s, which the list form writes back through.
//

import Foundation

enum ListVisibilityLabel {
    static func label(for visibility: [VisibilityAttributes]) -> LocalizedStringResource {
        ListVisibility(attributes: visibility).label
    }
}
