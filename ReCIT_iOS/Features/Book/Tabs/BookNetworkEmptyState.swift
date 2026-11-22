//
//  BookNetworkEmptyState.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// Dans le réseau on a book nobody in my network holds, neither as a copy nor in a list.
struct BookNetworkEmptyState: View {
    var body: some View {
        Section {
            Text("book.network.empty")
                .textStyle(.content300)
                .foregroundStyle(.foregroundSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .large)
                .padding(.horizontal, .medium)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

#Preview {
    List {
        BookNetworkEmptyState()
    }
}
