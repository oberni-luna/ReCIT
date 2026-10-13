//
//  NetworkGroupCardBorder.swift
//  ReCIT_iOS
//
//  The edge of a group card in the Réseau graph: a green hairline for a group I administer or
//  belong to, a dashed `foregroundTinted` line for one that invited me (`Graph / Group`, Q32).
//

import SwiftUI

struct NetworkGroupCardBorder: View {
    let role: NetworkGroupRole

    var body: some View {
        let shape: RoundedRectangle = .rect(cornerRadius: .rounded)
        switch role {
        case .admin, .member:
            shape.strokeBorder(
                DesignSystem.Color.borderTinted.color,
                lineWidth: NetworkGraphMetrics.groupBorderWidth
            )
        case .invited:
            shape.strokeBorder(
                DesignSystem.Color.foregroundTinted.color,
                style: .init(
                    lineWidth: NetworkGraphMetrics.invitedBorderWidth,
                    dash: NetworkGraphMetrics.dash
                )
            )
        }
    }
}
