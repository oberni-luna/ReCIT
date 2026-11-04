package studio.lunabee.nouveaurecit.data.db

import android.content.Context
import androidx.room.AutoMigration
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters

/**
 * The one store — `ReCIT.swift`'s `ModelContainer`. On disk, never synced anywhere else.
 *
 * Version 2 adds a list's `creatorId` and a reader's `bio`, two nullable columns: Room derives the
 * migration from the exported schemas, so the cache of 1.2.0 survives the update.
 */
@Database(
    entities = [
        UserEntity::class,
        EditionEntity::class,
        WorkEntity::class,
        AuthorEntity::class,
        EditionWorkCrossRef::class,
        WorkAuthorCrossRef::class,
        InventoryItemEntity::class,
        ShelfEntity::class,
        ShelfItemCrossRef::class,
        EntityListEntity::class,
        EntityListItemEntity::class,
        WpExtractEntity::class,
    ],
    version = 2,
    exportSchema = true,
    autoMigrations = [AutoMigration(from = 1, to = 2)],
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun entityDao(): EntityDao
    abstract fun inventoryDao(): InventoryDao
    abstract fun shelfDao(): ShelfDao
    abstract fun listDao(): ListDao

    companion object {
        fun build(context: Context): AppDatabase =
            Room.databaseBuilder(context, AppDatabase::class.java, "recit.db").build()
    }
}
