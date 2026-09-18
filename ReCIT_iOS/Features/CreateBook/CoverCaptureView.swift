//
//  CoverCaptureView.swift
//  ReCIT_iOS
//
//  The camera, for the one photograph this app takes. The book is in the reader's hand — it is
//  the only moment when photographing its cover is easy — and inventaire.io has no picture of
//  the editions nobody has ever held up.
//
//  **The one UIKit seam of the feature, and deliberately the whole of it.** SwiftUI has no
//  still-camera view; `PhotosPicker` opens the library, which is the wrong place for a book
//  that is being scanned right now. So `UIImagePickerController` is wrapped here and nowhere
//  else, and falls back to the library where no camera exists — the simulator, and the
//  end-to-end scenario with it.
//
//  What leaves this file is JPEG bytes, already reduced: a nine-megapixel photograph of a
//  paperback is a slow upload and a cover nobody will ever look at full size.
//
//  See PRD 0015.
//

import SwiftUI
import UIKit

struct CoverCaptureView: UIViewControllerRepresentable {

    /// The longest edge the uploaded image keeps. A cover is displayed at a few hundred points
    /// at most, and inventaire.io resizes on its side too.
    private static let maximumDimension: CGFloat = 1600

    /// JPEG quality. High enough that a title stays readable, low enough that a phone on a
    /// bookshop's Wi-Fi is not held up by it.
    private static let compressionQuality: CGFloat = 0.8

    let onCapture: (Data) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker: UIImagePickerController = .init()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        .init(onCapture: onCapture, onFinish: { dismiss() })
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: (Data) -> Void
        private let onFinish: () -> Void

        init(onCapture: @escaping (Data) -> Void, onFinish: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onFinish = onFinish
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let data = CoverCaptureView.jpegData(for: image) {
                onCapture(data)
            }
            onFinish()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish()
        }
    }

    /// Reduces the photograph to something worth sending, and answers its JPEG bytes.
    ///
    /// `UIGraphicsImageRenderer` and not `ImageRenderer`: the house rule prefers the latter for
    /// turning a *SwiftUI view* into an image, which is not what this is. Here a `UIImage` that
    /// came out of the camera is being resampled.
    static func jpegData(for image: UIImage) -> Data? {
        let longestEdge: CGFloat = max(image.size.width, image.size.height)
        guard longestEdge > 0 else { return nil }

        let scale: CGFloat = min(1, maximumDimension / longestEdge)
        let size: CGSize = .init(width: image.size.width * scale, height: image.size.height * scale)

        let format: UIGraphicsImageRendererFormat = .default()
        format.scale = 1
        let reduced: UIImage = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: .init(origin: .zero, size: size))
        }

        return reduced.jpegData(compressionQuality: compressionQuality)
    }
}
