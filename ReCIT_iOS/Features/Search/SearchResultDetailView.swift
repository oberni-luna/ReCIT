//
//  SearchResultDetailView.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/12/2025.
//

import SwiftUI

struct SearchResultDetailView: View {
    let result: SearchResult

    var body: some View {
        switch result.type {
        case .humans:
            SearchResultHumanDetailView(result: result)
        case .works:
            SearchResultWorkDetailView(result: result)
        default:
            SearchResultOtherDetailView(result: result)
        }
    }
}

struct SearchResultHumanDetailView: View {
    let result: SearchResult

    var body: some View {
        SearchResultDetailContentView(result: result)
            .navigationTitle(result.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct SearchResultWorkDetailView: View {
    let result: SearchResult

    var body: some View {
        SearchResultDetailContentView(result: result)
            .navigationTitle(result.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct SearchResultOtherDetailView: View {
    let result: SearchResult

    var body: some View {
        SearchResultDetailContentView(result: result)
            .navigationTitle(result.title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SearchResultDetailContentView: View {
    let result: SearchResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if result.imageUrl != nil {
                    EditionImage(imageUrl: result.imageUrl, contentMode: .fit)
                        .frame(maxHeight: 260)
                        .clipped()
                }

                Text(result.title)
                    .font(.title2)
                    .bold()

                if let description = result.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}
