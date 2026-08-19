//
//  AddInventoryItemView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 19/01/2026.
//

import SwiftUI
import SwiftData

struct AddInventoryItemSearchView: View {
    @Environment(InventoryModel.self) private var inventoryModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showScanner: Bool = false
    @State private var searchResult: SearchResult?
    @State private var addingItemId: String?
    @State private var path: NavigationPath = .init()

    var body: some View {
        NavigationStack(path: $path) {
            SearchView(onNavigate: { result in
                if let destination = NavigationDestination.destinationForSearchResult(result) {
                    path.append(destination)
                }
            })
            .navigationDestination(for: NavigationDestination.self) { destination in
                destination.viewForDestination($path)
            }
            .toolbar {
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Scan", systemImage: "barcode.viewfinder") {
                        showScanner = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .imageScale(.large)
                }
            }
            // The scanner is a mode, not a one-shot reader: it stays up, files book after
            // book, and carries its own navigation stack. Presented modally so leaving it
            // returns here rather than unwinding this screen's path. See PRD 0005.
            .fullScreenCover(isPresented: $showScanner) {
                BatchScanView()
            }
        }
    }

}

