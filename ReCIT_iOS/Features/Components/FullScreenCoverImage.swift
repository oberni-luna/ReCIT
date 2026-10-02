//
//  FullScreenCoverImage.swift
//  ReCIT_iOS
//
//  A cover opened full screen: drawn at once from what the screen behind already loaded, then
//  replaced by the sharpest version there is as soon as it arrives.
//
//  Drawn at once, because the zoom transition starts on the first frame: an image still loading
//  there was a dark, empty card growing out of the header. Replaced, because what the header
//  loaded is sized for the header — and `CachedAsyncImage`, given a placeholder's frame to size
//  its load to, used to shrink the full-screen cover to the size of a spinner.
//

import SwiftUI

struct FullScreenCoverImage<Content: View>: View {
    private let url: URL
    private let content: (Image) -> Content

    /// What is already in memory for the header's url, read before the first frame.
    @State private var shown: UIImage?
    /// The full-size version, once it is in.
    @State private var sharp: UIImage?

    init(url: URL, @ViewBuilder content: @escaping (Image) -> Content) {
        self.url = url
        self.content = content
        _shown = .init(initialValue: ImageLoader.shared.memoryCachedImage(for: url))
    }

    var body: some View {
        ZStack {
            if let shown {
                content(Image(uiImage: shown))
            } else if sharp == nil {
                ProgressView()
            }

            if let sharp {
                content(Image(uiImage: sharp))
                    .transition(.opacity)
            }
        }
        .task(id: url) {
            let sharpURL: URL = FullScreenImageURL.resolve(url)
            // The header's url already names the original: what is in memory is it, whole.
            if sharpURL == url, shown != nil { return }

            guard let image = try? await ImageLoader.shared.loadOriginal(url: sharpURL) else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                sharp = image
            }
        }
    }
}
