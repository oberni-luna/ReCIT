package studio.lunabee.nouveaurecit.data.db

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.data.model.Visibility

/*
 * The SwiftData `@Model` types, as Room rows. The server owns identity, so every row is keyed by
 * its inventaire.io `_id` or `uri`, and the local store is a cache of server state (ADR 0001).
 *
 * SwiftData's many-to-many relationships become cross-reference tables:
 * edition ↔ work (`edition_works`), work ↔ author (`work_authors`), shelf ↔ item (`shelf_items`).
 * Dates are epoch milliseconds, as the server sends them.
 */

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String,
    val rev: String = "",
    val username: String,
    val email: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val avatarUrl: String? = null,
    val lastItemAdded: Double = 0.0,
    val itemCount: Int = 0,
    val created: Double? = null,
    val lastInventorySync: Double? = null,
    val relation: UserRelation = UserRelation.None,
)

@Entity(tableName = "editions")
data class EditionEntity(
    @PrimaryKey val uri: String,
    val title: String,
    val subtitle: String? = null,
    val lang: String? = null,
    val authorNames: List<String> = emptyList(),
    val image: String? = null,
    val series: String? = null,
    val numberOfPages: Int? = null,
)

@Entity(tableName = "works")
data class WorkEntity(
    @PrimaryKey val uri: String,
    val lastrevid: Int = 0,
    val title: String,
    val subtitle: String? = null,
    val originalLang: String? = null,
    val image: String? = null,
    val publicationDate: String? = null,
    val preferredEditionUri: String? = null,
)

@Entity(tableName = "authors")
data class AuthorEntity(
    @PrimaryKey val uri: String,
    val lastrevid: Int = 0,
    val name: String,
    val subtitle: String? = null,
    val dateOfBirth: String? = null,
    val dateOfDeath: String? = null,
    val image: String? = null,
)

@Entity(
    tableName = "edition_works",
    primaryKeys = ["editionUri", "workUri"],
    indices = [Index("workUri")],
)
data class EditionWorkCrossRef(val editionUri: String, val workUri: String)

@Entity(
    tableName = "work_authors",
    primaryKeys = ["workUri", "authorUri"],
    indices = [Index("authorUri")],
)
data class WorkAuthorCrossRef(val workUri: String, val authorUri: String)

@Entity(
    tableName = "inventory_items",
    indices = [Index("ownerId"), Index("editionUri")],
)
data class InventoryItemEntity(
    @PrimaryKey val id: String,
    val rev: String,
    val editionUri: String,
    @ColumnInfo(name = "transactionType") val transaction: TransactionType,
    val visibility: List<Visibility>,
    val ownerId: String,
    val created: Double,
    val updated: Double? = null,
    val busy: Boolean? = null,
    val details: String = "",
    /** Owner, authors, title and subtitle, folded once — what the unified search matches against. */
    val searchIndex: String = "",
)

@Entity(tableName = "shelves", indices = [Index("ownerId")])
data class ShelfEntity(
    @PrimaryKey val id: String,
    val rev: String = "",
    val name: String,
    val description: String = "",
    val ownerId: String,
    val visibility: List<Visibility> = emptyList(),
    val color: String? = null,
    val created: Double = 0.0,
    val updated: Double? = null,
)

@Entity(
    tableName = "shelf_items",
    primaryKeys = ["shelfId", "itemId"],
    indices = [Index("itemId")],
    foreignKeys = [
        ForeignKey(entity = ShelfEntity::class, parentColumns = ["id"], childColumns = ["shelfId"], onDelete = ForeignKey.CASCADE),
        ForeignKey(entity = InventoryItemEntity::class, parentColumns = ["id"], childColumns = ["itemId"], onDelete = ForeignKey.CASCADE),
    ],
)
data class ShelfItemCrossRef(val shelfId: String, val itemId: String)

@Entity(tableName = "lists")
data class EntityListEntity(
    @PrimaryKey val id: String,
    val rev: String = "",
    val name: String,
    @ColumnInfo(name = "explanation") val explanation: String = "",
    val created: Double = 0.0,
    val updated: Double? = null,
    val visibility: List<Visibility> = emptyList(),
    val type: EntityListType = EntityListType.Work,
)

@Entity(
    tableName = "list_elements",
    indices = [Index("listId")],
    foreignKeys = [
        ForeignKey(entity = EntityListEntity::class, parentColumns = ["id"], childColumns = ["listId"], onDelete = ForeignKey.CASCADE),
    ],
)
data class EntityListItemEntity(
    @PrimaryKey val id: String,
    val listId: String,
    val uri: String,
    val comment: String = "",
    val ordinal: String = "0",
    val created: Double = 0.0,
    val updated: Double? = null,
    val entityType: EntityListType = EntityListType.Work,
)

@Entity(tableName = "wp_extracts")
data class WpExtractEntity(
    @PrimaryKey val uri: String,
    val content: String,
    val url: String,
)
