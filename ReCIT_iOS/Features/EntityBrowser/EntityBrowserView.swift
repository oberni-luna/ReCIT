//
//  EntityBrowserView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 23/01/2026.
//

import SwiftUI

struct EntityBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var path: NavigationPath = .init()

    let startingPoint: EntityDestination

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch startingPoint {
                case .author(let uri):
                    AuthorDetailView(authorUri: uri, path: $path)
                case .work(let uri):
                    WorkDetailView(workUri: uri, path: $path)
                }
            }
            .navigationDestination(for: EntityDestination.self) { destination in
                switch destination {
                case .author(let uri):
                    AuthorDetailView(authorUri: uri, path: $path)
                case .work(let uri):
                    WorkDetailView(workUri: uri, path: $path)
                }
            }
            .navigationDestination(for: Edition.self) { edition in
                EditionDetailView(edition: edition, path: $path)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }


}

#Preview {
    EntityBrowserView(startingPoint: .author(uri:"wd:Q1685027"))
}
