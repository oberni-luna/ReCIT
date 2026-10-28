//
//  ProfilePositionSection.swift
//  ReCIT_iOS
//
//  « Position » in « Modifier le profil »: where the account is, as a map that does not move
//  (`Form / Map Preview`), and the row that pushes the screen to place it. Without a position, a
//  sentence says what that costs instead of an empty map.
//

import MapKit
import SwiftUI

struct ProfilePositionSection: View {
    let position: Coordinates?
    let onEdit: () -> Void

    var body: some View {
        Section {
            if let position {
                ProfilePositionPreview(position: position)
                    .listRowInsets(top: .sMedium, leading: .medium, bottom: .sMedium, trailing: .medium)
            }

            Button(action: onEdit) {
                Label(
                    position == nil ? "edit_profile.position.add" : "edit_profile.position.edit",
                    systemImage: "mappin.and.ellipse"
                )
                .textStyle(.action300)
                .foregroundStyle(.foregroundTinted)
            }
            .accessibilityIdentifier("e2e.editProfile.position")
        } header: {
            CreateBookSectionHeader("edit_profile.position.header")
        } footer: {
            CreateBookSectionFooter(position == nil ? "edit_profile.position.none" : "edit_profile.position.footer")
        }
    }
}

/// The map itself, still: a marker on the position, a few kilometres around it.
private struct ProfilePositionPreview: View {
    let position: Coordinates

    private var coordinate: CLLocationCoordinate2D {
        .init(latitude: position.latitude, longitude: position.longitude)
    }

    var body: some View {
        Map(
            initialPosition: .region(
                .init(center: coordinate, span: .init(latitudeDelta: 0.06, longitudeDelta: 0.06))
            ),
            interactionModes: []
        ) {
            Marker("", coordinate: coordinate)
                .tint(DesignSystem.Color.backgroundTintedInverse.color)
        }
        // `initialPosition` is read once: a new position needs a new map.
        .id("\(position.latitude),\(position.longitude)")
        .frame(height: 164)
        .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
        .accessibilityHidden(true)
    }
}
