//
//  CreateBookISBNField.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

import SwiftUI

/// The ISBN of a book created from Recherche, where no barcode was read: typed, or left empty.
///
/// A wrong check digit is said under the field once the reader has left it, or as soon as the
/// thirteen digits are in — not while a number is still being typed.
struct CreateBookISBNField: View {
    private static let isbn13Length: Int = 13

    /// Whether what is typed can be published: nothing, or an ISBN whose check digit is right.
    private let isValid: Bool

    @FocusState private var isFocused: Bool

    @Binding private var isbn: String

    init(
        _ isbn: Binding<String>,
        isValid: Bool
    ) {
        _isbn = isbn
        self.isValid = isValid
    }

    private var showsError: Bool {
        guard isValid == false else { return false }
        return isFocused == false || isbn.filter(\.isNumber).count >= Self.isbn13Length
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .xSmall) {
            TextField("create_book.isbn.placeholder", text: $isbn)
                .keyboardType(.numberPad)
                .autocorrectionDisabled()
                .focused($isFocused)
                .textStyle(.content300)
                .foregroundStyle(.foregroundDefault)
                .accessibilityIdentifier(AccessibilityID.field)
                .withLabel(label: "edit_edition.isbn")

            if showsError {
                Text("create_book.isbn.invalid")
                    .textStyle(.caption200)
                    .foregroundStyle(.foregroundError)
                    .accessibilityIdentifier(AccessibilityID.error)
            }
        }
    }
}

private extension CreateBookISBNField {
    enum AccessibilityID {
        static let field: String = "e2e.createBook.isbnField"
        static let error: String = "e2e.createBook.isbnError"
    }
}

#Preview("Vide") {
    @Previewable @State var isbn: String = ""

    DesignSystem.Form {
        CreateBookISBNField($isbn, isValid: true)
    }
}

#Preview("Clé fausse") {
    @Previewable @State var isbn: String = "9782070360025"

    DesignSystem.Form {
        CreateBookISBNField($isbn, isValid: false)
    }
}
