//
//  EntityImageHash.swift
//  ReCIT_iOS
//
//  The name inventaire.io files an entity's picture under. An upload answers a path,
//  `/img/entities/<hash>`, and the claim that hangs the picture on an edition, `invp:P2`, takes
//  the hash alone — 40 hexadecimal characters, the SHA-1 of the file.
//

import Foundation

enum EntityImageHash {

    /// The hash at the end of an upload's path, or `nil` when what came back is not one.
    static func from(_ path: String?) -> String? {
        guard let last = path?.split(separator: "/").last else { return nil }

        let hash: String = .init(last)
        let isHash: Bool = hash.count == 40 && hash.allSatisfy { $0.isHexDigit && ($0.isNumber || $0.isLowercase) }
        return isHash ? hash : nil
    }

    /// The path a hash is served from, the shape `absoluteImageUrl` resolves.
    static func path(of hash: String) -> String {
        "/img/entities/\(hash)"
    }
}
