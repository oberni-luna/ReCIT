package studio.lunabee.nouveaurecit.ui.editedition

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Image
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius as GeometryCornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.creation.ClaimLiteral
import studio.lunabee.nouveaurecit.data.creation.EditionFormat
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.PublicationDate
import studio.lunabee.nouveaurecit.data.creation.WorkEdit
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.WithLabel
import java.io.File
import java.util.UUID

/*
 * The sections of the edition's form (iOS feature 0050), in the order « Modifier l'édition » shows them.
 * Each takes the values it draws and callbacks — never a view model — so the scanner's « Nouvelle
 * édition » (issue 0145) lays out the same sections over its own draft.
 */

/**
 * `EditionWorksSection`: the works the edition is an edition of, then « Ajouter une œuvre ». Touching a
 * work opens « Modifier l'œuvre », the only place its title and authors change; swiping it to the left
 * detaches it from the edition. The work itself stays on inventaire.io.
 */
@Composable
fun EditionWorksSection(
    works: List<WorkEdit>,
    onOpen: (UUID) -> Unit,
    onDetach: (UUID) -> Unit,
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val footer: Int = when (EditionFormRules.worksFooter(works)) {
        EditionFormRules.WorksFooter.Empty -> R.string.edit_edition_works_empty_help
        EditionFormRules.WorksFooter.NewWorkNeedsAuthor -> R.string.edit_edition_works_new_help
        EditionFormRules.WorksFooter.Default -> R.string.edit_edition_works_help
    }
    FormSection(header = stringResource(R.string.create_book_edition_of), footer = stringResource(footer), modifier = modifier) {
        val detach: String = stringResource(R.string.edit_edition_works_detach)
        works.forEach { work ->
            key(work.id) {
                SwipeToRemoveRow(label = detach, onRemove = { onDetach(work.id) }) {
                    WorkRow(work = work.candidate, onClick = { onOpen(work.id) })
                }
                FormDivider()
            }
        }
        FormActionRow(title = stringResource(R.string.edit_edition_works_add), onClick = onAdd)
    }
}

/**
 * `CreateBookCoverRow` in its section: the cover — a menu of where a picture can come from, and once one
 * is set, taking it away first — and the ISBN, shown and never edited. [coverPath] is a local picture,
 * [coverUrl] the one the server holds; [onCover] is handed a new picture's path, or `null` to remove it.
 */
@Composable
fun EditionCoverSection(
    isbn: String,
    isbnLabel: String,
    isbn10: String?,
    coverPath: String?,
    coverUrl: String?,
    onCover: (String?) -> Unit,
    modifier: Modifier = Modifier,
    footer: String? = stringResource(R.string.edit_edition_cover_footer),
) {
    FormSection(header = stringResource(R.string.edit_edition_cover_header), footer = footer, modifier = modifier) {
        Row(
            modifier = Modifier.padding(Spacing.medium),
            horizontalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            CoverFrame(coverPath = coverPath, coverUrl = coverUrl, onCover = onCover)
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                // Nothing at all without an ISBN: a label over an empty line reads as a field left blank.
                if (isbn.isNotEmpty()) {
                    WithLabel(label = isbnLabel) {
                        Text(isbn, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
                    }
                }
                if (!isbn10.isNullOrEmpty()) {
                    WithLabel(label = stringResource(R.string.edit_edition_isbn10)) {
                        Text(isbn10, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault)
                    }
                }
            }
        }
    }
}

/** The frame and its menu: the picture, or a dashed frame inviting one — dashed because the book needs none. */
@Composable
private fun CoverFrame(coverPath: String?, coverUrl: String?, onCover: (String?) -> Unit) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    val sources: CoverSources = rememberCoverSources(onCover = onCover)
    val hasCover: Boolean = coverPath != null || coverUrl != null
    val dash: Color = RecitTheme.colors.borderDefault
    val label: String = stringResource(if (hasCover) R.string.create_book_cover_change else R.string.create_book_cover_add)
    Box {
        Box(
            modifier = Modifier
                .size(width = CoverWidth, height = CoverHeight)
                .clip(RoundedCornerShape(CornerRadius.medium))
                .background(RecitTheme.colors.backgroundSecondary)
                .drawBehind {
                    if (!hasCover) {
                        drawRoundRect(
                            color = dash,
                            cornerRadius = GeometryCornerRadius(CornerRadius.medium.toPx()),
                            style = Stroke(width = 1.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(4.dp.toPx(), 4.dp.toPx()))),
                        )
                    }
                }
                .clickable(onClickLabel = label, role = Role.Button) { expanded = true },
            contentAlignment = Alignment.Center,
        ) {
            val model: Any? = coverPath?.let(::File) ?: coverUrl
            if (model != null) {
                AsyncImage(model = model, contentDescription = label, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
            } else {
                Column(
                    modifier = Modifier.padding(Spacing.small),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(Spacing.small),
                ) {
                    Icon(Icons.Outlined.Image, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
                    Text(label, style = RecitTheme.typography.caption200, color = RecitTheme.colors.foregroundSecondary, textAlign = TextAlign.Center)
                }
            }
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }, containerColor = RecitTheme.colors.backgroundRaised) {
            if (hasCover) {
                MenuLine(stringResource(R.string.create_book_cover_remove), Icons.Outlined.Delete, RecitTheme.colors.foregroundError) {
                    expanded = false
                    onCover(null)
                }
                HorizontalDivider(color = RecitTheme.colors.borderDefault)
                Text(
                    text = stringResource(R.string.create_book_cover_replace),
                    style = RecitTheme.typography.footnote200,
                    color = RecitTheme.colors.foregroundSecondary,
                    modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
                )
            }
            MenuLine(stringResource(R.string.create_book_cover_camera), Icons.Outlined.PhotoCamera) {
                expanded = false
                sources.camera()
            }
            MenuLine(stringResource(R.string.create_book_cover_photos), Icons.Outlined.PhotoLibrary) {
                expanded = false
                sources.photos()
            }
        }
    }
}

