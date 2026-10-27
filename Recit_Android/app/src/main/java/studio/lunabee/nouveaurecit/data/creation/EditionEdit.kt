package studio.lunabee.nouveaurecit.data.creation

import java.util.UUID

/**
 * `EditionEdit` (iOS features 0049, 0050): what the user has changed in « Modifier l'édition », and what
 * that comes to on the wire. No opinion about the network: the form fills it, the repository runs the
 * steps it lists ([nextStep]) and tells it which ones landed.
 *
 * Besides the edition's own title, subtitle and cover, the form changes the works the edition is an
 * edition of — added from the search or created, detached with a swipe —, each work's title and authors
 * ([WorkEdit]), and every other property of the catalogue ([EditionProperties]). Whatever has to exist
 * before a claim can name it goes first: the picture, the authors inventaire.io does not have, the works
 * being created, the publishers, collections and people the edition names. Then the claims, one at a
 * time, then the works' new titles.
 *
 * **A change half sent is finished, not redone.** Each step is its own request, so a title can land and a
 * cover fail. Each one landed moves into [original], a work's `original` or an author's `uri`, and the
 * retry lists only what is left — creating an author twice would put a twin on a public database, and
 * sending the title again would name, as the value it replaces, a title the edition no longer has.
 *
 * Immutable. Open one with the secondary constructor; change [title], [subtitle] and [properties] with
 * [copy], everything else through the functions below.
 */
