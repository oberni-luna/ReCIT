package studio.lunabee.nouveaurecit.ui.editedition

import androidx.annotation.StringRes
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.runtime.key
import androidx.compose.ui.res.stringResource
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.EditionEntityValue
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EntityEdit
import studio.lunabee.nouveaurecit.data.creation.WorkProperties

/**
 * `EditWorkFormView` (iOS feature 0057): « Modifier l'œuvre » — everything inventaire.io accepts on a
 * work: its title per language, type, form, original language and first publication; its authors and
 * everyone else who made it; its series, genres and subjects, its relations with other works, its
 * identifiers, links, and the works it is not to be confused with.
 *
 * What changes here is the work's, for every edition of it, and goes with the page's own « Enregistrer ».
 */
fun LazyListScope.editWorkForm(edit: EntityEdit, actions: EntityFormActions) {
    val properties: EditionProperties = edit.properties
    item(key = "work") {
        FormSection(header = stringResource(R.string.edit_work_header), footer = stringResource(R.string.edit_work_general_footer)) {
            EntityLabelRows(
                edit = edit,
                fieldName = { stringResource(R.string.edit_work_title_field, it) },
                addTitle = stringResource(R.string.edit_work_add_title),
                actions = actions,
            )
            FormDivider()
            ChoiceMenuRow(WorkProperties.Type, properties, stringResource(R.string.edit_work_type_placeholder), actions.onChange)
            FormDivider()
            ChoicePageRow(WorkProperties.Form, properties, stringResource(R.string.edit_work_form_placeholder), actions.onOpenProperty)
            FormDivider()
            EditionEntityPropertyRow(
                WorkProperties.OriginalLanguage,
                properties,
                stringResource(R.string.edition_property_language_placeholder),
                actions.onOpenProperty,
            )
            FormDivider()
            EditionDateRow(WorkProperties.FirstPublicationDate, properties, actions.onOpenProperty)
        }
    }
    item(key = "authors") {
        FormSection(header = stringResource(R.string.edit_work_authors_header), footer = stringResource(R.string.edit_work_authors_footer)) {
            val authors: List<EditionEntityValue> = properties.entities(WorkProperties.Author)
            val remove: String = stringResource(R.string.edit_edition_remove)
            authors.forEachIndexed { index, author ->
                key(author.id) {
                    val uri: String? = author.uri?.takeIf(EntityEdit::canEdit)
                    SwipeToRemoveRow(label = remove, onRemove = { actions.onChange(properties.remove(setOf(index), WorkProperties.Author)) }) {
                        EntityValueRow(
                            label = author.trimmedLabel,
                            detail = author.detail,
                            isNew = author.uri == null,
                            onClick = uri?.let { { actions.onOpenEntity(it) } },
                        )
                    }
                    FormDivider()
                }
            }
            FormActionRow(
                title = stringResource(if (authors.isEmpty()) R.string.edit_edition_work_add_author else R.string.edit_work_add_other_author),
                onClick = { actions.onPick(WorkProperties.Author) },
            )
        }
    }
    item(key = "roles") {
        EntityPropertiesSection(
            WorkProperties.roles,
            properties,
            stringResource(R.string.edit_work_roles_header),
            stringResource(R.string.edit_work_roles_footer),
            actions.onOpenProperty,
        )
    }
    item(key = "comics") {
        EntityPropertiesSection(
            WorkProperties.comicRoles,
            properties,
            stringResource(R.string.edit_work_comics_header),
            stringResource(R.string.edit_work_comics_footer),
            actions.onOpenProperty,
        )
    }
    item(key = "series") {
        FormSection(header = stringResource(R.string.edit_work_series_header), footer = stringResource(R.string.edit_work_series_footer)) {
            EditionEntityPropertyRow(WorkProperties.Series, properties, stringResource(R.string.edit_work_series_placeholder), actions.onOpenProperty)
            FormDivider()
            OrdinalRow(WorkProperties.SeriesOrdinal, properties, stringResource(R.string.edit_work_series_ordinal_placeholder), actions.onChange)
        }
    }
    item(key = "subjects") {
        EntityPropertiesSection(
            listOf(WorkProperties.Genre, WorkProperties.MainSubject),
            properties,
            stringResource(R.string.edit_work_subjects_header),
            stringResource(R.string.edit_work_subjects_footer),
            actions.onOpenProperty,
        )
    }
    item(key = "relations") {
        EntityPropertiesSection(
            WorkProperties.relations,
            properties,
            stringResource(R.string.edit_work_relations_header),
            stringResource(R.string.edit_work_relations_footer),
            actions.onOpenProperty,
        )
    }
    entityIdentifierSections(edit, actions, databasesFooter = R.string.edit_work_databases_footer, linksFooter = R.string.edit_edition_links_footer)
    item(key = "misc") {
        EntityPropertiesSection(
            listOf(WorkProperties.DifferentFrom),
            properties,
            stringResource(R.string.edit_entity_misc_header),
            stringResource(R.string.edit_work_misc_footer),
            actions.onOpenProperty,
        )
    }
}

/** The identifiers and the links of a work or a person, each section saying which catalogues there are. */
internal fun LazyListScope.entityIdentifierSections(
    edit: EntityEdit,
    actions: EntityFormActions,
    @StringRes databasesFooter: Int,
    @StringRes linksFooter: Int,
) {
    for ((group, footer) in listOf(EditionProperty.Group.Databases to databasesFooter, EditionProperty.Group.Links to linksFooter)) {
        item(key = "identifiers:$group") {
            EditionIdentifiersSection(
                group = group,
                properties = edit.properties,
                onChange = actions.onChange,
                onAdd = { actions.onAddIdentifier(group) },
                footer = stringResource(footer),
            )
        }
    }
}
