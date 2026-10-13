//
//  NetworkNodeSheet.swift
//  ReCIT_iOS
//
//  What the sheet of the Réseau graph holds for the node touched (PRD 0019, Q24, Q26, Q27): a
//  group's summary and « Ouvrir le groupe », or a reader's and « Voir le profil ». Touching another
//  node swaps this content; the sheet itself stays up.
//
//  Laid out at its own height, which `NetworkGraphView` measures for the sheet's one detent
//  (Q24b). The system grabber sits over the top padding.
//

import SwiftUI

struct NetworkNodeSheet: View {
    let graph: NetworkGraph
    let node: NetworkNodeID
    /// Opens the page of `node` — the group's, or the reader's profile.
    let onOpen: (NetworkNodeID) -> Void

    var body: some View {
        Group {
            switch node {
            case .group(let id):
                if let group = graph.group(id: id) {
                    NetworkGroupSheet(summary: .init(group: group, in: graph)) {
                        onOpen(node)
                    }
                }
            case .reader(let id):
                if let reader = graph.reader(id: id) {
                    NetworkReaderSheet(summary: .init(reader: reader, in: graph)) {
                        onOpen(node)
                    }
                }
            case .me:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .medium)
        .padding(.top, .large)
        .padding(.bottom, .medium)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("e2e.network.graph.sheet")
    }
}
