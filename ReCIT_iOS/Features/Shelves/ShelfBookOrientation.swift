//
//  ShelfBookOrientation.swift
//  ReCIT_iOS
//
//  How a book sits on the shelf — it decides which way its cover sliver runs and how its
//  title is set. Top-level rather than nested in `PaintedBookView`, which is generic over its
//  overlay and so cannot be named without type arguments. See ADR 0006.
//

enum ShelfBookOrientation {
    /// Standing spine-out: the cover's height runs along the book's height.
    case standing
    /// Lying flat in a pile: the cover's height runs along the book's length, and the sliver
    /// is stretched vertically over its thickness.
    case lying
}
