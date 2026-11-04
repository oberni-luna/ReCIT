package studio.lunabee.nouveaurecit.ui.editedition

import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EntityEdit
import studio.lunabee.nouveaurecit.data.creation.HumanProperties

/**
 * `EditAuthorFormView` (iOS feature 0057): « Modifier l'auteur·ice » — everything inventaire.io accepts
 * on a person: their name per language, pseudonyms, writing languages, dates of birth and death; their
 * movement and influences; their identifiers, links, and the namesakes they are not to be confused with.
 *
 * What changes here is the person's, for every work they are named on, and goes with the page's own
 * « Enregistrer ».
 */
fun LazyListScope.editAuthorForm(edit: EntityEdit, actions: EntityFormActions) {
    val properties: EditionProperties = edit.properties
    item(key = "author") {
        FormSection(header = stringResource(R.string.edit_author_header), footer = stringResource(R.string.edit_author_general_footer)) {
            EntityLabelRows(
                edit = edit,
                fieldName = { stringResource(R.string.edit_author_name_field, it) },
                addTitle = stringResource(R.string.edit_author_add_name),
                actions = actions,
            )
            FormDivider()
            TextValuesRows(HumanProperties.Pseudonym, properties, stringResource(R.string.edit_author_add_pseudonym), actions.onChange)
            FormDivider()
            EditionEntityPropertyRow(
                HumanProperties.WritingLanguages,
                properties,
                stringResource(R.string.edition_property_language_placeholder),
                actions.onOpenProperty,
            )
            FormDivider()
            EditionDateRow(HumanProperties.BirthDate, properties, actions.onOpenProperty)
            FormDivider()
            EditionDateRow(HumanProperties.DeathDate, properties, actions.onOpenProperty)
        }
    }
    item(key = "influences") {
        EntityPropertiesSection(
            listOf(HumanProperties.Movement, HumanProperties.InfluencedBy),
            properties,
            stringResource(R.string.edit_author_influences_header),
            stringResource(R.string.edit_author_influences_footer),
            actions.onOpenProperty,
        )
    }
    entityIdentifierSections(edit, actions, databasesFooter = R.string.edit_author_databases_footer, linksFooter = R.string.edit_author_links_footer)
    item(key = "misc") {
        EntityPropertiesSection(
            listOf(HumanProperties.DifferentFrom),
            properties,
            stringResource(R.string.edit_entity_misc_header),
            stringResource(R.string.edit_author_misc_footer),
            actions.onOpenProperty,
        )
    }
}
