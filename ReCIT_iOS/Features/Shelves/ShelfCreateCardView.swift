//
//  ShelfCreateCardView.swift
//  ReCIT_iOS
//
//  The trailing carousel card: an empty étagère (wash + plank) with a large + and a
//  label. Uses the same vertical metrics as ShelfRowView so its plank lines up with the
//  other shelves. Tapping it opens the create form. See ADR 0003 / 0004.
//

import SwiftUI

struct ShelfCreateCardView: View {
    let width: CGFloat
    let onTap: () -> Void

    private var plankHeight: CGFloat { width * 129.0 / 820.0 }
    private var zoneHeight: CGFloat { width * 9.0 / 16.0 }
    private var topRoom: CGFloat { zoneHeight * 0.25 }
    private let washBelow: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Image("ShelfWash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                    .offset(y: washBelow)
                    .opacity(0.92)
                    .allowsHitTesting(false)
                VStack(spacing: 0) {
                    Image(systemName: "plus")
                        .font(.system(size: zoneHeight * 0.42, weight: .light))
                        .foregroundStyle(.foregroundSecondary)
                        .frame(width: width, height: zoneHeight)
                    Image("ShelfPlank")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: width, height: zoneHeight + plankHeight)
            .padding(.top, topRoom)

            Text("Nouvelle étagère")
                .textStyle(.footnote200)
                .foregroundStyle(.foregroundSecondary)
                .lineLimit(1)
                .padding(.top, washBelow)
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
