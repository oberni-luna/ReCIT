//
//  KeyboardOKButton.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//
//  The shared, prominent « OK » over the keyboard of a field that spans lines: its return key
//  starts a new line, so this is the way to say the text is done.
//
//  No padding and no change to the bar's shared glass: on iOS 26 either one drops the keyboard's
//  item altogether, and the glass item already floats off the keyboard's top edge.
//

import SwiftUI

struct KeyboardOKButton: ToolbarContent {
    static let accessibilityID: String = "keyboard.ok"

    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()

            Button("action.ok", action: action)
                .glassProminentButtonStyle()
                .accessibilityIdentifier(Self.accessibilityID)
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
