package studio.lunabee.nouveaurecit.ui.profile.edit

import android.content.Context
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.user.Coordinates
import studio.lunabee.nouveaurecit.designsystem.CornerRadius
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.RecitTopBar
import studio.lunabee.nouveaurecit.ui.editedition.FormActionBar
import studio.lunabee.nouveaurecit.ui.editedition.FormDivider
import studio.lunabee.nouveaurecit.ui.editedition.FormFootnote
import studio.lunabee.nouveaurecit.ui.editedition.FormSection
import studio.lunabee.nouveaurecit.ui.editedition.FormTextRow

/**
 * `ProfilePositionView` (iOS feature 0055): placing the account on the map. The pin stays at the centre and
 * the map moves under it; a search moves the map to a place, when the phone has a geocoder; « Valider »
 * hands the centre to the draft, which rounds it to about a kilometre, and « Retirer ma position » hands
 * it nothing. Nothing is sent from here: « Enregistrer » on the form does that.
 *
 * The map holds still above the rest, so that dragging it never scrolls the page. No « Utiliser ma position
 * actuelle »: it needs the location permission, which the app does not ask for.
 */
@Composable
fun ProfilePositionScreen(
    position: Coordinates?,
    onConfirm: (Coordinates) -> Unit,
    onRemove: () -> Unit,
    onBack: () -> Unit,
) {
    val context: Context = LocalContext.current
    val placeSearch: PlaceSearch = remember { PlaceSearch(context) }
    val scope: CoroutineScope = rememberCoroutineScope()
    val start: Coordinates = position ?: FALLBACK_CENTER
    var center: Coordinates by rememberSaveable(stateSaver = CoordinatesSaver) { mutableStateOf(start) }
    var zoom: Double by rememberSaveable { mutableDoubleStateOf(if (position == null) COUNTRY_ZOOM else NEIGHBOURHOOD_ZOOM) }
    var target: Coordinates by remember { mutableStateOf(center) }
    var moves: Int by remember { mutableIntStateOf(0) }
    var query: String by rememberSaveable { mutableStateOf("") }
    var results: List<FoundPlace> by remember { mutableStateOf(emptyList()) }
    var hasSearched: Boolean by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { RecitTopBar(title = stringResource(R.string.profile_position_title), onBack = onBack) },
        bottomBar = {
            FormActionBar(
                text = stringResource(R.string.profile_position_confirm),
                onClick = { onConfirm(center) },
                enabled = true,
                isLoading = false,
            )
        },
        containerColor = RecitTheme.colors.backgroundForm,
    ) { padding: PaddingValues ->
        Column(Modifier.padding(padding).fillMaxSize().imePadding()) {
            PositionMap(
                target = target,
                zoom = zoom,
                moves = moves,
                interactive = true,
                onCenterChange = { center = it },
                modifier = Modifier
                    .padding(horizontal = Spacing.medium, vertical = Spacing.small)
                    .fillMaxWidth()
                    .height(MapHeight)
                    .clip(RoundedCornerShape(CornerRadius.medium)),
            )
            FormFootnote(
                text = stringResource(R.string.profile_position_map_footer),
                modifier = Modifier.padding(horizontal = Spacing.large),
            )
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(top = Spacing.medium, bottom = Spacing.large),
            ) {
                if (placeSearch.isAvailable) {
                    item(key = "search") {
                        PlaceSearchSection(
                            query = query,
                            onQueryChange = { query = it },
                            onSearch = {
                                scope.launch {
                                    results = placeSearch.search(query)
                                    hasSearched = true
                                }
                            },
                            results = results,
                            hasSearched = hasSearched,
                            onChoose = { place: FoundPlace ->
                                target = place.coordinates
                                zoom = NEIGHBOURHOOD_ZOOM
                                center = place.coordinates
                                moves += 1
                                results = emptyList()
                                hasSearched = false
                            },
                        )
                    }
                }
                if (position != null) {
                    item(key = "remove") {
                        FormSection(
                            header = null,
                            footer = stringResource(R.string.profile_position_remove_footer),
                            modifier = Modifier.padding(top = Spacing.medium),
                        ) {
                            DestructiveRow(text = stringResource(R.string.profile_position_remove), onClick = onRemove)
                        }
                    }
                }
            }
        }
    }
}

/** The field, then the places found — five at most — or the sentence saying there were none. */
@Composable
private fun PlaceSearchSection(
    query: String,
    onQueryChange: (String) -> Unit,
    onSearch: () -> Unit,
    results: List<FoundPlace>,
    hasSearched: Boolean,
    onChoose: (FoundPlace) -> Unit,
) {
    FormSection(header = null, footer = null) {
        FormTextRow(
            label = stringResource(R.string.profile_position_search),
            value = query,
            onValueChange = onQueryChange,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
            keyboardActions = KeyboardActions(onSearch = { onSearch() }),
        )
        results.forEach { place: FoundPlace ->
            FormDivider()
            Text(
                text = place.name,
                style = RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundDefault,
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(role = Role.Button) { onChoose(place) }
                    .padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
            )
        }
        if (hasSearched && results.isEmpty()) {
            FormDivider()
            Text(
                text = stringResource(R.string.profile_position_search_empty),
                style = RecitTheme.typography.content300,
                color = RecitTheme.colors.foregroundSecondary,
                modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.sMedium),
            )
        }
    }
}

private val CoordinatesSaver: Saver<Coordinates, Any> = listSaver(
    save = { listOf(it.latitude, it.longitude) },
    restore = { Coordinates(latitude = it[0], longitude = it[1]) },
)

/** Mainland France, when there is no position yet to open on. */
private val FALLBACK_CENTER: Coordinates = Coordinates(latitude = 46.6, longitude = 2.4)

/** iOS's 8° span: the whole country. */
private const val COUNTRY_ZOOM: Double = 6.0

/** iOS's 0.06° span: a few kilometres around the point. */
private const val NEIGHBOURHOOD_ZOOM: Double = 13.0

private val MapHeight: Dp = 280.dp
