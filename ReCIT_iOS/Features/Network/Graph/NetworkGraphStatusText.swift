//
//  NetworkGraphStatusText.swift
//  ReCIT_iOS
//
//  The look of what the status pill of « Tout » says — the counter, « Synchronisation… »: `action200`
//  in `foregroundSecondary`, on one line, in a capsule of Liquid Glass (`compteur`, `521:15993`,
//  Q35).
//

import SwiftUI

struct NetworkGraphStatusText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textStyle(.action200)
            .foregroundStyle(.foregroundSecondary)
            .lineLimit(1)
            .padding(NetworkGraphMetrics.statusInsets)
            .glassEffect(.regular, in: .capsule)
    }
}
