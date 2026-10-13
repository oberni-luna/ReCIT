//
//  AppIconTile.swift
//  ReCIT_iOS
//
//  The app's icon, drawn as a tile: the cream gradient and the books-on-a-shelf illustration of
//  `Resources/AppIcon.icon`, at the same scale and lift. Where the app names itself beside
//  someone else — under the À propos screen, in the 50 / 50 of the donation sheet, facing
//  inventaire.io's logo — it shows the face people know it by on their home screen.
//
//  The icon itself cannot be read at runtime (an `.icon` bundle is not an image asset), hence
//  the illustration copied into `Assets.xcassets/images/BooksOnShelf` and the gradient restated
//  here. Both are the icon's own colours, held in both appearances like the icon is.
//

import SwiftUI

struct AppIconTile: View {
    let size: CGFloat

    /// The icon's fill, top to 70 % down — `icon.json`'s two stops.
    private let gradient: LinearGradient = .init(
        stops: [
            .init(color: .init(.displayP3, red: 0.998, green: 0.992, blue: 0.971), location: 0),
            .init(color: .init(red: 0.962, green: 0.936, blue: 0.781), location: 0.7)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    /// The illustration's share of the tile, and how far it rides up — `icon.json` again,
    /// whose 20,75 pt lift is on a 1024 pt canvas.
    private let artScale: CGFloat = 0.75
    private let artLift: CGFloat = 20.75 / 1024
    /// The continuous corner of a home-screen icon, as a share of its side.
    private let cornerShare: CGFloat = 0.2237

    var body: some View {
        Image(.booksOnShelf)
            .resizable()
            .scaledToFit()
            .frame(width: size * artScale, height: size * artScale)
            .offset(y: -size * artLift)
            .frame(width: size, height: size)
            .background(gradient)
            .clipShape(.rect(cornerRadius: size * cornerShare, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    AppIconTile(size: 64)
}
