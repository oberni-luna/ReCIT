//
//  NetworkGraphView.swift
//  ReCIT_iOS
//
//  « Tout » when there is someone or something around me: the constellation, framed on the whole
//  network with « Vous » in the middle (PRD 0019, Q33), pinched, dragged and touched.
//
//  **Measure, place, show.** Every node is laid out first, invisible, at its real size — real
//  text, the reader's text size up to the graph's cap (Q19, Q43). Once all are measured, their
//  boxes and the graph make a `NetworkGraphLayout`, whose placement is looked up in the cache or
//  computed off the main actor (Q45). Then the nodes appear in place: the graph opens already
//  laid out, with nothing flying in (Q23).
//
//  **When the network changes** — a friend arrives or leaves, a group changes — the new placement
//  is computed the same way and the nodes slide from their old places to the new ones; nothing
//  slides with Reduce Motion on (Q17).
//
//  **The camera** is a `GraphViewport`, kept here rather than recomputed with each placement, so
//  a sync keeps the zoom and the place the reader left (Q33). A pinch is anchored at the fingers,
//  a drag moves the network within its bounds, and both can run at once: what they do is applied
//  on top of the camera while the fingers are down, and kept when they lift.
//
//  **Touching** goes through the camera's hit test (Q36): a node lights itself, its neighbours and
//  its lines, and its summary rises in a native sheet with one detent measured to its content
//  (Q24, Q24b). The graph stays live behind it. Another node swaps the content; empty space, or
//  the sheet dragged down, closes it and clears the selection; « Vous » does nothing (Q28). When
//  the node touched sits under the sheet, the camera moves up just enough, zoom unchanged (Q30).
//  « Ouvrir le groupe » and « Voir le profil » close the sheet first, and open the page once it
//  is gone.
//
//  **Answering** (issue 0108): an invitation or a friend request touched is answered from its
//  sheet, by `onAnswer`. Accepted, the node stays, its dashed lines turn solid and the sheet stays
//  up on the new state; refused, the node fades out of the graph and the selection goes with it,
//  which closes the sheet — still showing, on its way down, the graph it was opened on, and no
//  longer answering touches.
//
//  **The text size is capped at `.xxxLarge`** on the graph alone (Q43): past it the boxes would
//  crowd any screen; the lists and VoiceOver carry the accessibility sizes. The sheet is attached
//  outside the cap and follows the reader's size.
//

import SwiftUI

struct NetworkGraphView: View {
    let graph: NetworkGraph
    /// Opens the page of a node — a group's, or a reader's profile — once the sheet is gone.
    var onOpen: (NetworkNodeID) -> Void = { _ in }
    /// Answers the invitation or the friend request a node stands for.
    var onAnswer: (NetworkNodeID, NetworkSheetAnswer) -> Void = { _, _ in }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Each node's size as last measured.
    @State private var sizes: [NetworkNodeID: CGSize] = [:]
    /// Where the nodes stand; `nil` until the first placement, which is shown without animation.
    @State private var placement: NetworkGraphPlacement?
    /// The room the graph has on screen.
    @State private var area: CGSize = .zero
    /// Where the bottom of the graph is in the window, to know how much of it the sheet covers.
    @State private var areaBottom: CGFloat = 0
    /// The camera as the last gesture left it; `nil` until the first placement.
    @State private var camera: GraphViewport?
    /// A drag that ended while a pinch went on, kept until the pinch ends too.
    @State private var heldTranslation: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero
    @GestureState private var pinch: NetworkGraphPinch?

    /// The node touched.
    @State private var selection: NetworkNodeID?
    /// The node the sheet speaks of: the selection, kept while the sheet closes so its content
    /// does not empty on the way down.
    @State private var sheetNode: NetworkNodeID?
    /// The sheet's content height, for its one detent.
    @State private var sheetHeight: CGFloat = 0
    /// Where the top of the sheet is in the window.
    @State private var sheetTop: CGFloat?
    /// The page to open once the sheet is gone.
    @State private var pendingOpen: NetworkNodeID?
    /// The graph as it was when the node of the sheet left it, so the sheet closes on its last
    /// content rather than on an empty one.
    @State private var closingGraph: NetworkGraph?

    private let cache: NetworkGraphLayoutCache = .shared

