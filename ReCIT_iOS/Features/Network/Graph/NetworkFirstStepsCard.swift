//
//  NetworkFirstStepsCard.swift
//  ReCIT_iOS
//
//  The two ways out of an empty network, under « Vous » in E1 (`602:18269`, the « premiers pas »
//  card): find reader friends, find a group. Two `Row / Link` rows in a white card with a
//  hairline border, as the Profil's bare action rows — the existing strings, no new ones (Q39).
//
//  Links rather than buttons: both push onto the Réseau tab's path, and the back button brings
//  the graph back.
//

import SwiftUI

struct NetworkFirstStepsCard: View {
    var body: some View {
        VStack(spacing: .zero) {
            NavigationLink(value: NavigationDestination.addFriends) {
                NetworkFirstStepRow(title: "network.add_friends")
            }
            .accessibilityIdentifier("e2e.network.empty.addFriends")

            Divider()
                .padding(.leading, .medium)

            NavigationLink(value: NavigationDestination.findGroups) {
                NetworkFirstStepRow(title: "groups.find")
            }
            .accessibilityIdentifier("e2e.network.empty.findGroups")
        }
        .buttonStyle(.plain)
        .background(.backgroundDefault)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .strokeBorder(DesignSystem.Color.borderDefault.color, lineWidth: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        NetworkFirstStepsCard()
            .padding()
    }
}
