//
//  ProfilePositionView.swift
//  ReCIT_iOS
//
//  Placing the account on the map (`A5` in the Figma file). The pin stays at the centre and the
//  map moves under it; a search moves the map to a place; « Valider » hands the centre to the
//  draft, rounded to about a kilometre by `ProfileDraft.place(at:)`, and « Retirer ma position »
//  hands it nothing. Nothing is sent from here: « Enregistrer » on the form does that.
//
//  No « Utiliser ma position actuelle »: it needs the location permission and its usage string,
//  which the app does not ask for yet.
//

import MapKit
import SwiftUI

struct ProfilePositionView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var draft: ProfileDraft

    @State private var camera: MapCameraPosition
    @State private var center: CLLocationCoordinate2D
    @State private var query: String = ""
    @State private var results: [MKMapItem] = []
    @State private var hasSearched: Bool = false

    /// Mainland France, when there is no position yet to open on.
    private static let fallbackCenter: CLLocationCoordinate2D = .init(latitude: 46.6, longitude: 2.4)

    init(draft: Binding<ProfileDraft>) {
        self._draft = draft
        let start: CLLocationCoordinate2D = draft.wrappedValue.position.map {
            .init(latitude: $0.latitude, longitude: $0.longitude)
        } ?? Self.fallbackCenter
        let span: Double = draft.wrappedValue.position == nil ? 8 : 0.06
        self._camera = .init(
            initialValue: .region(.init(center: start, span: .init(latitudeDelta: span, longitudeDelta: span)))
        )
        self._center = .init(initialValue: start)
    }

    var body: some View {
        DesignSystem.Form {
            Section {
                Map(position: $camera)
                    .onMapCameraChange(frequency: .onEnd) { context in
                        center = context.region.center
                    }
                    .overlay {
                        Image(systemName: "mappin")
                            .font(.title)
                            .foregroundStyle(DesignSystem.Color.backgroundTintedInverse.color)
                            // The pin's point, not its middle, is the centre of the map.
                            .offset(y: -14)
                            .allowsHitTesting(false)
                    }
                    .frame(height: 280)
                    .clipShape(.rect(cornerRadius: DesignSystem.CornerRadius.medium))
                    .listRowInsets(top: .sMedium, leading: .medium, bottom: .sMedium, trailing: .medium)
                    .accessibilityLabel(Text("profile_position.map"))
            } footer: {
                CreateBookSectionFooter("profile_position.map.footer")
            }

            Section {
                TextField("profile_position.search", text: $query)
                    .textStyle(.content300)
                    .submitLabel(.search)
                    .onSubmit { Task { await search() } }
                    .accessibilityIdentifier("e2e.profilePosition.search")

                ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                    Button {
                        move(to: item)
                    } label: {
                        Text(item.name ?? "")
                            .textStyle(.content300)
                            .foregroundStyle(.foregroundDefault)
                    }
                }

                if hasSearched, results.isEmpty {
                    Text("profile_position.search.empty")
                        .textStyle(.content300)
                        .foregroundStyle(.foregroundSecondary)
                }
            }

            if draft.position != nil {
                Section {
                    Button("profile_position.remove", role: .destructive) {
                        draft.place(at: nil)
                        dismiss()
                    }
                    .textStyle(.action300)
                    .foregroundStyle(.foregroundError)
                } footer: {
                    CreateBookSectionFooter("profile_position.remove.footer")
                }
            }
        }
        .navigationTitle("profile_position.title")
        .formActionBar {
            Button {
                draft.place(at: .init(latitude: center.latitude, longitude: center.longitude))
                dismiss()
            } label: {
                Text("profile_position.confirm")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary())
            .accessibilityIdentifier("e2e.profilePosition.confirm")
        }
    }

    private func search() async {
        let text: String = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }

        let request: MKLocalSearch.Request = .init()
        request.naturalLanguageQuery = text
        request.resultTypes = [.address, .pointOfInterest]

        let response: MKLocalSearch.Response? = try? await MKLocalSearch(request: request).start()
        results = Array((response?.mapItems ?? []).prefix(5))
        hasSearched = true
    }

    private func move(to item: MKMapItem) {
        let coordinate: CLLocationCoordinate2D = Self.coordinate(of: item)
        center = coordinate
        camera = .region(.init(center: coordinate, span: .init(latitudeDelta: 0.06, longitudeDelta: 0.06)))
        results = []
        hasSearched = false
    }

    private static func coordinate(of item: MKMapItem) -> CLLocationCoordinate2D {
        if #available(iOS 26.0, *) {
            item.location.coordinate
        } else {
            item.placemark.coordinate
        }
    }
}
