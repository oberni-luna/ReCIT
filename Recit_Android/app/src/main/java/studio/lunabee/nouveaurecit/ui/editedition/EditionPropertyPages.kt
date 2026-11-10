package studio.lunabee.nouveaurecit.ui.editedition

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDefaults
import androidx.compose.material3.DatePickerState
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.TextLocale
import studio.lunabee.nouveaurecit.data.creation.ClaimLiteral
import studio.lunabee.nouveaurecit.data.creation.EditionEntityValue
import studio.lunabee.nouveaurecit.data.creation.EditionProperties
import studio.lunabee.nouveaurecit.data.creation.EditionProperty
import studio.lunabee.nouveaurecit.data.creation.EditionPropertyCatalogue
import studio.lunabee.nouveaurecit.data.creation.EntityEdit
import studio.lunabee.nouveaurecit.data.creation.EntitySearchHit
import studio.lunabee.nouveaurecit.data.creation.EntitySearchType
import studio.lunabee.nouveaurecit.data.creation.PublicationDate
import studio.lunabee.nouveaurecit.designsystem.DestructiveTextButton
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitSearchField
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import java.time.Instant
import java.time.LocalDate
import java.time.Month
import java.time.ZoneOffset
import java.time.format.TextStyle
import java.util.Locale

/*
 * The pages a property of the catalogue pushes over a form (`EditionPropertyDestination`): its values,
 * the search for one more, the date, the list of choices, the catalogue of identifiers and the field of
 * one. The same in « Modifier l'édition », the scanner's « Nouvelle édition », « Modifier l'œuvre » and
 * « Modifier l'auteur·ice »: they write into the properties they are handed — whose catalogue names the
 * step's property —, and push or close pages through the caller, whose stack it is.
 */

/**
 * The page an [EditionPropertyStep] shows. [entitySearch] is the picker's search, which the caller owns
 * so it survives a rotation; [onEntityQuery] types into it. [onOpenEntity], where given, opens « Modifier
 * l'auteur·ice » for a person a list of values names.
 */
@Composable
fun EditionPropertyPage(
    step: EditionPropertyStep,
    properties: EditionProperties,
    onChange: (EditionProperties) -> Unit,
    entitySearch: SearchState<EntitySearchHit>,
    onEntityQuery: (String) -> Unit,
    push: (EditionPropertyStep) -> Unit,
    pop: (count: Int) -> Unit,
    actions: @Composable RowScope.() -> Unit = {},
    onOpenEntity: ((String) -> Unit)? = null,
) {
    val catalogue: EditionPropertyCatalogue = properties.catalogue
    when (step) {
        is EditionPropertyStep.Values -> catalogue.property(step.propertyUri)?.let { property ->
            EntityValuesPage(
                property = property,
                properties = properties,
                onChange = onChange,
                onAdd = { push(EditionPropertyStep.Picker(property.uri)) },
                onBack = { pop(1) },
                onOpenEntity = onOpenEntity,
            )
        }
        is EditionPropertyStep.Picker -> catalogue.property(step.propertyUri)?.let { property ->
            EntityPickerPage(
                property = property,
                hasPublisher = properties.entities(EditionProperty.Publisher).isNotEmpty(),
                search = entitySearch,
                onQueryChange = onEntityQuery,
                onChoose = { entity ->
                    onChange(properties.add(entity, property))
                    pop(1)
                },
                onBack = { pop(1) },
                actions = actions,
            )
        }
        is EditionPropertyStep.Date -> catalogue.property(step.propertyUri)?.let { property ->
            DatePage(property = property, properties = properties, onChange = onChange, onBack = { pop(1) })
        }
        is EditionPropertyStep.Choice -> catalogue.property(step.propertyUri)?.let { property ->
            ChoiceListPage(property = property, properties = properties, onChange = onChange, onBack = { pop(1) })
        }
        is EditionPropertyStep.IdentifierCatalog -> IdentifierCatalogPage(
            group = step.group,
            catalogue = catalogue,
            onChoose = { push(EditionPropertyStep.IdentifierInput(it.uri)) },
            onBack = { pop(1) },
        )
        is EditionPropertyStep.IdentifierInput -> catalogue.property(step.propertyUri)?.let { property ->
            IdentifierInputPage(
                property = property,
                onAdd = { literal ->
                    onChange(properties.addLiteral(literal, property))
                    pop(EditionPropertyStep.PAGES_CLOSED_BY_IDENTIFIER)
                },
                onBack = { pop(1) },
            )
        }
    }
}