data class EditionEdit(
    /** The edition as the server holds it — when the form opened, then after each change that landed. */
    val original: EditionClaims,
    val title: String,
    val subtitle: String,
    /** The works the form lists under « Édition de », in order. */
    val works: List<WorkEdit>,
    /** The publisher, date, format, contributors, identifiers and links, as the form has them. */
    val properties: EditionProperties,
    val cover: Cover = Cover.Unchanged,
    /** The hash a replacing picture was filed under, once uploaded: a retry hangs it without sending it twice. */
    val uploadedCoverHash: String? = null,
) {
    /**
     * The edition as it opens. Every work it names is listed, described or not: one the description left
     * out would otherwise read as detached, and be unclaimed on the next save.
     */
    constructor(original: EditionClaims, originalWorks: List<EditionWork> = emptyList()) : this(
        original = original,
        title = original.title,
        subtitle = original.subtitle.orEmpty(),
        works = original.workUris.map { uri ->
            WorkEdit.existing(originalWorks.firstOrNull { it.uri == uri } ?: EditionWork(uri = uri, title = uri))
        },
        properties = original.properties,
    )

    /** What became of the cover since the form opened. */
    sealed interface Cover {
        data object Unchanged : Cover

        /** A new picture, the local JPEG at [path], not yet hung on the edition. */
        data class Replaced(val path: String) : Cover

        /** The edition's picture taken away. */
        data object Removed : Cover
    }

    // The cover

    /** The local picture the cover frame shows, when one replaces the edition's. */
    val coverPath: String? get() = (cover as? Cover.Replaced)?.path

    /** The picture the cover frame shows from the server: the edition's own, while nothing replaced or removed it. */
    val coverUrl: String? get() = if (cover == Cover.Unchanged) original.coverUrl else null

    /**
     * A picture set replaces the edition's, none removes it. Either way one already uploaded no longer
     * stands. Taking away a picture the edition never had changes nothing.
     */
    fun withCover(path: String?): EditionEdit = copy(
        cover = when {
            path != null -> Cover.Replaced(path)
            original.coverHash == null -> Cover.Unchanged
            else -> Cover.Removed
        },
        uploadedCoverHash = null,
    )

    /** The picture to upload before the cover's claim can be sent: a replacing one whose hash is not known yet. */
    val coverToUpload: String? get() = if (uploadedCoverHash == null) coverPath else null

    // The works

    /** Adds a work picked from the search — unless the edition lists it already. */
    fun addWork(candidate: WorkCandidate): EditionEdit {
        if (works.any { it.uri == candidate.uri }) return this
        return copy(works = works + WorkEdit.existing(EditionWork.of(candidate)))
    }

    /** None of the works found is the book's: one is created, named after the search, and listed last. */
    fun startNewWork(query: String): EditionEdit = copy(works = works + WorkEdit.newTitled(query))

    /** What a swipe on « Détacher » takes away: the edition stops being an edition of it; the work stays. */
    fun detachWork(id: UUID): EditionEdit = copy(works = works.filterNot { it.id == id })

    /** Changes one work — its title, its authors — from « Modifier l'œuvre ». */
    fun updatingWork(id: UUID, transform: (WorkEdit) -> WorkEdit): EditionEdit =
        copy(works = works.map { if (it.id == id) transform(it) else it })

    /** The uris of the works listed that exist. */
    val workUris: List<String> get() = works.mapNotNull { it.uri }

    // What there is to send

    val trimmedTitle: String get() = title.trim()

    val trimmedSubtitle: String get() = subtitle.trim()

    private val originalTitle: String get() = original.title.trim()

    private val originalSubtitle: String get() = original.subtitle.orEmpty().trim()

    val hasChanges: Boolean
        get() = trimmedTitle != originalTitle ||
            trimmedSubtitle != originalSubtitle ||
            cover != Cover.Unchanged ||
            workUris.toSet() != original.workUris.toSet() ||
            works.any { it.hasChanges } ||
            properties.differs(original.properties)

    /**
     * Whether there is something to send, and it can be sent. An edition without a title is unreadable in
     * every list, one with no work is refused (`wdt:P629` is required), a work created without a title or
     * an author is an orphan, and a collection is created under its publisher.
     */
    val isSaveable: Boolean
        get() = trimmedTitle.isNotEmpty() &&
            hasChanges &&
            works.isNotEmpty() &&
            works.all { it.isComplete } &&
            !properties.hasOrphanCollection

    /** The language the labels of a created author or work are written in: the edition's, or the reader's. */
    val labelLanguage: String get() = original.labelLanguage ?: ResolveRequestBuilder.defaultLabelLanguage

    /** The next request of the save, or `null` once everything has landed. */
    val nextStep: EditionEditStep?
        get() {
            coverToUpload?.let { return EditionEditStep.UploadCover(it) }
            for (work in works.filter { it.isEditable }) {
                val author: NewBookAuthor = work.authors.firstOrNull { it.uri == null } ?: continue
                return EditionEditStep.CreateAuthor(author.id, author.trimmedName, labelLanguage)
            }
            works.firstOrNull { it.isNew }?.let { work ->
                return EditionEditStep.CreateWork(work.id, work.trimmedTitle, labelLanguage, work.authors.mapNotNull { it.uri })
            }
            for (pending in properties.pendingEntities) {
                val kind: EntityCreationKind = EntityCreationKind.of(pending.property, properties.publisherUri) ?: continue
                return EditionEditStep.CreateEntity(pending.entity.id, pending.entity.trimmedLabel, labelLanguage, kind)
            }
            claimUpdates.firstOrNull()?.let { return EditionEditStep.Claim(it) }
            return labelUpdates.firstOrNull()?.let { EditionEditStep.Label(it) }
        }

    /**
     * The claims to send, in order: the edition's title, subtitle, cover and works, its other properties,
     * then the authors added to and taken from its works. A replacing cover is listed once its hash is
     * known, an author or a work once it exists.
     */
    val claimUpdates: List<EditionClaimUpdate>
        get() = buildList {
            if (trimmedTitle != originalTitle) add(update(EditableClaimProperty.Title, from = original.title, to = trimmedTitle))
            if (trimmedSubtitle != originalSubtitle) add(update(EditableClaimProperty.Subtitle, from = original.subtitle, to = trimmedSubtitle))
            when (cover) {
                is Cover.Replaced -> uploadedCoverHash?.let { add(update(EditableClaimProperty.Cover, from = original.coverHash, to = it)) }
                Cover.Removed -> add(update(EditableClaimProperty.Cover, from = original.coverHash, to = null))
                Cover.Unchanged -> Unit
            }
            val current: List<String> = workUris
            original.workUris.filter { it !in current }.forEach { add(update(EditableClaimProperty.Work, from = it, to = null)) }
            current.filter { it !in original.workUris }.forEach { add(update(EditableClaimProperty.Work, from = null, to = it)) }

            addAll(properties.updates(original.properties, original.uri))

            for (work in works.filter { it.isEditable }) {
                val uri: String = work.uri ?: continue
                work.addedAuthors.mapNotNull { it.uri }.forEach { add(update(EditableClaimProperty.Author, of = uri, from = null, to = it)) }
                work.removedAuthors.mapNotNull { it.uri }.forEach { add(update(EditableClaimProperty.Author, of = uri, from = it, to = null)) }
            }
        }

    /** The works renamed, as `update-label` takes them: in the language of the title they had. */
    val labelUpdates: List<EntityLabelUpdate>
        get() = works.mapNotNull { work ->
            val uri: String = work.uri ?: return@mapNotNull null
            val title: String = work.renamedTitle ?: return@mapNotNull null
            EntityLabelUpdate(uri = uri, lang = work.original?.titleLanguage ?: labelLanguage, value = title)
        }

    // What landed

    /** Records the hash a new cover was filed under. */
    fun coverUploaded(hash: String): EditionEdit = copy(uploadedCoverHash = hash)

    /** Records the uri an author was created under: it is named from now on. */
    fun authorCreated(id: UUID, uri: String): EditionEdit = copy(works = works.map { it.authorCreated(id, uri) })

    /** Records a work created: it exists now, written by its authors, and only the edition's claim on it is left. */
    fun workCreated(id: UUID, uri: String): EditionEdit = updatingWork(id) { it.created(uri, labelLanguage) }

    /** Records the uri a publisher, a collection or a person was created under. */
    fun entityCreated(id: UUID, uri: String): EditionEdit = copy(properties = properties.entityCreated(id, uri))

    /** Records that [update] landed: what it changed now holds its new value, so it drops out of [claimUpdates]. */
    fun landed(update: EditionClaimUpdate): EditionEdit {
        val oldValue: String? = update.oldValue?.string
        val newValue: String? = update.newValue?.string
        return when (EditableClaimProperty.from(update.property)) {
            EditableClaimProperty.Title -> copy(original = original.copy(title = newValue.orEmpty()))
            EditableClaimProperty.Subtitle -> copy(original = original.copy(subtitle = newValue))
            EditableClaimProperty.Cover -> copy(original = original.copy(coverHash = newValue), cover = Cover.Unchanged, uploadedCoverHash = null)
            EditableClaimProperty.Work -> copy(
                original = original.copy(workUris = original.workUris.filterNot { it == oldValue } + listOfNotNull(newValue)),
            )
            EditableClaimProperty.Author -> copy(works = works.map { if (it.uri == update.uri) it.authorLanded(newValue, oldValue) else it })
            null -> copy(original = original.copy(properties = original.properties.apply(update, properties)))
        }
    }

    /** Records that a work's new title landed. */
    fun landed(update: EntityLabelUpdate): EditionEdit =
        copy(works = works.map { if (it.uri == update.uri) it.titleLanded(update.value) else it })

    /** An update naming the value it replaces, on the edition unless said otherwise. An empty value is no value. */
    private fun update(property: EditableClaimProperty, of: String? = null, from: String?, to: String?): EditionClaimUpdate =
        EditionClaimUpdate.of(
            uri = of ?: original.uri,
            property = property,
            oldValue = from?.takeIf { it.isNotEmpty() },
            newValue = to?.takeIf { it.isNotEmpty() },
        )
}
