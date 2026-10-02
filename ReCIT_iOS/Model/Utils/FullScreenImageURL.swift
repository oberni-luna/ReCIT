//
//  FullScreenImageURL.swift
//  ReCIT_iOS
//
//  The address of a cover at the size worth showing on a whole screen.
//
//  inventaire.io serves `/img/entities/<hash>` at its original size when no `WxH` is given, which
//  is already the best there is. Wikimedia's `Special:FilePath` is asked for a `width`, and the
//  app — like inventaire.io — asks for 512 or 1024, a third of a phone screen's pixels at best.
//

import Foundation

enum FullScreenImageURL {

    /// Wide enough for any phone screen at its native scale; Wikimedia never upscales past the
    /// file's own width.
    static let wikimediaWidth: Int = 2048

    /// `url` with any size it asks for raised to a full screen's, or `url` itself when it already
    /// names the original.
    static func resolve(_ url: URL) -> URL {
        guard url.host() == "commons.wikimedia.org",
              url.path().contains("Special:FilePath"),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        var items: [URLQueryItem] = (components.queryItems ?? []).filter { $0.name != "width" }
        items.append(.init(name: "width", value: String(wikimediaWidth)))
        components.queryItems = items
        return components.url ?? url
    }
}