/**
 * A page pushed over a form: its bar, the grouped background, the keyboard kept clear of its content.
 * [navigationIcon], when given, replaces the back arrow — the root of a flow closes rather than goes back.
 */
@Composable
fun FormPageScaffold(
    title: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    actions: @Composable RowScope.() -> Unit = {},
    navigationIcon: (@Composable () -> Unit)? = null,
    bottomBar: @Composable () -> Unit = {},
    content: LazyListScope.() -> Unit,
) {
    Scaffold(
        modifier = modifier,
        topBar = {
            RecitTopBar(
                title = title,
                onBack = if (navigationIcon == null) onBack else null,
                actions = actions,
                navigationIcon = navigationIcon ?: {},
            )
        },
        bottomBar = bottomBar,
        containerColor = RecitTheme.colors.backgroundForm,
    ) { padding ->
        LazyColumn(
            modifier = Modifier.padding(padding).consumeWindowInsets(padding).fillMaxSize().imePadding(),
            contentPadding = PaddingValues(bottom = Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.xSmall),
            content = content,
        )
    }
}

/**
 * `EditionEntityValuesView`: the entities one property names — its publishers, its translators —
 * listed, taken away with a swipe, and added to through the search. A person inventaire.io has opens
 * « Modifier l'auteur·ice » through [onOpenEntity], where the caller can push it.
 */
@Composable
fun EntityValuesPage(
    property: EditionProperty,
    properties: EditionProperties,
    onChange: (EditionProperties) -> Unit,
    onAdd: () -> Unit,
    onBack: () -> Unit,
    onOpenEntity: ((String) -> Unit)? = null,
) {
    val remove: String = stringResource(R.string.edit_edition_remove)
    FormPageScaffold(title = stringResource(EditionPropertyLabels.label(property)), onBack = onBack) {
        item(key = "values") {
            FormSection(header = null, footer = stringResource(R.string.edit_edition_values_footer), modifier = Modifier.padding(top = Spacing.medium)) {
                properties.entities(property).forEachIndexed { index, entity ->
                    key(entity.id) {
                        val opensUri: String? = entity.uri?.takeIf { property.searchType == EntitySearchType.Humans && EntityEdit.canEdit(it) }
                        SwipeToRemoveRow(label = remove, onRemove = { onChange(properties.remove(setOf(index), property)) }) {
                            EntityValueRow(
                                label = entity.trimmedLabel,
                                detail = entity.detail,
                                isNew = entity.uri == null,
                                onClick = if (opensUri != null && onOpenEntity != null) ({ onOpenEntity(opensUri) }) else null,
                            )
                        }
                        FormDivider()
                    }
                }
                FormActionRow(title = stringResource(R.string.edit_edition_values_add), onClick = onAdd)
            }
        }
    }
}

/**
 * `EntityPickerView`: choosing an entity an edition names — a publisher, a collection, a language, a
 * person — existing ones first, creating one last. A language is only chosen, never created; a
 * collection is created under the edition's publisher, and without one the row says to choose it first.
 */
