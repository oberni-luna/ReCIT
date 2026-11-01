//
//  AccountWikidataSection.swift
//  ReCIT_iOS
//
//  The « Wikidata » section of « Compte et connexion » (`W1` and `W3` in the Figma file). Not
//  linked: one row that opens wikidata.org in a sheet. Linked: that it is, and Wikimedia's page
//  where the access is taken back — inventaire.io has no way to unlink.
//
//  Linking changes who signs an edit, not whether one is possible: without tokens, inventaire.io
//  publishes a change to a Wikidata work or person with its bot, naming the account in the
//  summary. The footer says which.
//

import LBSnackBar
import SwiftData
import SwiftUI

struct AccountWikidataSection: View {
    @Environment(UserModel.self) private var userModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.snackBar) private var snackBar

    let isLinked: Bool

    @State private var isConnecting: Bool = false

    var body: some View {
        Section {
            if isLinked {
                Text("account.wikidata.linked")
                    .textStyle(.content300)
                    .foregroundStyle(.foregroundDefault)
                    .withLabel(label: "account.wikidata.account")

                AboutInventaireLinkRow(
                    title: "account.wikidata.manage",
                    destination: WikidataOAuthFlow.manageGrantsURL
                )
                .listRowInsets(.init())
                .accessibilityIdentifier("e2e.account.wikidata.manage")
            } else {
                Button("account.wikidata.connect") {
                    isConnecting = true
                }
                .textStyle(.action300)
                .foregroundStyle(.foregroundTinted)
                .accessibilityIdentifier("e2e.account.wikidata.connect")
            }
        } header: {
            CreateBookSectionHeader("account.wikidata.header")
        } footer: {
            CreateBookSectionFooter(isLinked ? "account.wikidata.footer.linked" : "account.wikidata.footer")
        }
        .sheet(isPresented: $isConnecting, onDismiss: refresh) {
            WikidataConnectSheet()
        }
    }

    /// Reads the account again: the sheet cannot tell a link from a refusal, `enabledOAuth` can.
    private func refresh() {
        Task {
            do {
                try await userModel.syncMyUser(modelContext: modelContext)
                if userModel.account?.linksWikidata == true {
                    snackBar.show {
                        SnackBarView(title: String(localized: "account.wikidata.linked.confirmation"), onDismiss: nil)
                    }
                }
            } catch {
                snackBar.show { SnackBarView.error(error) }
            }
        }
    }
}
