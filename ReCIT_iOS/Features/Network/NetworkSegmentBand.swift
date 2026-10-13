//
//  NetworkSegmentBand.swift
//  ReCIT_iOS
//
//  The segmented control of the Réseau tab, in a band of its own under the large title (PRD 0019,
//  Q13, Q14) — `Chrome / Segmented Control · 3` in Figma, which is a stand-in for this native
//  picker: VoiceOver, Dynamic Type and Liquid Glass come with it.
//
//  It used to be the first row of the list, so the large title collapsed with the scroll. The
//  graph does not scroll, and a control that is a row of one segment and a bar of another jumps
//  when the segment changes; in a band fixed above all three, it stays where the finger left it.
//
//  The band is opaque, on the segment's own ground: the lists scroll under it, and a row showing
//  through the control would be read as part of it. **Its ground stops at its own top edge**: let
//  through the top safe area, it was drawn over the large title, and « Réseau » vanished from Amis
//  and Groupes. Above the band, the nav bar shows the ground of the segment itself, which runs
//  under it.
//

import SwiftUI

struct NetworkSegmentBand: View {
    @Binding var selection: NetworkSegment

    var body: some View {
        Picker("network.segment", selection: $selection) {
            ForEach(NetworkSegment.allCases, id: \.self) { segment in
                Text(segment.title)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .accessibilityIdentifier("e2e.network.segment")
        .padding(.horizontal, .medium)
        .padding(.vertical, .small)
        .background(selection.ground, ignoresSafeAreaEdges: .horizontal)
    }
}
