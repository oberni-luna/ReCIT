//
//  File.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 12/03/2026.
//

import Foundation
import SwiftUI

extension Shape where Self == RoundedRectangle {

    public static func rect(cornerRadius: DesignSystem.CornerRadius) -> Self {
        .rect(cornerRadius: CGFloat(cornerRadius.rawValue))
    }

}

