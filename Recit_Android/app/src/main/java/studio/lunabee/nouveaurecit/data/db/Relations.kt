package studio.lunabee.nouveaurecit.data.db

import androidx.room.Embedded
import androidx.room.Junction
import androidx.room.Relation

/** An inventory item with what every row shows of it: its edition and its owner. */
data class ItemRow(
    @Embedded val item: InventoryItemEntity,
    @Relation(parentColumn = "editionUri", entityColumn = "uri")
    val edition: EditionEntity?,
    @Relation(parentColumn = "ownerId", entityColumn = "id")
    val owner: UserEntity?,
) {
    val title: String get() = edition?.title.orEmpty()
    val subtitle: String? get() = edition?.subtitle?.takeIf { it.isNotBlank() }
    val authorNames: List<String> get() = edition?.authorNames.orEmpty().map(String::trim).filter(String::isNotEmpty)
    val image: String? get() = edition?.image
}

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