    var body: some View {
        let boxes: [NetworkNodeID: NetworkNodeBox] = boxes
        let layout: NetworkGraphLayout? = .init(graph: graph, boxes: boxes)
        let live: GraphViewport? = liveCamera
        let isReady: Bool = placement != nil && live != nil

        NetworkConstellationView(
            graph: graph,
            positions: .init(placement?.positions ?? [:]),
            scale: live?.scale ?? 1,
            centre: live?.origin ?? .init(x: area.width / 2, y: area.height / 2),
            placed: isReady ? Set(placement?.positions.keys.map(\.self) ?? []) : [],
            boxes: boxes,
            selection: selection,
            highlight: selection.flatMap(graph.highlight(for:)),
            onMeasure: { node, size in
                if sizes[node] != size {
                    sizes[node] = size
                }
            },
            onActivate: { node in
                select(node)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            areaBottom = frame.maxY
            if area != frame.size {
                area = frame.size
                updateCamera()
            }
        }
        // A card whose role changed, a node that left: faded rather than swapped (Q17).
        .animation(reduceMotion ? nil : .smooth(duration: NetworkGraphMetrics.transitionDuration), value: graph)
        .clipped()
        .dynamicTypeSize(...NetworkGraphMetrics.largestTextSize)
        .gesture(SimultaneousGesture(dragGesture, pinchGesture))
        // The location is the point of the graph touched, which the camera's hit test needs.
        .onTapGesture(coordinateSpace: .local) { location in
            touch(at: location)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("e2e.network.graph")
        .task(id: layout) {
            await place(layout)
        }
        .onChange(of: graph) { previous, current in
            if let selection, current.highlight(for: selection) == nil {
                closingGraph = previous
                self.selection = nil
            }
        }
        .onChange(of: pinch == nil) {
            // A pinch cancelled rather than ended: keep the drag it held.
            if pinch == nil, heldTranslation != .zero {
                camera = camera?.panning(by: heldTranslation)
                heldTranslation = .zero
            }
        }
        .onChange(of: selection) { previous, current in
            if previous == nil {
                // A sheet on its way up: where its top will be is not known yet.
                sheetTop = nil
            }
            if let current {
                sheetNode = current
            }
            revealSelection()
        }
        .onChange(of: sheetTop) {
            revealSelection()
        }
        .sheet(isPresented: isSheetPresented, onDismiss: openPending) {
            sheet
        }
    }

    // MARK: - The sheet

    private var isSheetPresented: Binding<Bool> {
        .init(
            get: { selection != nil },
            set: { isPresented in
                if isPresented == false {
                    selection = nil
                }
            }
        )
    }

    private var sheet: some View {
        Group {
            if let sheetNode {
                NetworkNodeSheet(
                    graph: selection == nil ? closingGraph ?? graph : graph,
                    node: sheetNode,
                    onOpen: { node in
                        pendingOpen = node
                        selection = nil
                    },
                    onAnswer: onAnswer
                )
                .allowsHitTesting(selection != nil)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            sheetHeight = frame.height
            // The sheet rises from below the tab bar: a frame whose bottom stops above the graph's
            // is one laid out on the way in or out — once dismissed, the content reports a frame
            // at the top of the window — and says nothing of what the sheet covers.
            guard selection != nil, frame.maxY >= areaBottom else { return }

            sheetTop = frame.minY
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(sheetHeight > 0 ? sheetHeight : NetworkGraphMetrics.sheetPlaceholderHeight)])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
    }

    private func openPending() {
        sheetTop = nil
        closingGraph = nil
        guard let pendingOpen else { return }

        self.pendingOpen = nil
        onOpen(pendingOpen)
    }

    // MARK: - Touching

    private func touch(at location: CGPoint) {
        guard let live = liveCamera else { return }

        switch live.node(at: location) {
        case .me:
            // Nothing happens when « Vous » is touched (Q28).
            return
        case .none:
            select(nil)
        case .some(let node):
            select(node)
        }
    }

    private func select(_ node: NetworkNodeID?) {
        guard node != selection else { return }

        withAnimation(reduceMotion ? nil : .smooth(duration: NetworkGraphMetrics.selectionDuration)) {
            selection = node
        }
    }

    /// Moves the camera up just enough for the node touched to clear the sheet (Q30).
    private func revealSelection() {
        guard let selection, let sheetTop, let camera else { return }

        let covered: CGFloat = areaBottom - sheetTop
        guard covered > 0 else { return }

        let next: GraphViewport = camera.revealing(selection, bottomInset: covered)
        guard next != camera else { return }

        withAnimation(reduceMotion ? nil : .smooth(duration: NetworkGraphMetrics.transitionDuration)) {
            self.camera = next
        }
    }

    // MARK: - The camera

    /// The camera with the gestures in flight applied on top of it.
    private var liveCamera: GraphViewport? {
        guard var live = camera else { return nil }

        if let pinch {
            live = live.pinching(by: pinch.magnification, at: pinch.anchor)
        }
        let translation: CGSize = .init(
            width: dragTranslation.width + heldTranslation.width,
            height: dragTranslation.height + heldTranslation.height
        )
        if translation != .zero {
            live = live.panning(by: translation)
        }
        return live
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                if pinch != nil {
                    heldTranslation.width += value.translation.width
                    heldTranslation.height += value.translation.height
                } else {
                    camera = camera?.panning(
                        by: .init(
                            width: heldTranslation.width + value.translation.width,
                            height: heldTranslation.height + value.translation.height
                        )
                    )
                    heldTranslation = .zero
                }
            }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .updating($pinch) { value, state, _ in
                state = .init(magnification: value.magnification, anchor: value.startLocation)
            }
            .onEnded { value in
                camera = camera?
                    .pinching(by: value.magnification, at: value.startLocation)
                    .panning(by: heldTranslation)
                heldTranslation = .zero
            }
    }

    /// The camera over the current placement and area: the opening frame the first time, then
    /// the same zoom and place, within the new bounds.
    private func updateCamera() {
        guard let placement, area.width > 0, area.height > 0 else { return }

        camera = camera?.updating(placement: placement, size: area) ?? .init(placement: placement, size: area)
    }

    // MARK: - Placing

    /// The box of every node measured so far, anchored where its lines meet: the centre of the
    /// avatar for « Vous » and the readers, the centre of the card for a group.
    private var boxes: [NetworkNodeID: NetworkNodeBox] {
        var boxes: [NetworkNodeID: NetworkNodeBox] = [:]
        for node in graph.nodes {
            guard let size = sizes[node] else { continue }

            switch node {
            case .me:
                boxes[node] = .init(
                    size: size,
                    anchor: .init(x: size.width / 2, y: NetworkGraphMetrics.meSide / 2)
                )
            case .reader:
                boxes[node] = .init(
                    size: size,
                    anchor: .init(x: size.width / 2, y: NetworkGraphMetrics.friendSide / 2)
                )
            case .group:
                boxes[node] = .init(centred: size)
            }
        }
        return boxes
    }

    /// Places the nodes of `layout` — at once the first time, sliding afterwards.
    private func place(_ layout: NetworkGraphLayout?) async {
        guard let layout else { return }

        let next: NetworkGraphPlacement = await cache.placementOffMainActor(for: layout)
        guard Task.isCancelled == false, next != placement else { return }

        if let animation = NetworkGraphMotion.animation(
            isFirstPlacement: placement == nil,
            reduceMotion: reduceMotion
        ) {
            withAnimation(animation) {
                placement = next
                updateCamera()
            }
        } else {
            var transaction: Transaction = .init()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                placement = next
                updateCamera()
            }
        }
    }
}

#Preview {
    let strangers: [String] = (0..<8).map { "stranger-\($0)" }
    NetworkGraphView(
        graph: .init(
            .init(
                me: .init(id: "me", username: "olivier_berni"),
                friends: ["Inès", "Léa", "Rémi", "Camille", "Hugo", "Sami", "Nora", "Paul"].map {
                    .init(id: $0, username: $0)
                },
                requesters: [.init(id: "Ariane", username: "Ariane")],
                groups: [
                    .init(
                        id: "club",
                        name: "Club de Belleville",
                        role: .admin,
                        memberIds: ["me", "Inès", "Léa", "Rémi", "Camille"] + strangers,
                        pendingCount: 2
                    ),
                    .init(
                        id: "bd",
                        name: "BD & romans graphiques",
                        role: .member,
                        memberIds: ["me", "Rémi", "Hugo", "Sami"] + strangers
                    ),
                    .init(
                        id: "l11",
                        name: "Lecteurs du 11e",
                        role: .invited,
                        memberIds: ["Camille", "Nora"] + strangers,
                        invitorUsername: "Camille"
                    )
                ]
            )
        )
    )
    .background(.backgroundDefault)
}
