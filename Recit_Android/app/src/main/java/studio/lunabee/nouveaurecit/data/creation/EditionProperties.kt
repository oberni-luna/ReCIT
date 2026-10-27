package studio.lunabee.nouveaurecit.data.creation

import kotlinx.serialization.json.JsonElement
import java.util.UUID

/**
 * `EditionProperties` (iOS feature 0050): the values of an edition's catalogue properties
 * ([EditionProperty]) — publisher, collection, date, language, format, counts, contributors, identifiers
 * and links — as the form holds them. No opinion about the network; shared by the edit of an edition that
 * exists and the draft of one being created.
 *
 * It answers the two questions a save asks: which entities have to be created before a claim can name
 * them, and — against the values the form opened on — which claims to send. A single-valued property
 * sends one update naming the value it replaces; a multivalued one, one update per value added or taken
 * away.
 *
 * Immutable: every change answers a new value.
 */
data class EditionProperties(
    /** The values, keyed by property uri, in the order read or added. A property with no value has no key. */
    val values: Map<String, List<EditionClaimValue>> = emptyMap(),
) {
    // Reading

    fun values(property: EditionProperty): List<EditionClaimValue> = values[property.uri].orEmpty()

    fun entities(property: EditionProperty): List<EditionEntityValue> = values(property).mapNotNull { it.entityValue }

    /** The value of a single-valued literal property: a date, a count, a format. */
    fun literal(property: EditionProperty): ClaimLiteral? = values(property).firstOrNull()?.claim

    /** Every entity uri the values name, for the call that fetches their labels. */
    val entityUris: List<String>
        get() = EditionProperty.all.flatMap { property -> entities(property).mapNotNull { it.uri } }

    /**
     * The entities still to be created, in the order the save creates them: people and publishers first,
     * collections last — a collection is created with its publisher's uri.
     */
    val pendingEntities: List<PendingEntity>
        get() {
            val pending: List<PendingEntity> = EditionProperty.all.flatMap { property ->
                entities(property).filter { it.uri == null }.map { PendingEntity(property, it) }
            }
            return pending.filter { it.property != EditionProperty.Collection } + pending.filter { it.property == EditionProperty.Collection }
        }

    /** The publisher a new collection is created under: the edition's first one that exists. */
    val publisherUri: String? get() = entities(EditionProperty.Publisher).firstNotNullOfOrNull { it.uri }

    /** Whether a collection is waiting to be created with no publisher to be created under. */
    val hasOrphanCollection: Boolean
        get() = pendingEntities.any { it.property == EditionProperty.Collection } && entities(EditionProperty.Publisher).isEmpty()

    /** The claims as they go on the wire, keyed by property uri. An entity still to be created is left out. */
    val claims: Map<String, List<ClaimLiteral>>
        get() = buildMap {
            for (property in EditionProperty.all) {
                val literals: List<ClaimLiteral> = values(property).mapNotNull { it.claim }
                if (literals.isNotEmpty()) put(property.uri, literals)
            }
        }

    // Changing

    /** Sets a single-valued literal: a date, a count, a format. `null` takes it away. */
    fun setLiteral(literal: ClaimLiteral?, property: EditionProperty): EditionProperties =
        with(property, literal?.let { listOf(EditionClaimValue.Literal(it)) }.orEmpty())

    /** Adds a literal to a multivalued property — an identifier, a link — unless it is there. */
    fun addLiteral(literal: ClaimLiteral, property: EditionProperty): EditionProperties {
        val current: List<EditionClaimValue> = values(property)
        if (current.any { it.claim == literal }) return this
        val added = EditionClaimValue.Literal(literal)
        return with(property, if (property.isMultivalued) current + added else listOf(added))
    }

    /** Adds an entity, unless it is named already. */
    fun add(entity: EditionEntityValue, property: EditionProperty): EditionProperties {
        if (entity.trimmedLabel.isEmpty() && entity.uri == null) return this
        val current: List<EditionClaimValue> = values(property)
        if (current.any { it.entityValue?.isSame(entity) == true }) return this
        val added = EditionClaimValue.Entity(entity)
        return with(property, if (property.isMultivalued) current + added else listOf(added))
    }

    /** What a swipe on the values of a property takes away. */
    fun remove(indices: Set<Int>, property: EditionProperty): EditionProperties =
        with(property, values(property).filterIndexed { index, _ -> index !in indices })

    /** Records the uri an entity was created under: the claim that names it can go now. */
    fun entityCreated(id: UUID, uri: String): EditionProperties = EditionProperties(
        values.mapValues { (_, current) ->
            current.map { value ->
                val entity: EditionEntityValue? = value.entityValue
                if (entity?.id == id) EditionClaimValue.Entity(entity.copy(uri = uri)) else value
            }
        },
    )

    // What there is to send

    /** The claim updates that turn [original] into these values, on the entity [uri]. Entities still to create wait. */
    fun updates(original: EditionProperties, uri: String): List<EditionClaimUpdate> = buildList {
        for (property in EditionProperty.all) {
            val before: List<ClaimLiteral> = original.values(property).mapNotNull { it.claim }
            val after: List<ClaimLiteral> = values(property).mapNotNull { it.claim }
            if (property.isMultivalued) {
                before.filter { it !in after }.forEach { add(EditionClaimUpdate(uri, property.uri, oldValue = it, newValue = null)) }
                after.filter { it !in before }.forEach { add(EditionClaimUpdate(uri, property.uri, oldValue = null, newValue = it)) }
            } else if (before.firstOrNull() != after.firstOrNull()) {
                add(EditionClaimUpdate(uri, property.uri, oldValue = before.firstOrNull(), newValue = after.firstOrNull()))
            }
        }
    }

    /** Records that [update] landed, so it drops out of [updates]. The value added is named from [current]. */
    fun apply(update: EditionClaimUpdate, current: EditionProperties): EditionProperties {
        val property: EditionProperty = EditionProperty.named(update.property) ?: return this
        var landed: List<EditionClaimValue> = values(property)
        update.oldValue?.let { old -> landed = landed.filterNot { it.claim == old } }
        update.newValue?.let { new ->
            val named: EditionClaimValue = current.values(property).firstOrNull { it.claim == new } ?: EditionClaimValue.Literal(new)
            landed = if (property.isMultivalued) landed + named else listOf(named)
        }
        return with(property, landed)
    }

    /** Whether the values differ from [original] in a way the save has to send or create. */
    fun differs(original: EditionProperties): Boolean = pendingEntities.isNotEmpty() || updates(original, "").isNotEmpty()

    private fun with(property: EditionProperty, newValues: List<EditionClaimValue>): EditionProperties =
        EditionProperties(if (newValues.isEmpty()) values - property.uri else values + (property.uri to newValues))

    /** An entity of [property] waiting to be created. */
    data class PendingEntity(val property: EditionProperty, val entity: EditionEntityValue)

    companion object {
        /** Reads the catalogue's properties out of an entity's claims; entity values are named with [labels], or by their uri. */
        fun fromClaims(claims: Map<String, List<JsonElement>>, labels: Map<String, String>): EditionProperties {
            val values: MutableMap<String, List<EditionClaimValue>> = linkedMapOf()
            for (property in EditionProperty.all) {
                val literals: List<ClaimLiteral> = claims[property.uri].orEmpty().mapNotNull(ClaimLiteral::from)
                if (literals.isEmpty()) continue
                values[property.uri] = literals.map { literal ->
                    val uri: String? = literal.string
                    if (property.searchType != null && uri != null) {
                        EditionClaimValue.Entity(EditionEntityValue(uri = uri, label = labels[uri] ?: uri))
                    } else {
                        EditionClaimValue.Literal(literal)
                    }
                }
            }
            return EditionProperties(values)
        }
    }
}
