package studio.lunabee.nouveaurecit.data.model

import studio.lunabee.nouveaurecit.data.db.AuthorEntity
import studio.lunabee.nouveaurecit.data.db.EditionEntity
import studio.lunabee.nouveaurecit.data.db.EntityListEntity
import studio.lunabee.nouveaurecit.data.db.EntityListItemEntity
import studio.lunabee.nouveaurecit.data.db.InventoryItemEntity
import studio.lunabee.nouveaurecit.data.db.ShelfEntity
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.data.db.WorkEntity
import studio.lunabee.nouveaurecit.network.ImageUrl
import studio.lunabee.nouveaurecit.network.dto.EntityResultDto
import studio.lunabee.nouveaurecit.network.dto.EntitySnapshotDto
import studio.lunabee.nouveaurecit.network.dto.ItemDto
import studio.lunabee.nouveaurecit.network.dto.ListDto
import studio.lunabee.nouveaurecit.network.dto.ListElementDto
import studio.lunabee.nouveaurecit.network.dto.ShelfDto
import studio.lunabee.nouveaurecit.network.dto.UserDto
import studio.lunabee.nouveaurecit.network.dto.WikidataProperty
import java.text.Normalizer

/*
 * Each `@Model`'s `init(dto:)` and `update(from:)`, as pure functions (ADR 0001): `merge(existing, dto)`
 * builds a new row when there is none, and otherwise folds the payload into the row it has, guarded
 * field by field so that a sparse payload never wipes good local data.
 */

object Merges {
    fun user(existing: UserEntity?, dto: UserDto, baseUrl: String): UserEntity {
        val position: List<Double>? = dto.position?.takeIf { it.size == 2 }
        val avatar: String? = dto.picture?.let { "$baseUrl$it" }
        val counts = dto.snapshot?.values.orEmpty()
        val itemCount: Int = counts.maxOfOrNull { it.itemsCount } ?: 0
        val lastItemAdded: Double = counts.maxOfOrNull { it.itemsLastAdd ?: 0.0 } ?: 0.0
        if (existing == null) {
            return UserEntity(
                id = dto.id,
                rev = dto.rev.orEmpty(),
                username = dto.username,
                email = dto.email,
                latitude = position?.get(0),
                longitude = position?.get(1),
                avatarUrl = avatar,
                lastItemAdded = lastItemAdded,
                itemCount = itemCount,
                created = dto.created,
            )
        }
        return existing.copy(
            rev = dto.rev?.takeIf { it.isNotEmpty() } ?: existing.rev,
            username = dto.username,
            email = dto.email ?: existing.email,
            latitude = position?.get(0) ?: existing.latitude,
            longitude = position?.get(1) ?: existing.longitude,
            avatarUrl = avatar ?: existing.avatarUrl,
            created = dto.created ?: existing.created,
            itemCount = itemCount,
            lastItemAdded = lastItemAdded,
        )
    }

    fun author(existing: AuthorEntity?, dto: EntityResultDto): AuthorEntity {
        val name: String? = (dto.labels["fr"] ?: dto.labels["en"] ?: dto.labels.values.firstOrNull())?.takeIf { it.isNotEmpty() }
        val subtitle: String? = dto.descriptions?.let { it["fr"] ?: it["en"] }
        val image: String? = ImageUrl.absolute(dto.image?.url)
        val born: String? = dto.claimString(WikidataProperty.DATE_OF_BIRTH)
        val died: String? = dto.claimString(WikidataProperty.DATE_OF_DEATH)
        if (existing == null) {
            return AuthorEntity(
                uri = dto.uri,
                lastrevid = dto.lastrevid ?: 0,
                name = name ?: "",
                subtitle = subtitle,
                dateOfBirth = born,
                dateOfDeath = died,
                image = image,
            )
        }
        return existing.copy(
            lastrevid = dto.lastrevid ?: existing.lastrevid,
            name = name ?: existing.name,
            subtitle = subtitle ?: existing.subtitle,
            dateOfBirth = born ?: existing.dateOfBirth,
            dateOfDeath = died ?: existing.dateOfDeath,
            image = image ?: existing.image,
        )
    }

    fun work(existing: WorkEntity?, dto: EntityResultDto): WorkEntity {
        val title: String? = (dto.labels["fr"] ?: dto.labels["en"] ?: dto.labels.values.firstOrNull())?.takeIf { it.isNotEmpty() }
        val subtitle: String? = dto.descriptions?.let { it["fr"] ?: it["en"] }
        val image: String? = ImageUrl.absolute(dto.image?.url)
        val date: String? = dto.claimString(WikidataProperty.PUBLICATION_DATE)
        if (existing == null) {
            return WorkEntity(
                uri = dto.uri,
                lastrevid = dto.lastrevid ?: 0,
                title = title ?: "Unknown",
                subtitle = subtitle,
                originalLang = dto.originalLang,
                image = image,
                publicationDate = date,
            )
        }
        return existing.copy(
            lastrevid = dto.lastrevid ?: existing.lastrevid,
            title = title ?: existing.title,
            subtitle = subtitle ?: existing.subtitle,
            originalLang = dto.originalLang ?: existing.originalLang,
            image = image ?: existing.image,
            publicationDate = date ?: existing.publicationDate,
        )
    }

