//
//  BatchScanEvent.swift
//  ReCIT_iOS
//
//  Everything that can happen to the batch scanner's row, as seen by the state machine.
//  Deliberately free of camera and network types: the view layer translates a `ScanResult`
//  or a network outcome into one of these.
//

import Foundation

enum BatchScanEvent: Equatable {
    /// A barcode is in frame. Fired continuously by the camera while the book is held up,
    /// which is why the machine — not the caller — decides whether it counts.
    case codeSeen(String)
    case lookupResolved(ScannedBook)
    case lookupFailed(code: String)
    case addStarted
    case addFinished
    case addFailed
    /// The row has said what it had to say and gives the screen back to the camera.
    case cleared
}
