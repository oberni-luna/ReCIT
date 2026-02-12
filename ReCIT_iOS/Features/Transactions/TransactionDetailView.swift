//
//  TransactionDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 07/02/2026.
//
import SwiftData
import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userModel: UserModel
    
    let transaction: UserTransaction

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: .xSmall) {
                    Text(transaction.item.edition?.title ?? "Unkown title")
                        .font(.title)
                    Text("\(transaction.created.formatted()) : \(transaction.owner.username) → \(transaction.requester.username)")
                    Text(transaction.state.rawValue)
                }
            }

            if transaction.messages.count >= 1 {
                Section("Messages") {
                    ForEach(transaction.messages) { message in
                        Text("\" \(message.message) \n-- \(message.user.username)")
                    }
                }
            }
        }
    }
}

