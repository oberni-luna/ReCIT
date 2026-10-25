//
//  EditionPropertyDestination.swift
//  ReCIT_iOS
//
//  The screen an `EditionPropertyStep` pushes, writing into the form's properties. The flow that
//  shows it hands it a way to push the next step and a way back to the form: the stacks belong
//  to the flows.
//

import SwiftUI

struct EditionPropertyDestination: View {
    let step: EditionPropertyStep
    @Binding var properties: EditionProperties
    let push: (EditionPropertyStep) -> Void
    /// Pops `count` screens: back past the catalogue, to the form.
    let pop: (Int) -> Void

    var body: some View {
        switch step {
        case .values(let uri):
            if let property = EditionProperty.named(uri) {
                EditionEntityValuesView(property: property, properties: $properties) {
                    push(.picker(property: uri))
                }
            }
        case .picker(let uri):
            if let property = EditionProperty.named(uri) {
                // Pops itself once an entity is picked or created.
                EntityPickerView(
                    property: property,
                    hasPublisher: properties.entities(of: .publisher).isEmpty == false
                ) { entity in
                    properties.add(entity, to: property)
                }
            }
        case .publicationDate:
            PublicationDateView(properties: $properties)
        case .identifierCatalog(let group):
            IdentifierCatalogView(group: group) { property in
                push(.identifierInput(property: property.uri))
            }
        case .identifierInput(let uri):
            if let property = EditionProperty.named(uri) {
                IdentifierInputView(property: property) { literal in
                    properties.addLiteral(literal, to: property)
                    pop(2)
                }
            }
        }
    }
}
