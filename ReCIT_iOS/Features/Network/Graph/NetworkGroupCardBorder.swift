//
//  NetworkGroupCardBorder.swift
//  ReCIT_iOS
//
//  The edge of a group card in the Réseau graph: a green hairline for a group I administer or
//  belong to, a dashed `foregroundTinted` line for one that invited me (`Graph / Group`, Q32).
//  Selected, every card has the same edge, in the colour of its fill, so it does not read as a
//  stroke of its own (Q25).
//

import SwiftUI

struct NetworkGroupCardBorder: View {
    let role: NetworkGroupRole
    var isSelected: Bool = false

    var body: some View {
        let shape: RoundedRectangle = .rect(cornerRadius: .rounded)
        if isSelected {
            shape.strokeBorder(
                DesignSystem.Color.backgroundTintedInverse.color,
                lineWidth: NetworkGraphMetrics.groupBorderWidth
            )
        } else {
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
}
