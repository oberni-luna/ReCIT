//
//  TransactionRequestWordingTests.swift
//  ReCIT_iOSTests
//
//  The request form names what is asked for from the copy's status instead of offering a type
//  picker inventaire.io would ignore. Pure and network-free.
//

import Foundation
import Testing
@testable import ReCIT_iOS

@Suite
struct TransactionRequestWordingTests {
    private func french(_ resource: LocalizedStringResource) -> String {
        var resource: LocalizedStringResource = resource
        resource.locale = .init(identifier: "fr")
        return String(localized: resource)
    }

    @Test
    func lendingAsksToBorrow() {
        let type: TransactionType = .lending

        #expect(french(type.requestTitle(book: "What If?", owner: "Q2")) == "Emprunter What If? à Q2")
        #expect(french(type.requestSentence(owner: "Q2")) == "Vous souhaitez l'emprunter à **Q2**")
        #expect(french(type.requestButtonLabel) == "Demander à l'emprunter")
        #expect(french(type.requestMenuLabel(owner: "Q2")) == "Emprunter à Q2")
        #expect(french(type.requestMenuTitle) == "Emprunter à")
    }

    @Test
    func sellingAsksToBuy() {
        let type: TransactionType = .selling

        #expect(french(type.requestTitle(book: "What If?", owner: "Q2")) == "Acheter What If? à Q2")
        #expect(french(type.requestSentence(owner: "Q2")) == "Vous souhaitez l'acheter à **Q2**")
        #expect(french(type.requestButtonLabel) == "Demander à l'acheter")
        #expect(french(type.requestMenuLabel(owner: "Q2")) == "Acheter à Q2")
        #expect(french(type.requestMenuTitle) == "Acheter à")
    }

    @Test
    func givingAsksToTake() {
        let type: TransactionType = .giving

        #expect(french(type.requestTitle(book: "What If?", owner: "Q2")) == "Récupérer What If? de Q2")
        #expect(french(type.requestSentence(owner: "Q2")) == "Vous souhaitez le récupérer de **Q2**")
        #expect(french(type.requestButtonLabel) == "Demander à le récupérer")
        #expect(french(type.requestMenuLabel(owner: "Q2")) == "Récupérer de Q2")
        #expect(french(type.requestMenuTitle) == "Récupérer de")
    }

    @Test(arguments: [TransactionType.lending, .selling, .giving])
    func messageLabelSaysItIsRequiredAndHints(type: TransactionType) {
        let label: String = french(type.requestMessageLabel)

        #expect(label.hasPrefix("Votre message (obligatoire) : "))
        #expect(label.hasSuffix(" ?"))
    }
}
