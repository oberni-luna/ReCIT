package studio.lunabee.nouveaurecit.ui.editedition

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.ClaimLiteral
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EditionPropertyChoice
import studio.lunabee.nouveaurecit.data.creation.EntityEdit
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import java.util.Locale

/*
 * The rows « Modifier l'œuvre » and « Modifier l'auteur·ice » have beyond the edition's (iOS feature
 * 0057): a label per language, a choice in a menu or on its own page, a rank typed, texts added one by
 * one, a section of properties whose values are entities.
 */

/**
 * `EntityLabelRows`: a work's title or a person's name, one field per language it has — [fieldName]
 * turns a language's name into the field's, « Titre · Français » —, then [addTitle], a menu of the
 * languages it has none in.
 */
@Composable
fun EntityLabelRows(edit: EntityEdit, fieldName: @Composable (String) -> String, addTitle: String, actions: EntityFormActions) {
    val locale: Locale = Locale.getDefault()
    edit.labels.forEach { label ->
        key(label.language) {
            FormTextRow(
                label = fieldName(EditionFormRules.languageName(label.language, locale)),
                value = label.value,
                onValueChange = { actions.onLabel(label.language, it) },
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
            )
            FormDivider()
        }
    }
    var expanded: Boolean by remember { mutableStateOf(false) }
    Box {
        FormActionRow(title = addTitle, onClick = { expanded = true }, enabled = edit.addableLanguages.isNotEmpty())
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }, containerColor = RecitTheme.colors.backgroundRaised) {
            edit.addableLanguages.forEach { language ->
                MenuChoice(EditionFormRules.languageName(language, locale), isSelected = false) {
                    expanded = false
                    actions.onAddLabel(language)
                }
            }
        }
    }
}

/** `EditionChoiceMenu`: a choice among a few — a work's type —, in a menu, « Non précisé » last. */
@Composable
fun ChoiceMenuRow(property: EditionProperty, properties: EditionProperties, placeholder: String, onChange: (EditionProperties) -> Unit) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    val selected: String? = properties.literal(property)?.string
    val choose: (String?) -> Unit = { uri ->
        expanded = false
        onChange(properties.setLiteral(uri?.let { ClaimLiteral.Text(it) }, property))
    }
    Box {
        EditionPropertyRow(
            label = stringResource(EditionPropertyLabels.label(property)),
            value = choiceName(property, properties),
            placeholder = placeholder,
            trailing = PropertyRowTrailing.Menu,
            onClick = { expanded = true },
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }, containerColor = RecitTheme.colors.backgroundRaised) {
            property.choices.forEach { choice ->
                MenuChoice(stringResource(EditionPropertyLabels.label(choice)), isSelected = choice.uri == selected) { choose(choice.uri) }
            }
            MenuChoice(stringResource(R.string.edition_choice_none), isSelected = selected == null) { choose(null) }
        }
    }
}

/** `EditionChoiceButton`: a choice among many — a work's form —, whose list is a page of its own. */
@Composable
fun ChoicePageRow(property: EditionProperty, properties: EditionProperties, placeholder: String, onOpen: (EditionProperty) -> Unit) {
    EditionPropertyRow(
        label = stringResource(EditionPropertyLabels.label(property)),
        value = choiceName(property, properties),
        placeholder = placeholder,
        onClick = { onOpen(property) },
    )
}

/** `EditionLiteralField`: a rank, typed. Anything but digits is dropped as it is typed; an empty field takes the claim away. */
@Composable
fun OrdinalRow(property: EditionProperty, properties: EditionProperties, placeholder: String, onChange: (EditionProperties) -> Unit) {
    FormTextRow(
        label = stringResource(EditionPropertyLabels.label(property)),
        value = properties.literal(property)?.text.orEmpty(),
        onValueChange = { typed -> onChange(properties.setLiteral(EditionFormRules.countLiteral(property, typed), property)) },
        placeholder = placeholder,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
    )
}

/**
 * `EditionTextValuesRows`: the texts a property holds — a person's pseudonyms —, each taken away with a
 * swipe, then a field that adds one when it is done with: on « OK », or when it loses the focus.
 */
@Composable
fun TextValuesRows(property: EditionProperty, properties: EditionProperties, addPlaceholder: String, onChange: (EditionProperties) -> Unit) {
    val remove: String = stringResource(R.string.edit_edition_remove)
    val name: String = stringResource(EditionPropertyLabels.label(property))
    properties.values(property).mapNotNull { it.claim }.forEachIndexed { index, value ->
        key(value.text) {
            SwipeToRemoveRow(label = remove, onRemove = { onChange(properties.remove(setOf(index), property)) }) {
                EditionPropertyRow(label = name, value = value.text, placeholder = "", trailing = PropertyRowTrailing.None)
            }
            FormDivider()
        }
    }
    var text: String by rememberSaveable { mutableStateOf("") }
    val add: () -> Unit = {
        property.literal(text)?.let { literal ->
            onChange(properties.addLiteral(literal, property))
            text = ""
        }
    }
    FormTextRow(
        label = name,
        value = text,
        onValueChange = { text = it },
        placeholder = addPlaceholder,
        modifier = Modifier.onFocusChanged { if (!it.isFocused) add() },
        keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words, imeAction = ImeAction.Done),
        keyboardActions = KeyboardActions(onDone = { add() }),
    )
}

/**
 * `EditEntityPropertiesSection`: a section of rows whose values are entities — a work's roles, its
 * relations, a person's influences —, each pushing its list of values, or the search when it names
 * nobody yet.
 */
@Composable
fun EntityPropertiesSection(
    properties: List<EditionProperty>,
    values: EditionProperties,
    header: String,
    footer: String,
    onOpen: (EditionProperty) -> Unit,
) {
    FormSection(header = header, footer = footer) {
        val placeholder: String = stringResource(R.string.edition_property_person_placeholder)
        properties.forEachIndexed { index, property ->
            if (index > 0) FormDivider()
            EditionEntityPropertyRow(property, values, placeholder, onOpen)
        }
    }
}

/** The name of the choice [property] holds; its uri for one the list does not hold. */
@Composable
private fun choiceName(property: EditionProperty, properties: EditionProperties): String? {
    val choice: EditionPropertyChoice? = EditionFormRules.choice(property, properties)
    return if (choice != null) stringResource(EditionPropertyLabels.label(choice)) else properties.literal(property)?.string
}

/** One line of a menu of choices: the one held in bold and tinted. */
@Composable
internal fun MenuChoice(text: String, isSelected: Boolean, onClick: () -> Unit) {
    DropdownMenuItem(
        text = {
            Text(
                text,
                style = if (isSelected) RecitTheme.typography.content400Bold else RecitTheme.typography.content400,
                color = if (isSelected) RecitTheme.colors.foregroundTinted else RecitTheme.colors.foregroundDefault,
            )
        },
        onClick = onClick,
    )
}
