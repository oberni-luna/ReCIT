//
//  BookHeaderTitle.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 22/11/2026.
//

import SwiftUI

/// The book's title in the Fiche livre's header: large and on as many lines as it takes at rest,
/// one small line once folded. The large title shrinks and fades out over the first half of the
/// fold, the small one fades in over the second, in a frame going from the one's height to the
/// other's.
struct BookHeaderTitle: View {
    private let title: String
    private let metrics: BookHeaderMetrics
    /// 0 at rest, 1 once folded.
    private let progress: CGFloat
    /// Told the large title's height, which the fold is measured from.
    private let onMeasure: (CGFloat) -> Void

    init(
        _ title: String,
        metrics: BookHeaderMetrics,
        progress: CGFloat,
        onMeasure: @escaping (CGFloat) -> Void
    ) {
        self.title = title
        self.metrics = metrics
        self.progress = progress
        self.onMeasure = onMeasure
    }

    var body: some View {
        ZStack(alignment: .top) {
            Text(title)
                .textStyle(.title200)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    onMeasure(height)
                }
                .scaleEffect(folding(metrics.titleScale), anchor: .top)
                .opacity(largeTitleOpacity)
                .accessibilityIdentifier(AccessibilityID.title)

            Text(title)
                .textStyle(.title50)
                .lineLimit(1)
                .opacity(smallTitleOpacity)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.foregroundDefault)
        .frame(maxWidth: .infinity)
        .frame(height: folding(metrics.titleFrameHeight), alignment: .top)
        .clipped()
        .accessibilityAddTraits(.isHeader)
        .allowsHitTesting(false)
    }

    /// Gone by halfway, before the small title shows: the two are never read together.
    private var largeTitleOpacity: CGFloat {
        max(1 - progress * 2, 0)
    }

    private var smallTitleOpacity: CGFloat {
        max(progress * 2 - 1, 0)
    }

    private func folding(_ values: (rest: CGFloat, folded: CGFloat)) -> CGFloat {
        FoldingHeaderCollapse.interpolate(from: values.rest, to: values.folded, progress: progress)
    }
}

private extension BookHeaderTitle {
    enum AccessibilityID {
        static let title: String = "e2e.entityTitle"
    }
}

#Preview {
    @Previewable @State var titleHeight: CGFloat = 0
    @Previewable @State var progress: CGFloat = 0

    VStack {
        BookHeaderTitle(
            "Le Comte de Monte-Cristo",
            metrics: .init(dynamicTypeSize: .large, titleHeight: titleHeight, bylineHeight: 0),
            progress: progress
        ) { titleHeight = $0 }
        .padding(.horizontal, .large)

        Slider(value: $progress)
    }
}