    fun edition(existing: EditionEntity?, dto: EntityResultDto): EditionEntity {
        val title: String? = editionTitle(dto.labels, dto.claimString(WikidataProperty.TITLE))
        val subtitle: String? = dto.descriptions?.get("fromclaims")
        val image: String? = ImageUrl.absolute(dto.image?.url)
        val pages: Int? = dto.claimNumber(WikidataProperty.NUMBER_OF_PAGES)?.toInt()
        if (existing == null) {
            return EditionEntity(
                uri = dto.uri,
                title = title ?: "Unknown",
                subtitle = subtitle,
                lang = dto.originalLang,
                image = image,
                numberOfPages = pages,
            )
        }
        return existing.copy(
            title = title ?: existing.title,
            subtitle = subtitle ?: existing.subtitle,
            lang = dto.originalLang ?: existing.lang,
            image = image ?: existing.image,
            numberOfPages = pages ?: existing.numberOfPages,
        )
    }

    /** `EditionTitle.resolve`: `labels.fromclaims`, then `labels.mul`, then the `wdt:P1476` claim. */
    fun editionTitle(labels: Map<String, String>?, titleClaim: String?): String? =
        listOf(labels?.get("fromclaims"), labels?.get("mul"), titleClaim).firstOrNull { !it.isNullOrEmpty() }

    /** An edition built from an item's snapshot — only when the store has none under that uri. */
    fun edition(uri: String, snapshot: EntitySnapshotDto): EditionEntity = EditionEntity(
        uri = uri,
        title = snapshot.title,
        subtitle = snapshot.subtitle,
        lang = snapshot.lang,
        authorNames = snapshot.authors?.split(",")?.map(String::trim)?.filter(String::isNotEmpty).orEmpty(),
        image = ImageUrl.absolute(snapshot.image),
        series = snapshot.series,
    )

    fun item(existing: InventoryItemEntity?, dto: ItemDto, ownerUsername: String): InventoryItemEntity {
        val index: String = searchIndex(
            ownerUsername = ownerUsername,
            authorNames = dto.snapshot.authors?.split(",").orEmpty(),
            title = dto.snapshot.title,
            subtitle = dto.snapshot.subtitle,
        )
        if (existing == null) {
            return InventoryItemEntity(
                id = dto.id,
                rev = dto.rev,
                editionUri = dto.entity,
                transaction = TransactionType.from(dto.transaction) ?: TransactionType.Inventorying,
                visibility = dto.visibility.orEmpty().mapNotNull(Visibility::from),
                ownerId = dto.owner,
                created = dto.created,
                updated = dto.updated,
                busy = dto.busy,
                details = dto.details.orEmpty(),
                searchIndex = index,
            )
        }
        return existing.copy(
            rev = dto.rev,
            transaction = TransactionType.from(dto.transaction) ?: existing.transaction,
            visibility = dto.visibility?.mapNotNull(Visibility::from) ?: existing.visibility,
            updated = dto.updated,
            busy = dto.busy,
            details = dto.details ?: existing.details,
            searchIndex = index,
        )
    }

    fun shelf(existing: ShelfEntity?, dto: ShelfDto): ShelfEntity {
        if (existing == null) {
            return ShelfEntity(
                id = dto.id,
                rev = dto.rev,
                name = dto.name,
                description = dto.description.orEmpty(),
                ownerId = dto.owner,
                visibility = dto.visibility.orEmpty().mapNotNull(Visibility::from),
                color = dto.color,
                created = dto.created,
                updated = dto.updated,
            )
        }
        return existing.copy(
            rev = dto.rev.ifEmpty { existing.rev },
            name = dto.name,
            description = dto.description ?: existing.description,
            visibility = dto.visibility?.mapNotNull(Visibility::from) ?: existing.visibility,
            color = dto.color ?: existing.color,
            updated = dto.updated ?: existing.updated,
        )
    }

    fun list(existing: EntityListEntity?, dto: ListDto): EntityListEntity {
        val base: EntityListEntity = existing ?: EntityListEntity(id = dto.id, name = dto.name)
        return base.copy(
            rev = dto.rev.ifEmpty { base.rev },
            name = dto.name,
            explanation = dto.description,
            created = if (dto.created > 0) dto.created else base.created,
            updated = dto.updated ?: base.updated,
            visibility = dto.visibility.mapNotNull(Visibility::from),
            type = EntityListType.from(dto.type),
        )
    }

    fun listElement(dto: ListElementDto, listId: String, type: EntityListType): EntityListItemEntity = EntityListItemEntity(
        id = dto.id,
        listId = listId,
        uri = dto.uri,
        comment = dto.comment.orEmpty(),
        ordinal = dto.ordinal,
        created = dto.created,
        updated = dto.updated,
        entityType = type,
    )

    /** `InventoryItem.buildSearchIndex`: owner, authors, title and subtitle, folded once. */
    fun searchIndex(ownerUsername: String, authorNames: List<String>, title: String, subtitle: String?): String =
        fold((listOf(ownerUsername) + authorNames + title + listOfNotNull(subtitle)).joinToString(" "))

    /** Case- and diacritic-insensitive form, the `localizedStandardContains` of this app. */
    fun fold(text: String): String =
        Normalizer.normalize(text, Normalizer.Form.NFD)
            .replace(Regex("\\p{Mn}+"), "")
            .lowercase()
            .trim()
}
