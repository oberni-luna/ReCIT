//
//  ShelfDetailTab.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  The two pages of an étagère's v2 screen: the books it holds, and what it is — its
//  description, who may see it, when it was made. The same pair as a list's (`ListDetailTab`).
//

import SwiftUI

enum ShelfDetailTab: CaseIterable, Hashable {
    case books
    case presentation
}
