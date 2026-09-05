//
//  CoverWallCatalog.swift
//  ReCIT_iOS
//
//  Turns what inventaire.io last published into the list of covers a wall can draw, and builds
//  each cover's URL at the size it is actually shown.
//
//  Three jobs, all of them arithmetic on strings, all of them pure:
//
//  1. **Sift.** An item without cover art contributes nothing, and the same edition coming back
//     twice — two people owning the same book is the normal case on a public feed — must not be
//     drawn twice side by side. Order is preserved: the feed is chronological and the wall
//     should open on what was added last.
//  2. **Cap.** Sixty covers is a wall; six hundred is a download.
//  3. **Size.** inventaire.io resizes server-side: `/img/entities/200x300/<hash>` weighs about
//     11 kB where `/img/entities/<hash>` weighs 346 kB. Asking for the full-size jacket of every
//     cover on the wall would cost some twenty megabytes to draw a background.
//
//  The sizing knowledge is deliberately local to the wall. `APIService.absoluteImageUrl` builds
//  full-size URLs for every thumbnail in the app, which is a real and separate performance
//  problem — see PRD 0011's *Out of Scope*.
//
//  Pure by design — no SwiftUI, no network, no images. See PRD 0011.
//

import CoreGraphics
import Foundation

struct CoverWallCatalog: Equatable, Sendable {

    /// How many covers a wall keeps. Sixty is what `recent-public` serves in one call, and
    /// about twice what a phone-sized wall shows at once — enough that nothing repeats.
    static let coverLimit: Int = 60

    /// The image paths to draw, in feed order, without holes and without duplicates.
    let coverPaths: [String]

    /// Sifts a feed's image paths. `nil` and empty entries are items with no cover art: they
    /// contribute nothing, and the wall paints their slots instead.
    init(imagePaths: [String?], limit: Int = Self.coverLimit) {
        var seen: Set<String> = []
        var kept: [String] = []

        for path in imagePaths {
            guard kept.count < max(0, limit) else { break }
            guard let path, path.isEmpty == false else { continue }
            guard seen.contains(path) == false else { continue }

            seen.insert(path)
            kept.append(path)
        }

        self.coverPaths = kept
    }

    // MARK: - URLs

    /// The URL of one cover, resized by the server to the frame it will be drawn in.
    ///
    /// `scale` is the screen's, so a 88 × 132 pt slot on a 3× phone asks for 264 × 396 px.
    /// Anything that is not an inventaire.io image path is left exactly as it is: the resizing
    /// segment is that server's convention and means nothing elsewhere.
    static func url(
        baseUrl: String,
        path: String,
        coverSize: CGSize,
        scale: CGFloat
    ) -> URL? {
        let sized: String = sizedPath(path, coverSize: coverSize, scale: scale)

        if sized.hasPrefix("http") {
            return URL(string: sized)
        }

        return URL(string: "\(baseUrl)\(sized)")
    }

    /// Inserts the size segment inventaire.io expects: `/img/entities/<hash>` becomes
    /// `/img/entities/<w>x<h>/<hash>`. A path that already carries one is left alone, and so is
    /// anything that is not an `/img/` path.
    static func sizedPath(_ path: String, coverSize: CGSize, scale: CGFloat) -> String {
        let components: [String] = path.split(separator: "/", omittingEmptySubsequences: false)
            .map(String.init)

        // ["", "img", "entities", "<hash>"] — four components, the last one being the hash.
        guard components.count == 4, components[1] == "img" else { return path }

        let width: Int = pixels(coverSize.width, scale: scale)
        let height: Int = pixels(coverSize.height, scale: scale)

        guard width > 0, height > 0 else { return path }

        return "/\(components[1])/\(components[2])/\(width)x\(height)/\(components[3])"
    }

    private static func pixels(_ points: CGFloat, scale: CGFloat) -> Int {
        guard points.isFinite, scale.isFinite else { return 0 }

        return Int((points * max(1, scale)).rounded())
    }
}
