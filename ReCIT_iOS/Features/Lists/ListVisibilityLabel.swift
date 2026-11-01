//
//  ListVisibilityLabel.swift
//  ReCIT_iOS
//
//  Who may see a list, in words, from inventaire.io's visibility keys: none is « Moi seul·e »,
//  `public` wins over the rest, `friends` and `groups` together are « Mes amis et mes groupes ».
//

import Foundation

enum ListVisibilityLabel {
    static func label(for visibility: [VisibilityAttributes]) -> LocalizedStringResource {
        if visibility.contains(.public) {
            return "list.visibility.public"
        }

        switch (visibility.contains(.friends), visibility.contains(.groups)) {
        case (true, true): return "list.visibility.friends_and_groups"
        case (true, false): return "list.visibility.friends"
        case (false, true): return "list.visibility.groups"
        case (false, false): return "list.visibility.private"
        }
    }
}
