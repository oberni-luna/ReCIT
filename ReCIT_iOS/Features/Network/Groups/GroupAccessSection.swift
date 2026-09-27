//
//  GroupAccessSection.swift
//  ReCIT_iOS
//
//  Who may come into a group — `Row / Toggle` ×2 in the Figma pass: whether any reader can find
//  it, and whether a request lets them in at once. Shared by the creation form and the settings.
//  The toggles take the primary button's green rather than the system's.
//

import SwiftUI

struct GroupAccessSection: View {
    @Binding var searchable: Bool
    @Binding var open: Bool

    var body: some View {
        Section {
            Toggle(isOn: $searchable) {
                label("groups.form.searchable", detail: "groups.form.searchable.detail")
            }
            .accessibilityIdentifier("e2e.groupForm.searchable")

            Toggle(isOn: $open) {
                label("groups.form.open", detail: open ? "groups.form.open.on" : "groups.form.open.off")
            }
            .accessibilityIdentifier("e2e.groupForm.open")
        } header: {
            Text("groups.form.access")
                .textStyle(.action200)
                .foregroundStyle(.foregroundSecondary)
        }
        .tint(.backgroundTintedInverse)
    }

    private func label(_ title: LocalizedStringKey, detail: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: .xxSmall) {
            Text(title)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
            Text(detail)
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
        }
    }
}
