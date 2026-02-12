//
//  TransactionDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/02/2026.
//
import SwiftData
import SwiftUI

struct TransactionCellView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userModel: UserModel
    
    let transaction: UserTransaction
    var amIRequester: Bool {
        transaction.requester._id == userModel.myUser?._id
    }

    var body: some View {
        if let edition = transaction.item.edition {
            HStack(alignment: .top, spacing: .sMedium) {
                CellThumbnail(imageUrl: edition.image, cornerRadius: .minimal, size: 48)

                VStack(alignment: .leading, spacing: .xSmall) {
                    Group {
                        Text(edition.title)
                            .font(.headline)
                        Text(.init(transactionDescription))
                            .font(.subheadline)
                    }
                    .foregroundStyle(.textDefault)

                    TransactionStateLabel(state: transaction.state)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    var transactionDescription: String {
        if amIRequester {
            switch transaction.type {
            case .lending:
                "Vous souhaitez l'emprunter à **\(transaction.owner.username)**"
            case .inventorying:
                "Inventorié"
            case .selling:
                "Vous souhaitez l'acheter à **\(transaction.owner.username)**"
            case .giving:
                "Vous souhaitez le récupérer de **\(transaction.owner.username)**"
            }
        } else {
            switch transaction.type {
            case .lending:
                "**\(transaction.requester.username)** souhaite l'emprunter"
            case .inventorying:
                "Inventorié"
            case .selling:
                "**\(transaction.requester.username)** souhaite l'acheter"
            case .giving:
                "**\(transaction.requester.username)** souhaite le récupérer"
            }
        }
    }

}
