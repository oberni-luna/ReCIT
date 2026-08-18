//
//  ShelfBookSelection.swift
//  ReCIT_iOS
//
//  Which book is currently singled out (grown) on the bookshelf. Held once for the whole
//  carousel so only one book stands out at a time: tapping a book on another étagère
//  moves the selection there. See ADR 0003.
//

struct ShelfBookSelection: Equatable {
    let shelfId: String
    let index: Int
}
