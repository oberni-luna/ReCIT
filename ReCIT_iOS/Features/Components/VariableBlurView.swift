//
//  VariableBlurView.swift
//  ReCIT_iOS
//
//  A backdrop blur whose radius falls off down the view: strongest at the top, gone at the
//  bottom. Used behind the shelf focus overlay's cell, so a title can sit over an arbitrary
//  page without an edge being drawn across the screen.
//
//  ## Why this exists at all
//
//  SwiftUI cannot express this. A material blurs its *live backdrop*, and every way of making
//  one fall off — `.mask`, `.opacity`, a gradient overlay — composites it into an offscreen
//  layer, where there is no backdrop left to sample; it silently degrades to a flat wash.
//  Stacking unmasked materials does blur progressively, but the largest one still has to end
//  somewhere, and it ends on a hard edge. `.scrollEdgeEffectStyle(.soft)` is a real
//  progressive blur but belongs to a scroll view's own edge, so it blurs scrolled content and
//  never the navigation bar sitting above it.
//
//  ## The cost, stated plainly
//
//  This reaches `CAFilter`, a **private QuartzCore class**, to install a `variableBlur` on the
//  visual effect view's backdrop layer. That is the only non-Metal way to get a real radius
//  ramp. Consequences worth weighing before shipping:
//
//  - It is private API. App Review may reject it, and a future OS may change or remove it.
//  - It is written here without the string-splitting that circulating versions of this recipe
//    use to hide the class name from static analysis. Hiding it would be worse than using it.
//  - Every failure path degrades to a plain `UIBlurEffect` rather than crashing, so the worst
//    case is a uniform blur instead of a graded one.
//
//  It is deliberately one self-contained file with no other callers, so removing it is a
//  single deletion plus one call site.
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

/// A blur that is strongest at the top edge and absent at the bottom.
struct VariableBlurView: UIViewRepresentable {
    /// The blur radius at the top edge, in points. It falls to nothing by the bottom edge, so
    /// the view's own height *is* the fade — give it the region you want blurred and nothing
    /// more.
    var maxRadius: CGFloat = 25

    func makeUIView(context: Context) -> VariableBlurUIView {
        .init(maxRadius: maxRadius)
    }

    func updateUIView(_ uiView: VariableBlurUIView, context: Context) {
        uiView.configure(maxRadius: maxRadius)
    }
}

/// The `UIVisualEffectView` doing the work. Its backdrop layer carries a `variableBlur`
/// filter masked by a vertical gradient, which is what turns a uniform blur into a ramp.
final class VariableBlurUIView: UIVisualEffectView {
    private var maxRadius: CGFloat
    /// The size the current gradient was built for, so it is only rebuilt when it must be.
    private var gradientSize: CGSize = .zero

    init(maxRadius: CGFloat) {
        self.maxRadius = maxRadius
        super.init(effect: UIBlurEffect(style: .regular))

        // The blur effect also paints a tint over the backdrop. That tint is what would read
        // as a grey wash, so every subview except the backdrop itself is hidden.
        for subview in subviews.dropFirst() {
            subview.alpha = 0
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("VariableBlurView is created in code only")
    }

    func configure(maxRadius: CGFloat) {
        guard maxRadius != self.maxRadius else { return }
        self.maxRadius = maxRadius
        gradientSize = .zero
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != gradientSize, bounds.height > 0, bounds.width > 0 else { return }
        gradientSize = bounds.size
        applyVariableBlur()
    }

    /// Installs the graded blur, or leaves the plain `UIBlurEffect` in place if any step of
    /// the private-API dance fails.
    private func applyVariableBlur() {
        guard let filterType = NSClassFromString("CAFilter") as? NSObject.Type else { return }
        guard
            let filter = filterType.perform(
                NSSelectorFromString("filterWithType:"),
                with: "variableBlur"
            )?.takeUnretainedValue() as? NSObject
        else { return }
        guard let mask = gradientMask(for: bounds.size) else { return }

        filter.setValue(maxRadius, forKey: "inputRadius")
        filter.setValue(mask, forKey: "inputMaskImage")
        // Without this the blur samples past the view's edges and the top few points read as
        // washed out rather than blurred.
        filter.setValue(true, forKey: "inputNormalizeEdges")

        // The first subview is the backdrop — the thing that actually samples what is behind.
        subviews.first?.layer.filters = [filter]
    }

    /// Black where the blur is full strength, clear where there is none. Core Image's origin
    /// is bottom-left, so the opaque end sits at `height`.
    ///
    /// Smooth rather than linear: a linear ramp holds a constant slope right up to the point
    /// it reaches zero, and the eye finds that terminus as a line. A smoothstep profile
    /// flattens as it approaches zero, so the fade has no discernible end.
    private func gradientMask(for size: CGSize) -> CGImage? {
        let gradient = CIFilter.smoothLinearGradient()
        gradient.color0 = .black
        gradient.color1 = .clear
        gradient.point0 = .init(x: 0, y: size.height)
        gradient.point1 = .init(x: 0, y: 0)

        guard let output = gradient.outputImage else { return nil }
        return CIContext().createCGImage(output, from: .init(origin: .zero, size: size))
    }
}
