//
//  ProfileChange.swift
//  ReCIT_iOS
//
//  One public attribute of the account about to be written, with the value it is written with.
//  `PUT /api/user` takes a single attribute per request, so a profile is saved as a list of these.
//

import Foundation

enum ProfileChange: Equatable, Sendable {
    /// A new picture as JPEG bytes, to be uploaded first; `nil` takes the picture away.
    case picture(Data?)
    case username(String)
    case bio(String)
    /// `nil` takes the position away.
    case position(Coordinates?)

    enum Kind: Equatable, Sendable {
        case picture
        case username
        case bio
        case position
    }

    var kind: Kind {
        switch self {
        case .picture: .picture
        case .username: .username
        case .bio: .bio
        case .position: .position
        }
    }
}