@Composable
fun EntityPickerPage(
    property: EditionProperty,
    hasPublisher: Boolean,
    search: SearchState<EntitySearchHit>,
    onQueryChange: (String) -> Unit,
    onChoose: (EditionEntityValue) -> Unit,
    onBack: () -> Unit,
    actions: @Composable RowScope.() -> Unit = {},
) {
    val query: String = search.trimmedQuery
    val offersCreation: Boolean = EditionFormRules.offersCreation(property, query)
    val canCreate: Boolean = EditionFormRules.canCreate(property, hasPublisher)
    EntitySearchPage(
        title = stringResource(EditionPropertyLabels.label(property)),
        placeholder = stringResource(R.string.entity_picker_prompt),
        search = search,
        onQueryChange = onQueryChange,
        existingHeader = stringResource(R.string.entity_picker_existing),
        existingFooter = if (property.allowsCreation) stringResource(R.string.entity_picker_why_existing) else null,
        createLabel = if (offersCreation) stringResource(R.string.entity_picker_create, query) else null,
        canCreate = canCreate,
        createFooter = when {
            !offersCreation -> null
            !canCreate -> stringResource(R.string.entity_picker_collection_needs_publisher)
            search.hasSearched && search.results.isEmpty() -> stringResource(R.string.entity_picker_no_result)
            else -> null
        },
        onChoose = { hit -> onChoose(EditionEntityValue(uri = hit.uri, label = hit.label, detail = hit.description)) },
        onCreate = { onChoose(EditionEntityValue(label = query)) },
        onBack = onBack,
        actions = actions,
    )
}

/**
 * The shape of every picker (`AuthorPickerView`, `EntityPickerView`): the field, open; the entries
 * inventaire.io has, each with what tells namesakes apart; « Créer » under them all — the duplicate is
 * the one damage a contributor of good faith does, so the existing answer is the easy one.
 */
@Composable
fun EntitySearchPage(
    title: String,
    placeholder: String,
    search: SearchState<EntitySearchHit>,
    onQueryChange: (String) -> Unit,
    existingHeader: String,
    existingFooter: String?,
    createLabel: String?,
    canCreate: Boolean,
    createFooter: String?,
    onChoose: (EntitySearchHit) -> Unit,
    onCreate: () -> Unit,
    onBack: () -> Unit,
    actions: @Composable RowScope.() -> Unit = {},
) {
    FormPageScaffold(title = title, onBack = onBack, actions = actions) {
        item(key = "field") { PickerSearchField(search.query, onQueryChange, placeholder) }
        if (search.results.isNotEmpty()) {
            item(key = "results") {
                FormSection(header = existingHeader, footer = existingFooter) {
                    search.results.forEachIndexed { index, hit ->
                        if (index > 0) FormDivider()
                        SearchHitRow(hit = hit, onClick = { onChoose(hit) })
                    }
                }
            }
        }
        if (createLabel != null) {
            item(key = "create") {
                FormSection(header = null, footer = createFooter, modifier = Modifier.padding(top = Spacing.medium)) {
                    FormActionRow(title = createLabel, onClick = onCreate, enabled = canCreate)
                }
            }
        }
    }
}

/** The picker's field, focused as the page opens: the reader came to type. */
@Composable
internal fun PickerSearchField(query: String, onQueryChange: (String) -> Unit, placeholder: String) {
    val focus: FocusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) { focus.requestFocus() }
    RecitSearchField(
        query = query,
        onQueryChange = onQueryChange,
        placeholder = placeholder,
        clearLabel = stringResource(R.string.action_close),
        autoCorrect = false,
        containerColor = RecitTheme.colors.backgroundFormCell,
        modifier = Modifier
            .padding(horizontal = Spacing.medium, vertical = Spacing.small)
            .focusRequester(focus),
    )
}

