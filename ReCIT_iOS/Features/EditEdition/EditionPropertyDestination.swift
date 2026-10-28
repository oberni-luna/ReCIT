//
//  EditionPropertyDestination.swift
//  ReCIT_iOS
//
//  The screen an `EditionPropertyStep` pushes, writing into the form's properties. The flow that
//  shows it hands it a way to push the next step and a way back to the form: the stacks belong
//  to the flows. A uri is looked up in the catalogue of the properties written into: an
//  edition's, a work's or a person's.
//

import SwiftUI

struct EditionPropertyDestination: View {
    let step: EditionPropertyStep
    @Binding var properties: EditionProperties
    let push: (EditionPropertyStep) -> Void
    /// Pops `count` screens: back past the catalogue, to the form.
    let pop: (Int) -> Void
    /// Pushes « Modifier l'auteur·ice » for a person a list of values names. `nil` where no such
    /// screen can be pushed.
    var openEntity: ((String) -> Void)?

    private var catalogue: EditionProperty.Catalogue {
        properties.catalogue
    }

    var body: some View {
        switch step {
        case .values(let uri):
            if let property = catalogue.property(named: uri) {
                EditionEntityValuesView(
                    property: property,
                    properties: $properties,
                    onAdd: { push(.picker(property: uri)) },
                    onOpenEntity: openEntity
                )
            }
        case .picker(let uri):
            if let property = catalogue.property(named: uri) {
                // Pops itself once an entity is picked or created.
                EntityPickerView(
                    property: property,
                    hasPublisher: properties.entities(of: .publisher).isEmpty == false
                ) { entity in
                    properties.add(entity, to: property)
                }
            }
        case .date(let uri):
            if let property = catalogue.property(named: uri) {
                PublicationDateView(property: property, properties: $properties)
            }
        case .choice(let uri):
            if let property = catalogue.property(named: uri) {
                EditionChoiceListView(property: property, properties: $properties)
            }
        case .identifierCatalog(let group):
            IdentifierCatalogView(group: group, catalogue: catalogue) { property in
                push(.identifierInput(property: property.uri))
            }
        case .identifierInput(let uri):
            if let property = catalogue.property(named: uri) {
                IdentifierInputView(property: property) { literal in
                    properties.addLiteral(literal, to: property)
                    pop(2)
                }
            }
        }
    }
}
