package studio.lunabee.nouveaurecit.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Upsert
import kotlinx.coroutines.flow.Flow
import studio.lunabee.nouveaurecit.data.model.UserRelation

/*
 * `Flow`-returning queries are the `@Query` of the iOS views: a screen collects them and redraws when
 * a sync or an optimistic write lands. `suspend` ones serve the repositories.
 *
 * `@Upsert` replaces a whole row, so callers merge first (`Merges.kt`) and upsert the merged row —
 * that is how "update in place, never wipe good local data" survives Room's row semantics.
 */

@Dao
interface UserDao {
    @Query("SELECT * FROM users WHERE id = :id")
    fun observe(id: String): Flow<UserEntity?>

    @Query("SELECT * FROM users WHERE id != :myId AND relation = :relation ORDER BY username COLLATE NOCASE")
    fun observeByRelation(myId: String, relation: UserRelation): Flow<List<UserEntity>>

    @Query("SELECT COUNT(*) FROM users WHERE id != :myId AND relation = 'RequestReceived'")
    fun observeReceivedRequestCount(myId: String): Flow<Int>

    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun get(id: String): UserEntity?

    @Query("SELECT * FROM users WHERE id IN (:ids)")
    suspend fun get(ids: List<String>): List<UserEntity>

    @Query("SELECT * FROM users")
    suspend fun all(): List<UserEntity>

    @Upsert
    suspend fun upsert(users: List<UserEntity>)

    @Query("UPDATE users SET relation = :relation WHERE id = :id")
    suspend fun setRelation(id: String, relation: UserRelation)

    @Query("UPDATE users SET lastInventorySync = :value WHERE id = :id")
    suspend fun setLastInventorySync(id: String, value: Double?)

    @Query("DELETE FROM users")
    suspend fun deleteAll()
}

@Dao
interface EntityDao {
    @Query("SELECT * FROM editions WHERE uri = :uri")
    fun observeEdition(uri: String): Flow<EditionEntity?>

    @Transaction
    @Query("SELECT * FROM editions WHERE uri = :uri")
    fun observeEditionWithWorks(uri: String): Flow<EditionWithWorks?>

    @Query("SELECT * FROM editions WHERE uri = :uri")
    suspend fun edition(uri: String): EditionEntity?

    @Query("SELECT * FROM editions WHERE uri IN (:uris)")
    suspend fun editions(uris: List<String>): List<EditionEntity>

    @Query("SELECT e.* FROM editions e INNER JOIN edition_works ew ON ew.editionUri = e.uri WHERE ew.workUri = :workUri")
    fun observeEditionsOfWork(workUri: String): Flow<List<EditionEntity>>

    @Query("SELECT workUri FROM edition_works WHERE editionUri = :editionUri")
    suspend fun workUris(editionUri: String): List<String>

    @Query("SELECT * FROM works WHERE uri = :uri")
    fun observeWork(uri: String): Flow<WorkEntity?>

    @Transaction
    @Query("SELECT * FROM works WHERE uri = :uri")
    fun observeWorkWithAuthors(uri: String): Flow<WorkWithAuthors?>

    @Transaction
    @Query("SELECT * FROM works WHERE uri IN (:uris)")
    fun observeWorksWithAuthors(uris: List<String>): Flow<List<WorkWithAuthors>>

    @Query("SELECT * FROM works WHERE uri = :uri")
    suspend fun work(uri: String): WorkEntity?

    @Query("SELECT * FROM works WHERE uri IN (:uris)")
    suspend fun works(uris: List<String>): List<WorkEntity>

    @Query("SELECT w.* FROM works w INNER JOIN work_authors wa ON wa.workUri = w.uri WHERE wa.authorUri = :authorUri ORDER BY w.title COLLATE NOCASE")
    fun observeWorksOfAuthor(authorUri: String): Flow<List<WorkEntity>>

    @Query("SELECT a.* FROM authors a INNER JOIN work_authors wa ON wa.authorUri = a.uri WHERE wa.workUri IN (:workUris)")
    fun observeAuthorsOfWorks(workUris: List<String>): Flow<List<AuthorEntity>>

    @Query("SELECT * FROM authors WHERE uri = :uri")
    fun observeAuthor(uri: String): Flow<AuthorEntity?>

