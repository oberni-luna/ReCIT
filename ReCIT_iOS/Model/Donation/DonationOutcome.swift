//
//  DonationOutcome.swift
//  ReCIT_iOS
//
//  How a press on « Donner » ended, which is all the donation sheet needs to know to decide what
//  it shows next.
//

import Foundation

enum DonationOutcome: Equatable {
    /// The App Store took the donation: the sheet thanks.
    case thanked
    /// It waits on someone else — Ask to Buy, a bank's confirmation. It will arrive later, through
    /// `Transaction.updates`, and the sheet says so rather than thanking for money not yet given.
    case pending
    /// The person changed their mind in the App Store's own sheet: nothing to say.
    case cancelled
    /// Anything else. The sheet says it did not go through; nothing was taken.
    case failed
}