/** One candidate: the name, and what tells it apart. */
@Composable
private fun SearchHitRow(hit: EntitySearchHit, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        verticalArrangement = Arrangement.spacedBy(Spacing.xxSmall),
    ) {
        Text(text = hit.label, style = RecitTheme.typography.content400Bold, color = RecitTheme.colors.foregroundDefault)
        hit.description?.takeIf(String::isNotBlank)?.let { description ->
            Text(
                text = description,
                style = RecitTheme.typography.footnote200,
                color = RecitTheme.colors.foregroundSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

/**
 * `PublicationDateView`: the date [property] holds — an edition's publication, a work's first one, a
 * person's birth —, as precise as is known: a year, a month, or a day. What is set is written into the
 * form as it changes; opening the page and leaving it adds nothing.
 */
@Composable
fun DatePage(property: EditionProperty, properties: EditionProperties, onChange: (EditionProperties) -> Unit, onBack: () -> Unit) {
    val thisYear: Int = remember { LocalDate.now().year }
    var date: PublicationDate by rememberSaveable(stateSaver = PublicationDateSaver) {
        mutableStateOf(EditionFormRules.initialDate(property, properties, thisYear))
    }
    val update: (PublicationDate) -> Unit = { changed ->
        if (changed != date) {
            date = changed
            onChange(properties.setLiteral(ClaimLiteral.Text(changed.claim), property))
        }
    }
    val hasDate: Boolean = properties.literal(property) != null
    FormPageScaffold(title = stringResource(EditionPropertyLabels.label(property)), onBack = onBack) {
        item(key = "precision") {
            FormSection(header = stringResource(R.string.edit_edition_date_precision), footer = stringResource(R.string.edit_edition_date_footer)) {
                PrecisionPicker(precision = date.precision, onPrecision = { update(date.copy(precision = it)) })
            }
        }
        item(key = "value:${date.precision}") {
            FormSection(header = null, footer = null, modifier = Modifier.padding(top = Spacing.medium)) {
                when (date.precision) {
                    PublicationDate.Precision.Year -> YearRow(date, update)
                    PublicationDate.Precision.Month -> {
                        MonthRow(date, update)
                        FormDivider()
                        YearRow(date, update)
                    }
                    PublicationDate.Precision.Day -> DayPicker(date, thisYear, update)
                }
            }
        }
        if (hasDate) {
            item(key = "remove") {
                DestructiveTextButton(
                    text = stringResource(R.string.edit_edition_date_remove),
                    onClick = {
                        onChange(properties.setLiteral(null, property))
                        onBack()
                    },
                    modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.medium),
                )
            }
        }
    }
}

@Composable
private fun PrecisionPicker(precision: PublicationDate.Precision, onPrecision: (PublicationDate.Precision) -> Unit) {
    val labels: List<Int> = listOf(R.string.edit_edition_date_year, R.string.edit_edition_date_month, R.string.edit_edition_date_day)
    SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(Spacing.medium)) {
        PublicationDate.Precision.entries.forEachIndexed { index, option ->
            SegmentedButton(
                selected = option == precision,
                onClick = { onPrecision(option) },
                shape = SegmentedButtonDefaults.itemShape(index = index, count = PublicationDate.Precision.entries.size),
                colors = SegmentedButtonDefaults.colors(
                    activeContainerColor = RecitTheme.colors.backgroundTinted,
                    activeContentColor = RecitTheme.colors.foregroundTinted,
                    activeBorderColor = RecitTheme.colors.borderDefault,
                    // On the card, which already draws the cell's colour.
                    inactiveContainerColor = Color.Transparent,
                    inactiveContentColor = RecitTheme.colors.foregroundDefault,
                    inactiveBorderColor = RecitTheme.colors.borderDefault,
                ),
            ) {
                Text(stringResource(labels[index]), style = RecitTheme.typography.action300)
            }
        }
    }
}

/** The year, typed; the field may be emptied on the way to another year without the date losing its own. */
@Composable
private fun YearRow(date: PublicationDate, update: (PublicationDate) -> Unit) {
    var text: String by rememberSaveable { mutableStateOf(date.year.toString()) }
    FormTextRow(
        label = stringResource(R.string.edit_edition_date_year),
        value = text,
        onValueChange = { typed ->
            text = typed.filter(Char::isDigit).take(4)
            EditionFormRules.typedYear(typed)?.let { update(date.copy(year = it)) }
        },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
    )
}

@Composable
private fun MonthRow(date: PublicationDate, update: (PublicationDate) -> Unit) {
    var expanded: Boolean by remember { mutableStateOf(false) }
    val locale: Locale = TextLocale.current
    val name: (Int) -> String = { month ->
        Month.of(month).getDisplayName(TextStyle.FULL_STANDALONE, locale).replaceFirstChar { it.titlecase(locale) }
    }
    Box {
        EditionPropertyRow(
            label = stringResource(R.string.edit_edition_date_month),
            value = name(date.month),
            placeholder = "",
            trailing = PropertyRowTrailing.Menu,
            onClick = { expanded = true },
        )
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }, containerColor = RecitTheme.colors.backgroundRaised) {
            (1..12).forEach { month ->
                DropdownMenuItem(
                    text = { Text(name(month), style = RecitTheme.typography.content400, color = RecitTheme.colors.foregroundDefault) },
                    onClick = {
                        expanded = false
                        update(date.copy(month = month))
                    },
                )
            }
        }
    }
}

