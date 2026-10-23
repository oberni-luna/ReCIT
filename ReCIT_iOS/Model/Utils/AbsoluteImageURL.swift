//
//  AbsoluteImageURL.swift
//  ReCIT_iOS
//
//  The address an image path from inventaire.io is fetched at. Three shapes come back from the
//  server: an absolute url, kept as it is; an `/img/...` path on inventaire.io itself, put after
//  the base url; and a bare Wikimedia Commons file name, asked of `Special:FilePath` at 512 wide.
//
//  The body of `APIService.absoluteImageUrl`, lifted out so that a model built from a DTO with
//  nothing but a base url in hand — a `User`, through `User.upsert` — resolves its picture by
//  the same rule as a group's, an author's or a cover. A reader's avatar used to be the base url
//  and the path glued together, so an absolute `picture` came out as two urls end to end.
//

import Foundation

nonisolated enum AbsoluteImageURL {

    /// The width Wikimedia is asked for: a thumbnail's worth, never the original.
    static let wikimediaWidth: Int = 512

    /// The url to fetch `path` at, or `nil` when there is no path.
    static func resolve(
        _ path: String?,
        baseUrl: String
    ) -> String? {
        guard let path else { return nil }
        if path.hasPrefix("http") {
            return path
        } else if path.hasPrefix("/img") {
            return "\(baseUrl)\(path)"
        } else {
            return "https://commons.wikimedia.org/wiki/Special:FilePath/\(path)?width=\(wikimediaWidth)"
        }
    }
}
