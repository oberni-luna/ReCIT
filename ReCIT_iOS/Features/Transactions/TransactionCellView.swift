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

    var isRead: Bool {
        ( amIRequester && !transaction.readStatus.requester ) ||
        ( !amIRequester && !transaction.readStatus.owner )
    }

    var body: some View {
        if let edition = transaction.item.edition {
            HStack(alignment: .top, spacing: .sMedium) {
                CellThumbnail(imageUrl: edition.image, cornerRadius: .minimal, size: 48)

                VStack(alignment: .leading, spacing: .xSmall) {
                    Group {
                        HStack(spacing: .small) {
                            if !isRead {
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundStyle(.foregroundTinted)
                            }
                            Text(edition.title)
                                .textStyle(.content400Bold)
                        }
                        Text(.init(transactionDescription))
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundDefault)
                    }
                    .foregroundStyle(.foregroundDefault)

                    TransactionStateLabel(state: transaction.state)
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            }
        }
    }

    var transactionDescription: String {
        if amIRequester {
            switch transaction.type {
            case .lending:
                String(localized: "transaction.desc.requester.lending \(transaction.owner.username)")
            case .inventorying:
                String(localized: "transaction.desc.inventoried")
            case .selling:
                String(localized: "transaction.desc.requester.selling \(transaction.owner.username)")
            case .giving:
                String(localized: "transaction.desc.requester.giving \(transaction.owner.username)")
            }
        } else {
            switch transaction.type {
            case .lending:
                String(localized: "transaction.desc.owner.lending \(transaction.requester.username)")
            case .inventorying:
                String(localized: "transaction.desc.inventoried")
            case .selling:
                String(localized: "transaction.desc.owner.selling \(transaction.requester.username)")
            case .giving:
                String(localized: "transaction.desc.owner.giving \(transaction.requester.username)")
            }
        }
    }

}
