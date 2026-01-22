//
//  EntityDestination.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 23/01/2026.
//

import Foundation

enum EntityDestination: Hashable, Identifiable {
    case author(uri: String)
    case work(uri: String)
    
    var id: String {
        switch self {
        case .author(let uri):
            return "author:\(uri)"
        case .work(let uri):
            return "work:\(uri)"
        }
    }
}
