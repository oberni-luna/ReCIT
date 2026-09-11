//
//  TipPointerShape.swift
//  ReCIT_iOS
//
//  The astuce pointer's geometry, apex down: the triangle `TipPointerView` fills.
//
//  A `Shape` of its own rather than a path drawn inline, so the pointer can be rotated or
//  flipped by whichever screen needs one aiming the other way — SORT-1 points down at a book,
//  and nothing says the next astuce will.
//

import SwiftUI

struct TipPointerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path: Path = .init()
        path.move(to: .init(x: rect.minX, y: rect.minY))
        path.addLine(to: .init(x: rect.maxX, y: rect.minY))
        path.addLine(to: .init(x: rect.midX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}
