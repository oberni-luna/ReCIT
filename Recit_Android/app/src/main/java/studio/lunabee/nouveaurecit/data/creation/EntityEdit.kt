package studio.lunabee.nouveaurecit.data.creation

import studio.lunabee.nouveaurecit.data.model.EntityLabel
import java.util.UUID

/**
 * `EntityEdit` (iOS feature 0057): a work or a person as « Modifier l'œuvre » and « Modifier
 * l'auteur·ice » change it — its labels, a title or a name per language, and every property of its
 * catalogue — against what inventaire.io holds. No opinion about the network, like [EditionEdit]: the form
 * fills it, `EntityCreationRepository.saveEntity` runs the steps it lists and tells it which ones landed.
 *
 * Each screen saves its own entity: the people a claim names that inventaire.io does not have are created
 * first, then the claims go one at a time, then the labels. What landed moves into [original] and
 * [originalLabels], so a retry sends only what is left.
 *
 * Only inventaire.io's own entities are opened ([canEdit]): a Wikidata one is changed on Wikidata.
 *
 * Immutable. Open one with [open]; change [properties] with [copy], the labels through the functions below.
 */
data class EntityEdit(
    val uri: String,
    /** The labels as inventaire.io holds them, after every one that landed, keyed by language. */
    val originalLabels: Map<String, String>,
    /** The labels as the form has them: the one shown first, then the others. */
    val labels: List<Label>,
    /** The properties as inventaire.io holds them, after every claim that landed. */
    val original: EditionProperties,
    val properties: EditionProperties,
    /** The language a person created from the form is labelled in: the entity's own. */
    val labelLanguage: String,
) {
    /** One label: the title or the name in one language. */
    data class Label(val language: String, val value: String) {
        val trimmedValue: String get() = value.trim()
    }

    val catalogue: EditionPropertyCatalogue get() = properties.catalogue

    val isEditable: Boolean get() = canEdit(uri)

    /** The name the screen and the rows beneath it show: the first label that says something. */
    val displayName: String get() = labels.map { it.trimmedValue }.firstOrNull { it.isNotEmpty() }.orEmpty()

    // Labels

    /** The languages a label can be added in, less those the entity has one in. */
    val addableLanguages: List<String>
        get() = LABEL_LANGUAGES.filter { language -> labels.none { it.language == language } }

    /** Adds an empty label in [language], for the reader to fill. */
    fun addingLabel(language: String): EntityEdit =
        if (labels.any { it.language == language }) this else copy(labels = labels + Label(language, ""))

    fun withLabel(language: String, value: String): EntityEdit =
        copy(labels = labels.map { if (it.language == language) it.copy(value = value) else it })

    // What there is to send

    /** The labels changed or added. One emptied is not sent: `update-label` cannot take a label away. */
    val labelUpdates: List<EntityLabelUpdate>
        get() = labels.mapNotNull { label ->
            val value: String = label.trimmedValue
            if (value.isEmpty() || value == originalLabels[label.language]?.trim()) return@mapNotNull null
            EntityLabelUpdate(uri = uri, lang = label.language, value = value)
        }

    val claimUpdates: List<EditionClaimUpdate> get() = properties.updates(original, uri)

    val hasChanges: Boolean get() = labelUpdates.isNotEmpty() || properties.differs(original)

    /** Whether there is something to send, and it can be sent: no label it had emptied, and a name left to show. */
    val isSaveable: Boolean
        get() = isEditable &&
            hasChanges &&
            displayName.isNotEmpty() &&
            labels.all { originalLabels[it.language] == null || it.trimmedValue.isNotEmpty() }

    /** The next request of the save, or `null` once everything has landed. */
    val nextStep: EditionEditStep?
        get() {
            for (pending in properties.pendingEntities) {
                val kind: EntityCreationKind = EntityCreationKind.of(pending.property, publisherUri = null) ?: continue
                return EditionEditStep.CreateEntity(pending.entity.id, pending.entity.trimmedLabel, labelLanguage, kind)
            }
            claimUpdates.firstOrNull()?.let { return EditionEditStep.Claim(it) }
            return labelUpdates.firstOrNull()?.let { EditionEditStep.Label(it) }
        }

    // What landed

    fun entityCreated(id: UUID, uri: String): EntityEdit = copy(properties = properties.entityCreated(id, uri))

    fun landed(update: EditionClaimUpdate): EntityEdit = copy(original = original.apply(update, properties))

    fun landed(update: EntityLabelUpdate): EntityEdit = copy(originalLabels = originalLabels + (update.lang to update.value))

    /** Shows a person this entity names under a new name: one just renamed in « Modifier l'auteur·ice ». */
    fun rename(uri: String, label: String): EntityEdit =
        copy(original = original.rename(uri, label), properties = properties.rename(uri, label))

    // Showing

    /** A work as « Édition de » lists it: its title, and the authors it names. */
    val editionWork: EditionWork
        get() = EditionWork(
            uri = uri,
            title = displayName,
            authors = properties.entities(WorkProperties.Author).mapNotNull { author ->
                author.uri?.let { NewBookAuthor(name = author.trimmedLabel, uri = it) }
            },
            titleLanguage = labels.firstOrNull()?.language,
        )

    companion object {
        /**
         * The languages offered by « Ajouter dans une autre langue »: those the app's readers most often
         * write in. Any other is added on the website.
         */
        val LABEL_LANGUAGES: List<String> = listOf(
            "fr", "en", "de", "es", "it", "pt", "nl", "ca", "eu", "br", "oc", "sv", "da", "nb", "fi",
            "pl", "cs", "ru", "uk", "bg", "el", "tr", "ar", "he", "ja", "zh", "ko",
        )

        /**
         * The entity as it opens: its labels, the one shown first, then the others by language; and its
         * properties, as read and as the form will change them.
         */
        fun open(
            uri: String,
            labels: Map<String, String>,
            properties: EditionProperties,
            originalLanguage: String? = null,
        ): EntityEdit {
            val shown: String? = EntityLabel.language(labels, originalLanguage)
            val ordered: List<String> = labels.keys.sortedWith(compareBy<String> { it != shown }.thenBy { it })
            return EntityEdit(
                uri = uri,
                originalLabels = labels,
                labels = ordered.map { Label(it, labels[it].orEmpty()) },
                original = properties,
                properties = properties,
                labelLanguage = shown ?: originalLanguage ?: ResolveRequestBuilder.defaultLabelLanguage,
            )
        }

        /**
         * Whether the work or person behind this uri opens in « Modifier l'œuvre » or « Modifier
         * l'auteur·ice »: inventaire.io's own only. A Wikidata one is changed on Wikidata, through an
         * account this app does not hold.
         */
        fun canEdit(uri: String?): Boolean = uri?.startsWith("inv:") == true
    }
}
