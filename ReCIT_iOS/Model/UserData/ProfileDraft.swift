//
//  ProfileDraft.swift
//  ReCIT_iOS
//
//  « Modifier le profil » while it is being typed: what the form shows, set against what the
//  server last agreed to. Pure — no network, no store — so that what gets sent is decided here,
//  and tested here.
//
//  Only what changed is sent, because `PUT /api/user` answers `400 already up-to-date` to a value
//  it already has, and because every request costs a second (see `RequestPacer`). The order is the
//  one the form reads in: picture, name, bio, position.
//

import Foundation

struct ProfileDraft: Equatable {
    /// `BoundedString(0, 1000)` in `server/models/validations/user.ts`.
    static let bioLimit: Int = 1_000

    enum Picture: Equatable {
        case unchanged
        case replaced(Data)
        case removed
    }

    var picture: Picture = .unchanged
    var username: String
    var bio: String
    var position: Coordinates?

    private var savedUsername: String
    private var savedBio: String
    private var savedPosition: Coordinates?
    /// Whether the account has a picture on the server — the only case where removing one is a
    /// change rather than nothing.
    private(set) var hasSavedPicture: Bool

    init(
        username: String,
        bio: String,
        position: Coordinates?,
        hasPicture: Bool
    ) {
        self.username = username
        self.bio = bio
        self.position = position
        self.savedUsername = username
        self.savedBio = bio
        self.savedPosition = position
        self.hasSavedPicture = hasPicture
    }

    init(user: User) {
        self.init(
            username: user.username,
            bio: user.bio ?? "",
            position: user.position,
            hasPicture: user.avatarURLValue != nil
        )
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBio: String {
        bio.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// What « Enregistrer » sends, in the order it sends it.
    var changes: [ProfileChange] {
        var changes: [ProfileChange] = []

        switch picture {
        case .unchanged:
            break
        case .replaced(let data):
            changes.append(.picture(data))
        case .removed:
            if hasSavedPicture {
                changes.append(.picture(nil))
            }
        }

        if trimmedUsername != savedUsername {
            changes.append(.username(trimmedUsername))
        }

        if trimmedBio != savedBio {
            changes.append(.bio(trimmedBio))
        }

        if position != savedPosition {
            changes.append(.position(position))
        }

        return changes
    }

    /// Whether the name typed has to be asked about. Not when it is the account's own, nor when
    /// only its case moved: the availability check would answer « taken » about the account
    /// itself, and the server lets an account keep its own name in another case.
    var usernameNeedsCheck: Bool {
        trimmedUsername.lowercased() != savedUsername.lowercased()
    }

    var bioLength: Int {
        bio.count
    }

    var isBioTooLong: Bool {
        bioLength > Self.bioLimit
    }

    var isUsernameEmpty: Bool {
        trimmedUsername.isEmpty
    }

    /// Something to send, and nothing the server is bound to refuse.
    var isSaveable: Bool {
        changes.isEmpty == false && isBioTooLong == false && isUsernameEmpty == false
    }

    /// The picture shown and the one on the server are now the same thing — for the menu, which
    /// only offers to remove a picture there is.
    var showsPicture: Bool {
        switch picture {
        case .unchanged: hasSavedPicture
        case .replaced: true
        case .removed: false
        }
    }

    /// Places the position, rounded to two decimals — about a kilometre. A position is public on
    /// inventaire.io, and it is meant to say which neighbourhood, not which door.
    mutating func place(at coordinates: Coordinates?) {
        position = coordinates.map(Self.rounded)
    }

    static func rounded(_ coordinates: Coordinates) -> Coordinates {
        .init(
            latitude: (coordinates.latitude * 100).rounded() / 100,
            longitude: (coordinates.longitude * 100).rounded() / 100
        )
    }

    /// Takes in what the server has accepted, so that a second « Enregistrer » after a partial
    /// failure sends only what is left.
    mutating func markLanded(_ landed: [ProfileChange]) {
        for change in landed {
            switch change {
            case .picture(let data):
                picture = .unchanged
                hasSavedPicture = data != nil
            case .username(let value):
                savedUsername = value
            case .bio(let value):
                savedBio = value
            case .position(let value):
                savedPosition = value
            }
        }
    }
}