@Composable
private fun MenuLine(text: String, icon: ImageVector, color: Color = RecitTheme.colors.foregroundDefault, onClick: () -> Unit) {
    DropdownMenuItem(
        text = { Text(text, style = RecitTheme.typography.content400, color = color) },
        leadingIcon = { Icon(icon, contentDescription = null, tint = color) },
        onClick = onClick,
    )
}

/** « Titre »: the edition's title, required, and its subtitle. */
@Composable
fun EditionTitleSection(
    title: String,
    subtitle: String,
    onTitle: (String) -> Unit,
    onSubtitle: (String) -> Unit,
    modifier: Modifier = Modifier,
    footer: String? = null,
) {
    FormSection(header = stringResource(R.string.edit_edition_title_header), footer = footer, modifier = modifier) {
        val sentences = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences)
        FormTextRow(label = stringResource(R.string.create_book_title_field), value = title, onValueChange = onTitle, keyboardOptions = sentences)
        FormDivider()
        FormTextRow(
            label = stringResource(R.string.edit_edition_subtitle_field),
            value = subtitle,
            onValueChange = onSubtitle,
            singleLine = false,
            keyboardOptions = sentences,
        )
    }
}

/**
 * `EditionPublicationSection`: the publisher, the collection, the date and the language. Each row pushes
 * its own page — a search for an entity, or the date's precision — which the caller decides.
 */
@Composable
fun EditionPublicationSection(properties: EditionProperties, onOpen: (EditionProperty) -> Unit, modifier: Modifier = Modifier) {
    FormSection(
        header = stringResource(R.string.edit_edition_publication_header),
        footer = stringResource(R.string.edit_edition_publication_footer),
        modifier = modifier,
    ) {
        EditionEntityPropertyRow(EditionProperty.Publisher, properties, stringResource(R.string.edition_property_publisher_placeholder), onOpen)
        FormDivider()
        EditionEntityPropertyRow(EditionProperty.Collection, properties, stringResource(R.string.edition_property_collection_placeholder), onOpen)
        FormDivider()
        val date: PublicationDate? = properties.literal(EditionProperty.PublicationDateProperty)?.string?.let(PublicationDate::parse)
        EditionPropertyRow(
            label = stringResource(EditionPropertyLabels.label(EditionProperty.PublicationDateProperty)),
            value = date?.displayed(),
            placeholder = stringResource(R.string.edition_property_publication_date_placeholder),
            onClick = { onOpen(EditionProperty.PublicationDateProperty) },
        )
        FormDivider()
        EditionEntityPropertyRow(EditionProperty.Language, properties, stringResource(R.string.edition_property_language_placeholder), onOpen)
    }
}

/**
 * `EditionFormatSection`: the format, chosen in a menu among the six inventaire.io allows, and the
 * numbers of pages and volumes, typed. A count goes out as a number; an empty field takes the claim away.
 */
@Composable
fun EditionFormatSection(properties: EditionProperties, onChange: (EditionProperties) -> Unit, modifier: Modifier = Modifier) {
    FormSection(
        header = stringResource(R.string.edit_edition_format_header),
        footer = stringResource(R.string.edit_edition_format_footer),
        modifier = modifier,
    ) {
        EditionFormatMenu(properties = properties, onChange = onChange)
        FormDivider()
        EditionCountRow(EditionProperty.NumberOfPages, properties, onChange)
        FormDivider()
        EditionCountRow(EditionProperty.NumberOfVolumes, properties, onChange)
    }
}

