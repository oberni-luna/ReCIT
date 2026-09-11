//
//  ContainerCreationSheet.swift
//  ReCIT_iOS
//
//  The one place where an « Ajouter à une nouvelle … » line becomes a form.
//
//  Mounted by the screen carrying the membership menu rather than by the menu itself: a
//  `.sheet` placed inside a `Menu`'s content does not present reliably. The menu writes a
//  `ContainerCreationRequest` into the binding, this reads it and opens the matching form —
//  so every carrier screen is one line, and the sheet is defined once. See PRD 0014.
//

import SwiftUI

extension View {

    /// Opens the creation form asked for by `request`. The binding is cleared by the sheet
    /// itself when it goes, so a second demand presents again.
    func containerCreationSheet(_ request: Binding<ContainerCreationRequest?>) -> some View {
        modifier(ContainerCreationSheet(request: request))
    }
}

struct ContainerCreationSheet: ViewModifier {

    @Binding var request: ContainerCreationRequest?

    func body(content: Content) -> some View {
        content
            .sheet(item: $request) { request in
                switch request {
                case .list(let workUri):
                    ListFormView(fileWorkIntoNewList: workUri)
                case .shelf:
                    // The étagère half is issue 0084: nothing writes `.shelf` yet, so this
                    // case is unreachable rather than deliberately empty. It mounts the
                    // étagère form there, and no other file has to change.
                    EmptyView()
                }
            }
    }
}
