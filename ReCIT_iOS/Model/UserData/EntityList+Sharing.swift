//
//  EntityList+Sharing.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 16/11/2026.
//

import Foundation

extension EntityList {
    /// No one but its creator may open it: a link to it, or to one of its elements, would open
    /// nothing for whoever receives it, so the list offers none.
    var isVisibleToCreatorAlone: Bool {
        visibility.isEmpty
    }
}
