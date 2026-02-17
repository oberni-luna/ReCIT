//
//  SnackBarView.swift
//  DesignSystem
//
//  Created by Rémi Lanteri on 14/11/2025.

import SwiftUI

public struct SnackBarView: View {

    let title: String
    let subtitle: String?
    let onDismiss: (() -> Void)?

    public init(title: String, subtitle: String? = nil, onDismiss: (() -> Void)?) {
        self.title = title
        self.subtitle = subtitle
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: .small) {
            VStack(alignment: .leading, spacing: .xSmall) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textDefault)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.textDefault)
                }
            }
            Spacer()
            if let onDismiss {
                Button("", systemImage: "xmark") {
                    onDismiss()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.all, .medium)
        .background(.thickMaterial)
        .cornerRadius(.rounded)
        .padding(.all, .medium)
    }
}
