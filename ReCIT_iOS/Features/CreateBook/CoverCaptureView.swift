//
//  CoverCaptureView.swift
//  ReCIT_iOS
//
//  The camera, for the one photograph this app takes. The book is in the reader's hand — it is
//  the only moment when photographing its cover is easy — and inventaire.io has no picture of
//  the editions nobody has ever held up.
//
//  **The UIKit seam of the feature.** SwiftUI has no still-camera view, so
//  `UIImagePickerController` is wrapped here and nowhere else. Photos and Files have SwiftUI
//  pickers of their own, offered beside it in the cover's menu, which only offers the camera
//  where there is one; the library fallback below is for a device that loses it meanwhile.
//
//  What leaves this file is JPEG bytes, reduced by `CoverImageReducer`.
//
//  See PRD 0015 and PRD 0026.
//

import SwiftUI
import UIKit

struct CoverCaptureView: UIViewControllerRepresentable {

    /// Whether this device can take a photograph — not the simulator.
    static var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

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
               let data = CoverImageReducer.jpegData(for: image) {
                onCapture(data)
            }
            onFinish()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish()
        }
    }
}