/** The calendar, for a date known to the day. Its days are UTC midnights, as Material's picker counts them. */
@Composable
private fun DayPicker(date: PublicationDate, thisYear: Int, update: (PublicationDate) -> Unit) {
    val day: LocalDate = date.toLocalDate() ?: LocalDate.of(date.year, 1, 1)
    val state: DatePickerState = rememberDatePickerState(
        initialSelectedDateMillis = day.atStartOfDay(ZoneOffset.UTC).toInstant().toEpochMilli(),
        yearRange = minOf(EarliestYear, date.year)..maxOf(thisYear + 1, date.year),
    )
    LaunchedEffect(state.selectedDateMillis) {
        val millis: Long = state.selectedDateMillis ?: return@LaunchedEffect
        update(date.with(Instant.ofEpochMilli(millis).atZone(ZoneOffset.UTC).toLocalDate()))
    }
    DatePicker(
        state = state,
        title = null,
        headline = null,
        showModeToggle = false,
        colors = DatePickerDefaults.colors(
            containerColor = Color.Transparent,
            selectedDayContainerColor = RecitTheme.colors.backgroundTintedInverse,
            selectedDayContentColor = RecitTheme.colors.foregroundTintedInverse,
            selectedYearContainerColor = RecitTheme.colors.backgroundTintedInverse,
            selectedYearContentColor = RecitTheme.colors.foregroundTintedInverse,
            todayDateBorderColor = RecitTheme.colors.borderTinted,
            todayContentColor = RecitTheme.colors.foregroundTinted,
        ),
    )
}

/**
 * `IdentifierCatalogView`: the catalogues an edition, a work or a person can be identified in — or the
 * kinds of links it can have — each with the server's example, to pick the one an identifier is added to.
 */
@Composable
fun IdentifierCatalogPage(
    group: EditionProperty.Group,
    catalogue: EditionPropertyCatalogue,
    onChoose: (EditionProperty) -> Unit,
    onBack: () -> Unit,
) {
    val isDatabases: Boolean = group == EditionProperty.Group.Databases
    FormPageScaffold(
        title = stringResource(if (isDatabases) R.string.edit_edition_databases_add else R.string.edit_edition_links_add),
        onBack = onBack,
    ) {
        item(key = "catalog") {
            FormSection(
                header = null,
                footer = stringResource(R.string.edit_edition_identifiers_catalog_footer),
                modifier = Modifier.padding(top = Spacing.medium),
            ) {
                catalogue.inGroup(group).forEachIndexed { index, property ->
                    if (index > 0) FormDivider()
                    EditionPropertyRow(
                        label = stringResource(EditionPropertyLabels.label(property)),
                        value = property.example,
                        placeholder = "",
                        onClick = { onChoose(property) },
                    )
                }
            }
        }
    }
}

/**
 * `IdentifierInputView`: one identifier or link, checked as it is typed against the pattern the server
 * checks it with — a value refused here would have been refused there, with a less useful message.
 */
