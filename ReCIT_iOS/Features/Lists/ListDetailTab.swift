//
//  ListDetailTab.swift
//  ReCIT_iOS
//
//  The two pages of a list's screen: what it holds, in the cover flow, and what it is — its
//  description, its type, who may see it, when it was made. See the `Liste détails · Description
//  de la liste` section of the Figma file (`909:1465`, B1 and B2).
//

import SwiftUI

enum ListDetailTab: CaseIterable, Hashable {
    case elements
    case presentation
}
