//
//  CoverAddress.swift
//  ReCIT_iOS
//
//  A cover designated by its address on the web: what counts as one, and where to look for it.
//
//  The address goes to inventaire.io as it is, in the edition seed's `image`, and `resolve`
//  fetches it itself (`convertAndCleanupImageUrl`). So the only addresses worth accepting are
//  the ones its `isUrl` accepts — http or https, with a host — and the app checks that before
//  anything is loaded.
//
//  See PRD 0026.
//

import Foundation

enum CoverAddress {

    /// The url an address typed or pasted designates, or `nil` when it is not one the server
    /// could fetch.
    static func url(from text: String) -> URL? {
        let trimmed: String = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host(),
              host.isEmpty == false else { return nil }

        return url
    }

    /// A Google Images search for the book: the title of the work and the ISBN, which together
    /// find this edition's cover more often than either alone.
    static func googleImagesURL(title: String, isbn: String) -> URL? {
        let terms: String = [title, isbn]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        var components: URLComponents? = .init(string: "https://www.google.com/search")
        components?.queryItems = [
            .init(name: "tbm", value: "isch"),
            .init(name: "q", value: terms)
        ]
        return components?.url
    }
}
