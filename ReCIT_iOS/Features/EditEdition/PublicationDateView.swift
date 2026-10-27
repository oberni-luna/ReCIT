//
//  PublicationDateView.swift
//  ReCIT_iOS
//
//  The edition's publication date, as precise as the book: a year, a month, or a day. Pushed by
//  the « Date de publication » row. What is set is written into the form as it changes; opening
//  the screen and leaving it adds nothing.
//

import SwiftUI

struct PublicationDateView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var properties: EditionProperties

    @State private var date: PublicationDate

    init(properties: Binding<EditionProperties>) {
        _properties = properties
        let current: PublicationDate? = properties.wrappedValue.literal(of: .publicationDate)?.string.flatMap(PublicationDate.init)
        let thisYear: Int = Calendar(identifier: .gregorian).component(.year, from: .now)
        _date = State(initialValue: current ?? .init(year: thisYear, precision: .year))
    }

    private var hasDate: Bool {
        properties.literal(of: .publicationDate) != nil
    }

    var body: some View {
        DesignSystem.Form {
            Section {
                Picker("edit_edition.date.precision", selection: $date.precision) {
                    Text("edit_edition.date.year").tag(PublicationDate.Precision.year)
                    Text("edit_edition.date.month").tag(PublicationDate.Precision.month)
                    Text("edit_edition.date.day").tag(PublicationDate.Precision.day)
                }
                .pickerStyle(.segmented)
            } footer: {
                CreateBookSectionFooter("edit_edition.date.footer")
            }

            Section {
                switch date.precision {
                case .year:
                    PublicationYearField(year: $date.year)
                case .month:
                    Picker("edit_edition.date.month", selection: $date.month) {
                        ForEach(1...12, id: \.self) { month in
                            Text(Calendar.current.standaloneMonthSymbols[month - 1].capitalized).tag(month)
                        }
                    }
                    PublicationYearField(year: $date.year)
                case .day:
                    DatePicker(
                        "edit_edition.date.day",
                        selection: Binding(get: { date.date }, set: { date.set($0) }),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                }
            }

            if hasDate {
                Section {
                    Button("edit_edition.date.remove", role: .destructive) {
                        properties.setLiteral(nil, for: .publicationDate)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(String(localized: String.LocalizationValue(EditionProperty.publicationDate.label)))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: date) { _, newValue in
            properties.setLiteral(.string(newValue.claim), for: .publicationDate)
        }
    }
}

/// The year, typed.
private struct PublicationYearField: View {
    @Binding var year: Int

    var body: some View {
        TextField(
            "edit_edition.date.year",
            text: Binding(
                get: { String(year) },
                set: { text in
                    guard let typed = Int(text.filter(\.isNumber).prefix(4)), typed > 0 else { return }
                    year = typed
                }
            )
        )
        .keyboardType(.numberPad)
        .textStyle(.content300)
        .withLabel(label: "edit_edition.date.year")
    }
}
