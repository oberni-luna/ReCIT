//
//  KeyboardOKButton.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  The « OK » over the keyboard of a field that spans lines: its return key starts a new line, so
//  this is the way to say the text is done. Prominent, and held off the keyboard's top edge.
//
//  The bar's shared glass is put away from iOS 26: the button is glass of its own, and would
//  otherwise sit inside a second ring.
//

import SwiftUI

struct KeyboardOKButton: ToolbarContent {
    static let accessibilityID: String = "keyboard.ok"

    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some ToolbarContent {
        if #available(iOS 26.0, *) {
            item
                .sharedBackgroundVisibility(.hidden)
        } else {
            item
        }
    }

    private var item: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()

            Button("action.ok", action: action)
                .glassProminentButtonStyle()
                .accessibilityIdentifier(Self.accessibilityID)
                .padding(.all, .small)
        }
    }
}

#Preview {
    @Previewable @State var text: String = ""
    @Previewable @FocusState var isFocused: Bool

    List {
        TextField(
            "inventory.item.write_notes",
            text: $text,
            axis: .vertical
        )
        .focused($isFocused)
    }
    .toolbar {
        KeyboardOKButton {
            isFocused = false
        }
    }
}
