//
//  CreateBookRequest.swift
//  ReCIT_iOS
//
//  What the scanner asks for when a barcode came back unknown: a book that does not exist on
//  inventaire.io yet, named by the one thing we are sure of — the ISBN the camera read.
//
//  Free of SwiftUI and SwiftData, like `ContainerCreationRequest` and for the same reason: it
//  is a demand written into a binding, and the screen that mounts the sheet decides what to do
//  with it. See PRD 0015.
//

import Foundation

struct CreateBookRequest: Identifiable, Equatable, Sendable {

    /// The barcode, as the camera read it. Also the identity of the demand, which is what
    /// `.sheet(item:)` presents on: the same unknown book asked for twice is one sheet.
    let isbn: String

    var id: String { isbn }
}
