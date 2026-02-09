//
//  EntitySummaryView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 24/01/2026.
//

import SwiftUI
import SwiftData

struct EntitySummaryView: View {
    @EnvironmentObject private var inventoryModel: InventoryModel
    @EnvironmentObject private var userModel: UserModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum ViewState {
        case loading
        case loaded(data: WpExtract)
        case error(error: Error)
        case empty
    }
    @State private var viewState: ViewState = .loading
    @State private var showMore: Bool = false

    let entityUri: String
    let otherEntityUri: String?

    init(entityUri: String, otherEntityUri: String? = nil) {
        self.entityUri = entityUri
        self.otherEntityUri = otherEntityUri
    }

    var body: some View {
        Group {
            switch viewState {
            case .loading:
                ProgressView()
            case .loaded(data: let data):
                Text(data.content)
                    .font(.subheadline)
                    .foregroundStyle(.textDefault)
                    .lineLimit(3)
                    .withLabel(label: "Résumé")
                    .onTapGesture {
                        showMore = true
                    }
                    .sheet(isPresented: $showMore) {
                        ScrollView {
                            Text(data.content)
                                .font(.body)
                                .foregroundStyle(.textDefault)
                                .padding(.all, .large)
                        }
                        .presentationDetents([.medium, .large])
                    }
            case .error(error: let error):
                Text("Error loading summary \(error.localizedDescription)")
            case .empty:
                EmptyView()
            }
        }
        .onAppear {
            Task {
                await fetchExtract()
            }
        }
    }

    @MainActor
    private func fetchExtract() async {
        do {
            if let extract = try await inventoryModel.getOrFetchExtract(forUri: entityUri, modelContext: modelContext) {
                viewState = .loaded(data: extract)
            } else {
                if let entityUri = otherEntityUri,
                   let extract = try await inventoryModel.getOrFetchExtract(forUri: entityUri, modelContext: modelContext) {
                    viewState = .loaded(data: extract)
                } else {
                    viewState = .empty
                }
            }
        } catch {
            viewState = .error(error: error)
        }
    }

    enum EntityLoaderError: Error {
        case notFound
        case undecodable
    }
}

#Preview {
//    EntitySummaryView()
}
