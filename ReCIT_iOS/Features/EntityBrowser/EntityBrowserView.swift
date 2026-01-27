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
                startingPoint.viewForDestination($path)
            }
            .navigationDestination(for: EntityDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .navigationDestination(for: Edition.self) { edition in
                EditionDetailView(editionUri: edition.uri, path: $path)
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

    @ViewBuilder
    func viewForDestination(destination: EntityDestination) -> some View {
        switch destination {
        case .author(let uri):
            AuthorDetailView(authorUri: uri, path: $path)
        case .work(let uri):
            WorkDetailView(workUri: uri, path: $path)
        case .edition(let uri):
            EditionDetailView(editionUri: uri, path: $path)
        }
    }
}

#Preview {
    EntityBrowserView(startingPoint: .author(uri:"wd:Q1685027"))
}
