//
//  DesignSystem.swift
// DansMaPoche
//
//  Created by Olivier Berni on 29/10/2024.
//

import SwiftUI

public enum DesignSystem: Sendable {
    @MainActor
    public static func start() {
        setupFonts()
//        setupNavigationBar()
        setupAlertTintColor()
    }

    private static func setupFonts() {
        for font in TextStyle.CustomFont.allCases {
            guard let url = Bundle.main.url(forResource: font.registrationName, withExtension: font.fileExtension) else { break }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    @MainActor
    private static func setupNavigationBar() {
        let defaultAppearance: UINavigationBarAppearance = DesignSystem.getDefaultAppearance()

        let clearBackgroundAppearance: UINavigationBarAppearance = DesignSystem.getDefaultAppearance()
        clearBackgroundAppearance.backgroundEffect = nil

        UINavigationBar.appearance().standardAppearance = defaultAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = clearBackgroundAppearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = clearBackgroundAppearance
        UINavigationBar.appearance().compactAppearance = clearBackgroundAppearance
    }

    @MainActor
    private static func getDefaultAppearance() -> UINavigationBarAppearance {
        let appearance: UINavigationBarAppearance = .init()
        appearance.setBackIndicatorImage(UIImage(resource: .back), transitionMaskImage: UIImage(resource: .back))
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear] // Hide back button text

        // Apply color and font for normal and large titles
        appearance.titleTextAttributes = [.font: TextStyle.title50.uiFont, .foregroundColor: UIColor(Color.textDefault.color)]
        appearance.largeTitleTextAttributes = [.font: TextStyle.title200.uiFont, .foregroundColor: UIColor(Color.textDefault.color)]
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = .init(style: .systemMaterial)

        return appearance
    }

    @MainActor
    private static func setupAlertTintColor() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(Color.surfaceTintPrimary.color)
    }
}
