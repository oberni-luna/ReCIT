package studio.lunabee.exlibris.backend.items

import kotlinx.serialization.json.JsonObject

/**
 * inventaire.io's `buildSnapshot` (`controllers/items/lib/snapshot/`), from a `by-uris` answer fetched with the
 * works, their authors and their series as relatives: an edition's title is its `wdt:P1476`, else its best label;
 * its authors those of its works, then its own translators, illustrators and the like, named in its language.
 */
object SnapshotBuilder {
    /** inventaire.io names an edition without an original language in English. */
    private const val DEFAULT_LANG: String = "en"
    private const val TITLE: String = "wdt:P1476"
    private const val SUBTITLE: String = "wdt:P1680"
    private const val EDITION_OF: String = "wdt:P629"
    private const val PART_OF_SERIES: String = "wdt:P179"
    private const val SERIES_ORDINAL: String = "wdt:P1545"
    private const val IMAGE: String = "wdt:P18"
    private const val ISBN_13: String = "wdt:P212"
    private const val ISBN_10: String = "wdt:P957"
    private const val AUTHOR: String = "wdt:P50"
    private const val GENRE: String = "wdt:P136"
    private const val SUBJECT: String = "wdt:P921"

    /** inventaire.io's `workAuthorRelationsProperties`. */
    private val WORK_AUTHOR_PROPERTIES: List<String> =
        listOf("wdt:P50", "wdt:P58", "wdt:P98", "wdt:P110", "wdt:P6338", "wdt:P9191", "wdt:P10836", "wdt:P10837")

    /** inventaire.io's `editionAuthorRelationsProperties`. */
    private val EDITION_AUTHOR_PROPERTIES: List<String> =
        listOf("wdt:P98", "wdt:P110", "wdt:P655", "wdt:P736", "wdt:P2679", "wdt:P2680")

    /** What `by-uris` is asked to follow, so that one request brings the whole graph a snapshot is built from. */
    val relatives: List<String> =
        (WORK_AUTHOR_PROPERTIES + EDITION_AUTHOR_PROPERTIES + listOf(EDITION_OF, PART_OF_SERIES)).distinct()

    fun build(
        uri: String,
        entities: InventaireEntities,
        refreshed: Long,
    ): SnapshotOutcome {
        val entity: JsonObject? = entities.entity(uri)
        val graph: EntityGraph? = entity?.let { graph(it, entities) }
        val title: String? = graph?.title?.takeIf { it.isNotEmpty() }
        return when {
            entity == null -> {
                SnapshotOutcome.NotFound
            }

            graph == null -> {
                SnapshotOutcome.InvalidType
            }

            title == null -> {
                SnapshotOutcome.NoTitle
            }

            else -> {
                SnapshotOutcome.Built(
                    EntitySnapshot(
                        uri = entities.canonical(uri),
                        snapshot = snapshot(entity, graph, title),
                        works = graph.works.map(::work),
                        refreshed = refreshed,
                    ),
                )
            }
        }
    }

    private fun graph(
        entity: JsonObject,
        entities: InventaireEntities,
    ): EntityGraph? =
        when (entity.text("type")) {
            "edition" -> editionGraph(entity, entities)
            "work" -> workGraph(entity, entities)
            else -> null
        }

    private fun editionGraph(
        edition: JsonObject,
        entities: InventaireEntities,
    ): EntityGraph {
        val lang: String = edition.text("originalLang") ?: DEFAULT_LANG
        val works: List<JsonObject> = edition.claims(EDITION_OF).mapNotNull(entities::entity)
        val authorsUris: List<String> =
            aggregate(works, WORK_AUTHOR_PROPERTIES) + aggregate(listOf(edition), EDITION_AUTHOR_PROPERTIES)
        return EntityGraph(
            lang = lang,
            title = edition.claims(TITLE).firstOrNull() ?: edition.label(lang, null),
            image = (edition["image"] as? JsonObject)?.text("url"),
            works = works,
            authors = authorsUris.distinct().mapNotNull(entities::entity),
            series = aggregate(works, listOf(PART_OF_SERIES)).mapNotNull(entities::entity),
        )
    }

    private fun workGraph(
        work: JsonObject,
        entities: InventaireEntities,
    ): EntityGraph {
        val lang: String? = work.text("originalLang")
        return EntityGraph(
            lang = lang,
            title = work.label(lang, null),
            image = work.claims(IMAGE).firstOrNull(),
            works = listOf(work),
            authors = aggregate(listOf(work), WORK_AUTHOR_PROPERTIES).mapNotNull(entities::entity),
            series = aggregate(listOf(work), listOf(PART_OF_SERIES)).mapNotNull(entities::entity),
        )
    }

    private fun snapshot(
        entity: JsonObject,
        graph: EntityGraph,
        title: String,
    ): ItemSnapshot {
        val isEdition: Boolean = entity.text("type") == "edition"
        val seriesNames: String? = names(graph.lang, graph.series)
        return ItemSnapshot(
            title = title,
            subtitle = if (isEdition) entity.claims(SUBTITLE).firstOrNull()?.takeIf { it.isNotEmpty() } else null,
            lang = graph.lang,
            authors = names(graph.lang, graph.authors),
            image = graph.image?.takeIf(::isImageUrl),
            series = seriesNames,
            ordinal = seriesNames?.let { ordinal(graph.works) },
            worksUris = graph.works.map { it.uri() },
            authorsUris = graph.authors.map { it.uri() },
            seriesUris = graph.series.map { it.uri() },
            isbn13 = if (isEdition) entity.claims(ISBN_13).firstOrNull() else null,
            isbn10 = if (isEdition) entity.claims(ISBN_10).firstOrNull() else null,
        )
    }

    private fun work(work: JsonObject): SnapshotWork =
        SnapshotWork(
            uri = work.uri(),
            authors = work.claims(AUTHOR).ifEmpty { null },
            genres = work.claims(GENRE).ifEmpty { null },
            subjects = work.claims(SUBJECT).ifEmpty { null },
        )

    /** `setOrdinal`: one work's rank in its series, or the ranks of works all in the same one, joined by commas. */
    private fun ordinal(works: List<JsonObject>): String? =
        if (works.size == 1) {
            works.single().claims(SERIES_ORDINAL).firstOrNull()
        } else {
            aggregate(works, listOf(SERIES_ORDINAL))
                .takeIf { aggregate(works, listOf(PART_OF_SERIES)).size == 1 && it.isNotEmpty() }
                ?.joinToString(",")
        }

    private fun names(
        lang: String?,
        entities: List<JsonObject>,
    ): String? =
        entities
            .mapNotNull { it.label(lang, it.text("originalLang")) }
            .takeIf { it.isNotEmpty() }
            ?.joinToString(", ")

    private fun aggregate(
        entities: List<JsonObject>,
        properties: List<String>,
    ): List<String> = entities.flatMap { entity -> properties.flatMap { entity.claims(it) } }.distinct()

    /** inventaire.io keeps image hashes and URLs, and drops Wikimedia file names. */
    private fun isImageUrl(image: String): Boolean =
        image.startsWith("/") || image.startsWith("https://") || image.startsWith("http://")

    private data class EntityGraph(
        val lang: String?,
        val title: String?,
        val image: String?,
        val works: List<JsonObject>,
        val authors: List<JsonObject>,
        val series: List<JsonObject>,
    )
}
