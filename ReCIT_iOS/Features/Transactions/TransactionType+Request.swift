//
//  TransactionType+Request.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 01/11/2026.
//

import Foundation

/// The words of a request, taken from the status of the copy asked for.
///
/// inventaire.io derives a transaction's type from the item it is about — `POST /api/transactions`
/// takes only `item` and `message` — so the request form names it rather than asking for it.
/// `.inventorying` is never requested (its copies offer no entry); it falls back to the generic
/// wording.
extension TransactionType {
    /// The form's title: « Emprunter What If? à Q2 ».
    func requestTitle(book: String, owner: String) -> LocalizedStringResource {
        switch self {
        case .lending: "transaction.request.title.lending \(book) \(owner)"
        case .selling: "transaction.request.title.selling \(book) \(owner)"
        case .giving: "transaction.request.title.giving \(book) \(owner)"
        case .inventorying: "transaction.form.header \(book) \(owner)"
        }
    }

    /// What the request amounts to, in Markdown: « Vous souhaitez l'emprunter à **Q2** ».
    func requestSentence(owner: String) -> LocalizedStringResource {
        switch self {
        case .lending: "transaction.desc.requester.lending \(owner)"
        case .selling: "transaction.desc.requester.selling \(owner)"
        case .giving: "transaction.desc.requester.giving \(owner)"
        case .inventorying: "transaction.desc.inventoried"
        }
    }

    /// The submit button: « Demander à l'emprunter ».
    var requestButtonLabel: LocalizedStringResource {
        switch self {
        case .lending: "transaction.request.button.lending"
        case .selling: "transaction.request.button.selling"
        case .giving: "transaction.request.button.giving"
        case .inventorying: "transaction.action.request"
        }
    }

    /// The label above the message, with a hint at what to say.
    var requestMessageLabel: LocalizedStringResource {
        switch self {
        case .lending: "transaction.request.message.lending"
        case .selling: "transaction.request.message.selling"
        case .giving: "transaction.request.message.giving"
        case .inventorying: "transaction.form.your_message_required"
        }
    }

    /// A menu entry asking `owner` for their copy: « Acheter à Q2 ».
    func requestMenuLabel(owner: String) -> LocalizedStringResource {
        switch self {
        case .lending, .inventorying: "action.borrow_from_user \(owner)"
        case .selling: "action.buy_from_user \(owner)"
        case .giving: "action.take_from_user \(owner)"
        }
    }

    /// The title of a menu of owners, each a button with their name: « Acheter à ».
    var requestMenuTitle: LocalizedStringResource {
        switch self {
        case .lending, .inventorying: "action.borrow_from"
        case .selling: "action.buy_from"
        case .giving: "action.take_from"
        }
    }
}
