//
//  RelationRequestSheet.swift
//  ReCIT_iOS
//
//  The confirmation before asking to join somebody's network — frame `N5a` of the « Réseau »
//  pass.
//
//  **It only confirms.** The other frame of that pair, `N5b`, drew a message field, and it was
//  dropped: `POST /api/relations/request` takes a user id and nothing else, so a message typed
//  here would go nowhere. A sheet that confirms is honest; one that collects a message the
//  server discards is not.
//

import SwiftUI
import SwiftData

struct RelationRequestSheet: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let user: User

    var body: some View {
        NavigationStack {
            VStack(spacing: .medium) {
                UserCellView(user: user)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("network.request.explanation \(user.username)")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: .zero)

                Button("network.request.send") {
                    userModel.requestRelation(with: user, modelContext: modelContext)
                    dismiss()
                }
                .buttonStyle(.primary())
                .accessibilityIdentifier("e2e.request.send")

                Button("action.cancel") {
                    dismiss()
                }
                .buttonStyle(.secondary())
            }
            .padding(.all, .medium)
            .navigationTitle("network.request.title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
