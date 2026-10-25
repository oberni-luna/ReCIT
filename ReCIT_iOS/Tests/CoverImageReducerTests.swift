//
//  CoverImageReducerTests.swift
//  ReCIT_iOSTests
//
//  What leaves the device as a cover, whichever way it came in: a JPEG no longer than 1600
//  points on its longest edge, or nothing when the bytes are not an image.
//
//  See PRD 0026.
//

import Testing
import UIKit
@testable import ReCIT_iOS

@MainActor
@Suite("CoverImageReducer")
struct CoverImageReducerTests {

    private func pngData(width: CGFloat, height: CGFloat) -> Data {
        let format: UIGraphicsImageRendererFormat = .default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: .init(width: width, height: height), format: format)
            .pngData { context in
                UIColor.systemTeal.setFill()
                context.fill(.init(x: 0, y: 0, width: width, height: height))
            }
    }

    @Test("A large picture comes back as a JPEG 1600 on its longest edge")
    func largePictureIsReduced() throws {
        let jpeg: Data = try #require(CoverImageReducer.jpegData(from: pngData(width: 2400, height: 3200)))
        let image: UIImage = try #require(UIImage(data: jpeg))

        #expect(image.size == .init(width: 1200, height: 1600))
    }

    @Test("A small picture keeps its size")
    func smallPictureIsKept() throws {
        let jpeg: Data = try #require(CoverImageReducer.jpegData(from: pngData(width: 400, height: 600)))
        let image: UIImage = try #require(UIImage(data: jpeg))

        #expect(image.size == .init(width: 400, height: 600))
    }

    @Test("Bytes that are not an image give nothing")
    func notAnImage() {
        #expect(CoverImageReducer.jpegData(from: Data("<html></html>".utf8)) == nil)
    }
}