    @Query("SELECT * FROM authors WHERE uri IN (:uris)")
    fun observeAuthors(uris: List<String>): Flow<List<AuthorEntity>>

    @Query("SELECT * FROM authors WHERE uri = :uri")
    suspend fun author(uri: String): AuthorEntity?

    @Query("SELECT * FROM authors WHERE uri IN (:uris)")
    suspend fun authors(uris: List<String>): List<AuthorEntity>

    @Upsert
    suspend fun upsertEditions(editions: List<EditionEntity>)

    @Upsert
    suspend fun upsertWorks(works: List<WorkEntity>)

    @Upsert
    suspend fun upsertAuthors(authors: List<AuthorEntity>)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun linkEditionWorks(links: List<EditionWorkCrossRef>)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun linkWorkAuthors(links: List<WorkAuthorCrossRef>)

    @Query("UPDATE works SET preferredEditionUri = :editionUri WHERE uri = :workUri")
    suspend fun setPreferredEdition(workUri: String, editionUri: String)

    @Query("SELECT * FROM wp_extracts WHERE uri = :uri")
    fun observeExtract(uri: String): Flow<WpExtractEntity?>

    @Query("SELECT * FROM wp_extracts WHERE uri = :uri")
    suspend fun extract(uri: String): WpExtractEntity?

    @Upsert
    suspend fun upsertExtract(extract: WpExtractEntity)

    @Query("DELETE FROM editions")
    suspend fun deleteEditions()

    @Query("DELETE FROM works")
    suspend fun deleteWorks()

    @Query("DELETE FROM authors")
    suspend fun deleteAuthors()

    @Query("DELETE FROM edition_works")
    suspend fun deleteEditionWorks()

    @Query("DELETE FROM work_authors")
    suspend fun deleteWorkAuthors()

    @Query("DELETE FROM wp_extracts")
    suspend fun deleteExtracts()
}

@Dao
interface InventoryDao {
    @Transaction
    @Query("SELECT * FROM inventory_items WHERE ownerId = :ownerId ORDER BY created DESC")
    fun observeItemsOf(ownerId: String): Flow<List<ItemRow>>

    @Transaction
    @Query("SELECT * FROM inventory_items ORDER BY created DESC")
    fun observeAll(): Flow<List<ItemRow>>

    @Transaction
    @Query("SELECT * FROM inventory_items WHERE id = :id")
    fun observeItem(id: String): Flow<ItemRow?>

    @Transaction
    @Query("SELECT * FROM inventory_items WHERE editionUri = :editionUri ORDER BY created DESC")
    fun observeItemsOfEdition(editionUri: String): Flow<List<ItemRow>>

    @Transaction
    @Query(
        "SELECT i.* FROM inventory_items i INNER JOIN edition_works ew ON ew.editionUri = i.editionUri " +
            "WHERE ew.workUri IN (:workUris) ORDER BY i.created DESC",
    )
    fun observeItemsOfWorks(workUris: List<String>): Flow<List<ItemRow>>

    @Query("SELECT COUNT(*) FROM inventory_items WHERE ownerId = :ownerId")
    fun observeCountOf(ownerId: String): Flow<Int>

    @Query("SELECT * FROM inventory_items WHERE id = :id")
    suspend fun get(id: String): InventoryItemEntity?

    @Query("SELECT * FROM inventory_items WHERE id IN (:ids)")
    suspend fun get(ids: List<String>): List<InventoryItemEntity>

    @Query("SELECT DISTINCT editionUri FROM inventory_items")
    suspend fun heldEditionUris(): List<String>

    @Upsert
    suspend fun upsert(items: List<InventoryItemEntity>)

    @Query("UPDATE inventory_items SET transactionType = :transaction WHERE id = :id")
    suspend fun setTransaction(id: String, transaction: String)

    @Query("UPDATE inventory_items SET details = :details WHERE id = :id")
    suspend fun setDetails(id: String, details: String)

    @Query("DELETE FROM inventory_items WHERE id = :id")
    suspend fun delete(id: String)

    @Query("DELETE FROM inventory_items WHERE ownerId = :ownerId")
    suspend fun deleteOwnedBy(ownerId: String)

    @Query("DELETE FROM inventory_items")
    suspend fun deleteAll()
}

