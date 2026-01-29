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
    EntityBrowserView(startingPoint: .author(uri:.init("wd:Q1685027")))
}
