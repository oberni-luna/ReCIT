package studio.lunabee.nouveaurecit.data.db

import androidx.room.TypeConverter
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import studio.lunabee.nouveaurecit.data.model.EntityListType
import studio.lunabee.nouveaurecit.data.model.TransactionType
import studio.lunabee.nouveaurecit.data.model.UserRelation
import studio.lunabee.nouveaurecit.data.model.Visibility

class Converters {
    private val json: Json = Json
    private val strings = ListSerializer(String.serializer())

    @TypeConverter
    fun fromStrings(value: List<String>): String = json.encodeToString(strings, value)

    @TypeConverter
    fun toStrings(value: String): List<String> = json.decodeFromString(strings, value)

    @TypeConverter
    fun fromVisibility(value: List<Visibility>): String = json.encodeToString(strings, value.map { it.raw })

    @TypeConverter
    fun toVisibility(value: String): List<Visibility> = json.decodeFromString(strings, value).mapNotNull(Visibility::from)

    @TypeConverter
    fun fromTransactionType(value: TransactionType): String = value.raw

    @TypeConverter
    fun toTransactionType(value: String): TransactionType = TransactionType.from(value) ?: TransactionType.Inventorying

    @TypeConverter
    fun fromRelation(value: UserRelation): String = value.name

    @TypeConverter
    fun toRelation(value: String): UserRelation = UserRelation.entries.firstOrNull { it.name == value } ?: UserRelation.None

    @TypeConverter
    fun fromListType(value: EntityListType): String = value.raw

    @TypeConverter
    fun toListType(value: String): EntityListType = EntityListType.from(value)
}
