//
//  WikidataConnectSheet.swift
//  ReCIT_iOS
//
//  « Relier mon compte Wikidata »: wikidata.org's own page, in a sheet titled « Wikidata », and a
//  way out. The sheet closes by itself once the server sends the browser back; what happened —
//  linked, refused, given up — is read afterwards from `GET /api/user` by the screen that
//  presented it.
//

import SwiftUI

struct WikidataConnectSheet: View {
    @Environment(AuthModel.self) private var authModel
    @Environment(UserModel.self) private var userModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let baseURL = URL(string: userModel.apiService.baseUrl()) {
                    WikidataWebView(
                        startURL: WikidataOAuthFlow.startURL(baseURL: baseURL),
                        baseURL: baseURL,
                        cookies: authModel.webSessionCookies(),
                        onReturn: { dismiss() }
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle("account.wikidata.sheet.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close", systemImage: "xmark") {
                        dismiss()
                    }
                    .accessibilityIdentifier("e2e.account.wikidata.close")
                }
            }
        }
    }
}