@Dao
interface ShelfDao {
    @Transaction
    @Query("SELECT * FROM shelves WHERE ownerId = :ownerId ORDER BY name COLLATE NOCASE")
    fun observeShelvesOf(ownerId: String): Flow<List<ShelfWithItems>>

    @Transaction
    @Query("SELECT * FROM shelves WHERE id = :id")
    fun observeShelf(id: String): Flow<ShelfWithItems?>

    @Query("SELECT shelfId FROM shelf_items WHERE itemId = :itemId")
    fun observeShelfIdsOf(itemId: String): Flow<List<String>>

    @Query("SELECT * FROM shelves WHERE id = :id")
    suspend fun get(id: String): ShelfEntity?

    @Query("SELECT * FROM shelves WHERE ownerId = :ownerId")
    suspend fun shelvesOf(ownerId: String): List<ShelfEntity>

    @Query("SELECT id FROM shelves WHERE id IN (:ids)")
    suspend fun existingIds(ids: List<String>): List<String>

    @Query("SELECT itemId FROM shelf_items WHERE shelfId = :shelfId")
    suspend fun itemIds(shelfId: String): List<String>

    @Upsert
    suspend fun upsert(shelves: List<ShelfEntity>)

    @Query("DELETE FROM shelves WHERE id IN (:ids)")
    suspend fun delete(ids: List<String>)

    @Query("DELETE FROM shelves WHERE ownerId = :ownerId")
    suspend fun deleteOwnedBy(ownerId: String)

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun link(links: List<ShelfItemCrossRef>)

    @Query("DELETE FROM shelf_items WHERE shelfId = :shelfId AND itemId = :itemId")
    suspend fun unlink(shelfId: String, itemId: String)

    @Query("DELETE FROM shelf_items WHERE shelfId = :shelfId")
    suspend fun unlinkAllOf(shelfId: String)

    @Query("DELETE FROM shelf_items WHERE itemId = :itemId")
    suspend fun unlinkItem(itemId: String)

    @Transaction
    suspend fun replaceItems(shelfId: String, itemIds: List<String>) {
        unlinkAllOf(shelfId)
        link(itemIds.map { ShelfItemCrossRef(shelfId, it) })
    }

    @Transaction
    suspend fun replaceShelvesOfItem(itemId: String, shelfIds: List<String>) {
        unlinkItem(itemId)
        link(shelfIds.map { ShelfItemCrossRef(it, itemId) })
    }

    @Query("DELETE FROM shelves")
    suspend fun deleteAll()

    /** How many étagères [ownerId] owns — the account-deletion summary. */
    @Query("SELECT COUNT(*) FROM shelves WHERE ownerId = :ownerId")
    fun observeCountOf(ownerId: String): Flow<Int>
}

@Dao
interface ListDao {
    @Transaction
    @Query("SELECT * FROM lists ORDER BY created DESC")
    fun observeLists(): Flow<List<ListWithElements>>

    @Transaction
    @Query("SELECT * FROM lists WHERE id = :id")
    fun observeList(id: String): Flow<ListWithElements?>

    @Query("SELECT * FROM lists WHERE id = :id")
    suspend fun get(id: String): EntityListEntity?

    @Query("SELECT * FROM lists")
    suspend fun all(): List<EntityListEntity>

    @Query("SELECT * FROM list_elements WHERE listId = :listId")
    suspend fun elements(listId: String): List<EntityListItemEntity>

    @Upsert
    suspend fun upsert(lists: List<EntityListEntity>)

    @Upsert
    suspend fun upsertElements(elements: List<EntityListItemEntity>)

    @Query("DELETE FROM lists WHERE id IN (:ids)")
    suspend fun delete(ids: List<String>)

    @Query("DELETE FROM list_elements WHERE id IN (:ids)")
    suspend fun deleteElements(ids: List<String>)

    @Query("DELETE FROM list_elements WHERE listId = :listId AND uri IN (:uris)")
    suspend fun deleteElementsByUri(listId: String, uris: List<String>)

    @Query("DELETE FROM lists")
    suspend fun deleteAll()

    /** How many lists the store holds — only mine are ever synced. */
    @Query("SELECT COUNT(*) FROM lists")
    fun observeCount(): Flow<Int>
}
