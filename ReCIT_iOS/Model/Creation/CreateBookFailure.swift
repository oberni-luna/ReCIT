//
//  CreateBookFailure.swift
//  ReCIT_iOS
//
//  What went wrong when a book would not publish, in the terms the reader needs — not the
//  terms the network used.
//
//  A pure type, like `AuthOutcome` and the other answers in `Model/Authentication/`: the
//  mapping from a status code to a sentence is a decision, and a decision belongs somewhere it
//  can be asserted. The one sentence that always holds, whatever the case, is that **nothing
//  was created on inventaire.io** — which is what makes trying again safe, and what a reader
//  who fears having made a duplicate needs to be told first.
//
//  See PRD 0015.
//

import Foundation

enum CreateBookFailure: Equatable, Sendable {

    /// The session is gone, or there never was one. Contributing to the open database is not
    /// anonymous, and saying so is more use than saying « 401 ».
    case needsAccount

    /// inventaire.io refused the entry: an ISBN it will not take, a claim it will not accept.
    /// Rare, and not something a retry fixes by itself.
    case refused

    /// The request never got an answer it could use — no network, a server that timed out, an
    /// answer that would not decode. The case a retry is actually for.
    case network

    init(error: Error) {
        guard let networkError = error as? NetworkError else {
            self = .network
            return
        }

        switch networkError {
        case .badStatus(let code, _) where code == 401 || code == 403:
            self = .needsAccount
        case .badStatus(let code, _) where (400..<500).contains(code):
            self = .refused
        case .badStatus, .badResponse, .badUrl, .invalidRequest, .transport,
             .failedToEncodeRequest, .failedToDecodeResponse:
            self = .network
        }
    }

    var title: String.LocalizationValue {
        switch self {
        case .needsAccount: "create_book.failure.account.title"
        case .refused: "create_book.failure.refused.title"
        case .network: "create_book.failure.network.title"
        }
    }

    var explanation: String.LocalizationValue {
        switch self {
        case .needsAccount: "create_book.failure.account.body"
        case .refused: "create_book.failure.refused.body"
        case .network: "create_book.failure.network.body"
        }
    }

    /// Whether trying the same thing again is worth offering. A refused entry is not going to
    /// be accepted by asking twice, and an account cannot be obtained from this sheet.
    var isWorthRetrying: Bool {
        self == .network
    }
}
