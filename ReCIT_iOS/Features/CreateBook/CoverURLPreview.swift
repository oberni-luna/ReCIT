//
//  CoverURLPreview.swift
//  ReCIT_iOS
//
//  What an address pasted into « Image depuis une URL » turned out to be: nothing yet, an image
//  — with its size, and the bytes the form's cover frame will show — or a page that is not one.
//  The three phases of `Form / Image Preview` (`716:615`) in the Figma file, plus the moment of
//  asking.
//
//  The picture is loaded by the app before it goes anywhere, for two reasons. The reader has to
//  see it: the cover will be public, and an address copied from a search page is easily the
//  wrong edition's. And the most common mistake — copying the address of Google's result page
//  rather than of the image — answers with HTML, which only decoding it can tell apart.
//
//  Loaded through the cookieless session: the address is on somebody else's server, which has
//  no business with the reader's cookies, and nothing to hand back to them either.
//
//  See PRD 0026.
//

import UIKit

enum CoverURLPreview: Equatable {
    /// No address, or none that could be fetched.
    case empty

    /// Asking the server at that address.
    case loading

    /// An image: its reduced JPEG, for the cover frame, and its size in pixels, for the caption.
    case loaded(jpeg: Data, width: Int, height: Int)

    /// The address answered with something that is not an image — or did not answer.
    case failed

    /// Fetches the address and decodes what comes back.
    static func load(_ url: URL) async -> CoverURLPreview {
        guard let (data, _) = try? await URLSession.cookieless.data(from: url),
              let image = UIImage(data: data),
              let jpeg = CoverImageReducer.jpegData(for: image) else { return .failed }

        return .loaded(
            jpeg: jpeg,
            width: Int(image.size.width * image.scale),
            height: Int(image.size.height * image.scale)
        )
    }
}
