//
//  NetworkEdgesCanvas.swift
//  ReCIT_iOS
//
//  The lines of the Réseau graph, drawn in one `Canvas` under the nodes (PRD 0019, Q19, Q32,
//  Q32 bis): green to a group, from me or from a friend; a lighter green from me to each reader;
//  dashed for what waits on my answer — an invitation, a friend request.
//
//  One path per style, each stroked once: hundreds of lines cost three draws, and where two lines
//  of a style cross they do not darken each other.
//
//  The colours are the design system's dynamic ones, resolved by the canvas against its own
//  environment, so the lines follow the appearance (Q42). Hidden from VoiceOver: the nodes say
//  who is joined to whom (issue 0110).
//

import SwiftUI

struct NetworkEdgesCanvas: View {
    let segments: [NetworkEdgeSegment]

    var body: some View {
        let tinted: Color = DesignSystem.Color.foregroundTinted.color
        let segments: [NetworkEdgeSegment] = segments
        Canvas { context, _ in
            var toGroups: Path = .init()
            var toReaders: Path = .init()
            var dashed: Path = .init()
            for segment in segments {
                if segment.kind.isDashed {
                    dashed.move(to: segment.from)
                    dashed.addLine(to: segment.to)
                } else if segment.kind.joinsMeToReader {
                    toReaders.move(to: segment.from)
                    toReaders.addLine(to: segment.to)
                } else {
                    toGroups.move(to: segment.from)
                    toGroups.addLine(to: segment.to)
                }
            }
            context.stroke(
                toReaders,
                with: .color(tinted.opacity(NetworkGraphMetrics.meToReaderLineOpacity)),
                lineWidth: NetworkGraphMetrics.meToReaderLineWidth
            )
            context.stroke(
                toGroups,
                with: .color(tinted.opacity(NetworkGraphMetrics.groupLineOpacity)),
                lineWidth: NetworkGraphMetrics.groupLineWidth
            )
            context.stroke(
                dashed,
                with: .color(tinted),
                style: .init(
                    lineWidth: NetworkGraphMetrics.groupLineWidth,
                    dash: NetworkGraphMetrics.dash
                )
            )
        }
        .accessibilityHidden(true)
    }
}
