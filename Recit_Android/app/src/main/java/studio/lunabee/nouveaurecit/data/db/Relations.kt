package studio.lunabee.nouveaurecit.data.db

import androidx.room.Embedded
import androidx.room.Junction
import androidx.room.Relation
import java.text.Collator

/**
 * An inventory item with what every row shows of it: its edition, its owner, and the authors of the
 * edition's works — what the row names when the edition itself names nobody.
 */
data class ItemRow(
    @Embedded val item: InventoryItemEntity,
    @Relation(parentColumn = "editionUri", entityColumn = "uri")
    val edition: EditionEntity?,
    @Relation(parentColumn = "ownerId", entityColumn = "id")
    val owner: UserEntity?,
    @Relation(entity = EditionEntity::class, parentColumn = "editionUri", entityColumn = "uri")
    val editionWorks: EditionWorkAuthors? = null,
) {
    val title: String get() = edition?.title.orEmpty()
    val subtitle: String? get() = edition?.subtitle?.takeIf { it.isNotBlank() }
    val authorNames: List<String>
        get() = displayedAuthorNames(
            editionNames = edition?.authorNames.orEmpty(),
            workAuthorNames = editionWorks?.works.orEmpty().flatMap { it.authors }.map { it.name },
        )
    val image: String? get() = edition?.image

    companion object {
        /**
         * `Edition.displayedAuthorNames` (feature 0036): the edition's own names, or — until a sync
         * has filled them, and for a snapshot that names nobody — its works' authors, deduplicated
         * and sorted so that a row does not reorder from one emission to the next.
         */
        fun displayedAuthorNames(editionNames: List<String>, workAuthorNames: List<String>): List<String> {
            val own: List<String> = editionNames.map(String::trim).filter(String::isNotEmpty)
            if (own.isNotEmpty()) return own
            return workAuthorNames.map(String::trim).filter(String::isNotEmpty).distinct().sortedWith(Collator.getInstance())
        }
    }
}

/** An edition and its works, each with its authors: [ItemRow]'s fallback for naming a book. */
data class EditionWorkAuthors(
    @Embedded val edition: EditionEntity,
    @Relation(
        entity = WorkEntity::class,
        parentColumn = "uri",
        entityColumn = "uri",
        associateBy = Junction(EditionWorkCrossRef::class, parentColumn = "editionUri", entityColumn = "workUri"),
    )
    val works: List<WorkWithAuthors>,
)

data class ShelfWithItems(
    @Embedded val shelf: ShelfEntity,
    @Relation(
        entity = InventoryItemEntity::class,
        parentColumn = "id",
        entityColumn = "id",
        associateBy = Junction(ShelfItemCrossRef::class, parentColumn = "shelfId", entityColumn = "itemId"),
    )
    val items: List<ItemRow>,
)

data class ListWithElements(
    @Embedded val list: EntityListEntity,
    @Relation(parentColumn = "id", entityColumn = "listId")
    val elements: List<EntityListItemEntity>,
)

data class EditionWithWorks(
    @Embedded val edition: EditionEntity,
    @Relation(
        parentColumn = "uri",
        entityColumn = "uri",
        associateBy = Junction(EditionWorkCrossRef::class, parentColumn = "editionUri", entityColumn = "workUri"),
    )
    val works: List<WorkEntity>,
)

data class WorkWithAuthors(
    @Embedded val work: WorkEntity,
    @Relation(
        parentColumn = "uri",
        entityColumn = "uri",
        associateBy = Junction(WorkAuthorCrossRef::class, parentColumn = "workUri", entityColumn = "authorUri"),
    )
    val authors: List<AuthorEntity>,
)