@Composable
fun IdentifierInputPage(property: EditionProperty, onAdd: (ClaimLiteral) -> Unit, onBack: () -> Unit) {
    var text: String by rememberSaveable { mutableStateOf("") }
    val name: String = stringResource(EditionPropertyLabels.label(property))
    val literal: ClaimLiteral? = property.literal(text)
    val focus: FocusRequester = remember { FocusRequester() }
    LaunchedEffect(Unit) { focus.requestFocus() }
    FormPageScaffold(title = name, onBack = onBack) {
        item(key = "field") {
            val status: EditionFormRules.IdentifierStatus = EditionFormRules.identifierStatus(property, text)
            val footer: String? = when (status) {
                EditionFormRules.IdentifierStatus.Empty -> null
                is EditionFormRules.IdentifierStatus.Example -> stringResource(R.string.edit_edition_identifiers_example, status.example)
                EditionFormRules.IdentifierStatus.Invalid -> stringResource(R.string.edit_edition_identifiers_invalid, name)
            }
            Column(Modifier.padding(top = Spacing.medium)) {
                FormSection(header = null, footer = null) {
                    FormTextRow(
                        label = name,
                        value = text,
                        onValueChange = { text = it },
                        placeholder = property.example.orEmpty(),
                        modifier = Modifier.focusRequester(focus),
                        keyboardOptions = KeyboardOptions(
                            capitalization = KeyboardCapitalization.None,
                            autoCorrectEnabled = false,
                            keyboardType = if (property.kind == EditionProperty.Kind.Url) KeyboardType.Uri else KeyboardType.Ascii,
                        ),
                    )
                }
                if (footer != null) {
                    FormFootnote(
                        text = footer,
                        color = if (status == EditionFormRules.IdentifierStatus.Invalid) RecitTheme.colors.foregroundError else RecitTheme.colors.foregroundSecondary,
                        modifier = Modifier.padding(horizontal = Spacing.large, vertical = Spacing.small),
                    )
                }
            }
        }
        item(key = "add") {
            PrimaryButton(
                text = stringResource(R.string.edit_edition_identifiers_add),
                onClick = { literal?.let(onAdd) },
                enabled = literal != null,
                modifier = Modifier.padding(Spacing.medium),
            )
        }
    }
}

/**
 * `EditionChoiceListView`: the values a property allows, when they are too many for a menu — a work's
 * form —, the one it holds checked, « Non précisé » last. A choice closes the page.
 */
@Composable
fun ChoiceListPage(property: EditionProperty, properties: EditionProperties, onChange: (EditionProperties) -> Unit, onBack: () -> Unit) {
    val selected: String? = properties.literal(property)?.string
    val choose: (String?) -> Unit = { uri ->
        onChange(properties.setLiteral(uri?.let { ClaimLiteral.Text(it) }, property))
        onBack()
    }
    FormPageScaffold(title = stringResource(EditionPropertyLabels.label(property)), onBack = onBack) {
        item(key = "choices") {
            FormSection(header = null, footer = null, modifier = Modifier.padding(top = Spacing.medium)) {
                property.choices.forEachIndexed { index, choice ->
                    if (index > 0) FormDivider()
                    ChoiceRow(stringResource(EditionPropertyLabels.label(choice)), isSelected = selected == choice.uri) { choose(choice.uri) }
                }
                FormDivider()
                ChoiceRow(stringResource(R.string.edition_choice_none), isSelected = selected == null) { choose(null) }
            }
        }
    }
}

/** One value of a [ChoiceListPage]: its name, and a check when it is the one held. */
@Composable
private fun ChoiceRow(title: String, isSelected: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = MinRowHeight)
            .selectable(selected = isSelected, role = Role.RadioButton, onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
    ) {
        Text(title, style = RecitTheme.typography.content300, color = RecitTheme.colors.foregroundDefault, modifier = Modifier.weight(1f))
        if (isSelected) Icon(Icons.Default.Check, contentDescription = null, tint = RecitTheme.colors.foregroundTinted)
    }
}

/** A date kept across a rotation with its precision, so a day set and a precision lowered can be raised again. */
private val PublicationDateSaver: Saver<PublicationDate, Any> = listSaver(
    save = { listOf(it.year, it.month, it.day, it.precision.ordinal) },
    restore = { PublicationDate(it[0], it[1], it[2], PublicationDate.Precision.entries[it[3]]) },
)

/** The calendar reaches back to the first printed books, and further when the edition says so. */
private const val EarliestYear: Int = 1450