@Composable
private fun EditionFormatMenu(properties: EditionProperties, onChange: (EditionProperties) -> Unit) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    val format: EditionFormat? = EditionFormat.from(properties.literal(EditionProperty.Format)?.string)
    val choose: (EditionFormat?) -> Unit = { chosen ->
        expanded = false
        onChange(properties.setLiteral(chosen?.let { ClaimLiteral.Text(it.uri) }, EditionProperty.Format))
    }
    Box {
        EditionPropertyRow(
            label = stringResource(EditionPropertyLabels.label(EditionProperty.Format)),
            value = format?.let { stringResource(EditionPropertyLabels.name(it)) },
            placeholder = stringResource(R.string.edition_property_format_placeholder),
            trailing = PropertyRowTrailing.Menu,
            onClick = { expanded = true },
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }, containerColor = RecitTheme.colors.backgroundRaised) {
            EditionFormat.entries.forEach { option ->
                FormatLine(stringResource(EditionPropertyLabels.name(option)), isSelected = option == format) { choose(option) }
            }
            FormatLine(stringResource(R.string.edition_format_none), isSelected = format == null) { choose(null) }
        }
    }
}

@Composable
private fun FormatLine(text: String, isSelected: Boolean, onClick: () -> Unit) {
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

/** A positive count, typed. Anything but digits is dropped as it is typed. */
@Composable
private fun EditionCountRow(property: EditionProperty, properties: EditionProperties, onChange: (EditionProperties) -> Unit) {
    FormTextRow(
        label = stringResource(EditionPropertyLabels.label(property)),
        value = properties.literal(property)?.text.orEmpty(),
        onValueChange = { typed -> onChange(properties.setLiteral(EditionFormRules.countLiteral(property, typed), property)) },
        placeholder = stringResource(R.string.edition_property_count_placeholder),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
    )
}

/**
 * `EditionContributorsSection`: the people this edition credits besides the work's authors — translation,
 * illustrations, cover, preface, afterword, editorial direction. Each role can name several.
 */
@Composable
fun EditionContributorsSection(properties: EditionProperties, onOpen: (EditionProperty) -> Unit, modifier: Modifier = Modifier) {
    FormSection(
        header = stringResource(R.string.edit_edition_contributors_header),
        footer = stringResource(R.string.edit_edition_contributors_footer),
        modifier = modifier,
    ) {
        val placeholder: String = stringResource(R.string.edition_property_person_placeholder)
        EditionProperty.contributors.forEachIndexed { index, property ->
            if (index > 0) FormDivider()
            EditionEntityPropertyRow(property, properties, placeholder, onOpen)
        }
    }
}

/**
 * `EditionIdentifiersSection`: the identifiers of the edition in library catalogues
 * ([EditionProperty.Group.Databases]), or its links ([EditionProperty.Group.Links]). Each value is a
 * row, taken away with a swipe; the last row adds one, through the catalogue and a field checked against
 * the server's pattern.
 */
@Composable
fun EditionIdentifiersSection(
    group: EditionProperty.Group,
    properties: EditionProperties,
    onChange: (EditionProperties) -> Unit,
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val isDatabases: Boolean = group == EditionProperty.Group.Databases
    FormSection(
        header = stringResource(if (isDatabases) R.string.edit_edition_databases_header else R.string.edit_edition_links_header),
        footer = stringResource(if (isDatabases) R.string.edit_edition_databases_footer else R.string.edit_edition_links_footer),
        modifier = modifier,
    ) {
        val remove: String = stringResource(R.string.edit_edition_remove)
        EditionFormRules.identifierEntries(group, properties).forEach { entry ->
            key(entry.property.uri, entry.value.text) {
                SwipeToRemoveRow(label = remove, onRemove = { onChange(EditionFormRules.removing(entry, properties)) }) {
                    EditionPropertyRow(
                        label = stringResource(EditionPropertyLabels.label(entry.property)),
                        value = entry.value.text,
                        placeholder = "",
                        trailing = PropertyRowTrailing.None,
                    )
                }
                FormDivider()
            }
        }
        FormActionRow(
            title = stringResource(if (isDatabases) R.string.edit_edition_databases_add else R.string.edit_edition_links_add),
            onClick = onAdd,
        )
    }
}

/** `EditionEntityPropertyButton`: a property whose values are entities, their names joined, or an invitation. */
@Composable
fun EditionEntityPropertyRow(
    property: EditionProperty,
    properties: EditionProperties,
    placeholder: String,
    onOpen: (EditionProperty) -> Unit,
) {
    val names: List<String> = properties.entities(property).map { it.trimmedLabel }
    EditionPropertyRow(
        label = stringResource(EditionPropertyLabels.label(property)),
        value = names.takeIf { it.isNotEmpty() }?.let { EditionFormRules.joinedNames(it, stringResource(R.string.edition_property_names_and)) },
        placeholder = placeholder,
        onClick = { onOpen(property) },
    )
}

/** The cover frame: a book's 2:3, large enough to recognise the jacket. */
private val CoverWidth: Dp = 88.dp
private val CoverHeight: Dp = 132.dp
