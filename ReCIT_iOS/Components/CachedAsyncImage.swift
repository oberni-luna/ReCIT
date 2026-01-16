//
//  CachedAsyncImage.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 14/01/2026.
//


import SwiftUI
import AVFoundation
import Nuke

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    private let imageAppearanceDuration: TimeInterval = 0.1

    @State private var loadedImage: Image?

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            if loadedImage == nil {
                placeholder()
                    .transition(
                        .asymmetric(
                            insertion: .identity,
                            removal: .opacity.animation(.easeOut(duration: imageAppearanceDuration))
                        )
                    )
            }

            if let loadedImage: Image = loadedImage {
                content(loadedImage)
                    .transition(.opacity.animation(.easeIn(duration: imageAppearanceDuration)))
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .task(id: url) {
                        guard let url = url else { return }
                        let targetSize: CGSize = proxy.size
                        do {
                            let uiImage: UIImage = try await ImageLoader.shared.load(
                                url: url,
                                targetSize: targetSize
                            )
                            loadedImage = Image(uiImage: uiImage)
                        } catch {
                            loadedImage = nil
                        }
                    }
            }
        }
        .id(url)
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Content == Image {
    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.init(
            url: url,
            content: { $0 },
            placeholder: placeholder
        )
    }
}

// MARK: - ImageLoader

private actor ImageLoader {
    enum ImageLoaderError: Error {
        case canceled
        case undecodable
    }

    static let shared: ImageLoader = ImageLoader()

    private let pipeline: ImagePipeline

    init() {
        var configuration: ImagePipeline.Configuration = .withDataCache(
            name: "com.fitnesspark.imagecache",
            sizeLimit: 1024 * 1024 * 200 // 200 MB disk cache
        )

        let imageCache: ImageCache = .init(
            costLimit: 1024 * 1024 * 150, // 150 MB
            countLimit: 100 // Up to 100 images in memory
        )
        configuration.imageCache = imageCache

        self.pipeline = ImagePipeline(configuration: configuration)
    }

    /// Loads an image asynchronously with Nuke caching. The resulting image is "inflated" (decoded to pixels)
    /// before being returned, ensuring it renders quickly without scroll jank.
    func load(url: URL, targetSize: CGSize?) async throws -> UIImage {
        let request: ImageRequest = .init(url: url)

        if let cachedImage: UIImage = getCachedImage(for: request) {
            return try await processImage(cachedImage, targetSize: targetSize)
        }

        let downloadedImage: UIImage = try await downloadImage(from: url)
        cacheImage(downloadedImage, for: request)

        let processedImage: UIImage = try await processImage(downloadedImage, targetSize: targetSize)
        inflateImage(processedImage)

        return processedImage
    }

    private func getCachedImage(for request: ImageRequest) -> UIImage? {
        pipeline.cache[request]?.image
    }

    private func downloadImage(from url: URL) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard !Task.isCancelled else { throw ImageLoaderError.canceled }
        guard let uiImage = UIImage(data: data, scale: 1.0) else { throw ImageLoaderError.undecodable }
        guard !Task.isCancelled else { throw ImageLoaderError.canceled }
        return uiImage
    }

    private func cacheImage(_ image: UIImage, for request: ImageRequest) {
        let imageContainer: ImageContainer = .init(image: image)
        pipeline.cache[request] = imageContainer
    }

    private func processImage(_ image: UIImage, targetSize: CGSize?) async throws -> UIImage {
        guard let targetSize = targetSize else { return image }

        let screenScale: CGFloat = await UIScreen.main.scale
        guard shouldResize(image, targetSize: targetSize, screenScale: screenScale) else {
            return image
        }

        guard !Task.isCancelled else { throw ImageLoaderError.canceled }

        if let resizedImage = resizedImage(uiImage: image, scale: screenScale, targetSize: targetSize) {
            return resizedImage
        }

        return image
    }

    private func shouldResize(_ image: UIImage, targetSize: CGSize, screenScale: CGFloat) -> Bool {
        image.size.width > targetSize.width * screenScale
            || image.size.height > targetSize.height * screenScale
    }

    private func inflateImage(_ image: UIImage) {
        // Inflate the UIImage by forcing decode to pixels
        // https://developer.apple.com/forums/thread/653738
        _ = image.cgImage?.dataProvider?.data
    }

    /// Resizes an image to fit within the target size while maintaining aspect ratio.
    /// https://nshipster.com/image-resizing/
    private func resizedImage(
        uiImage: UIImage,
        scale: CGFloat,
        targetSize: CGSize
    ) -> UIImage? {
        let scaledTargetSize: CGSize = .init(
            width: targetSize.width * scale,
            height: targetSize.height * scale
        )
        let scaledBounds: CGRect = AVMakeRect(
            aspectRatio: uiImage.size,
            insideRect: CGRect(origin: .zero, size: scaledTargetSize)
        )
        let format: UIGraphicsImageRendererFormat = .init()
        format.scale = scale
        let renderer: UIGraphicsImageRenderer = .init(
            bounds: scaledBounds,
            format: format
        )
        return renderer.image { _ in
            uiImage.draw(in: scaledBounds)
        }
    }
}
