package studio.lunabee.nouveaurecit.data.creation

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull

/**
 * `ClaimLiteral` (iOS feature 0050): one value of a claim as it travels — a string (a title, a uri, an
 * identifier, a date) or a whole number.
 *
 * inventaire.io validates the type, not only the text: `wdt:P1104`, the number of pages, is a positive
 * integer and the string `"256"` is refused. So a count goes out as a JSON number, which is what
 * [ClaimLiteralSerializer] writes.
 */
@Serializable(with = ClaimLiteralSerializer::class)
sealed interface ClaimLiteral {
    data class Text(val value: String) : ClaimLiteral

    data class Integer(val value: Int) : ClaimLiteral

    /** The value as the form prints it. */
    val text: String
        get() = when (this) {
            is Text -> value
            is Integer -> value.toString()
        }

    /** The value when it is a string: a uri, a date, an identifier. */
    val string: String? get() = (this as? Text)?.value

    companion object {
        /**
         * A value as `by-uris` answers it. A number is kept only when whole — inventaire.io's numbers are
         * counts — and a boolean is nothing an edition holds.
         */
        fun from(element: JsonElement): ClaimLiteral? {
            val primitive: JsonPrimitive = element as? JsonPrimitive ?: return null
            if (primitive is JsonNull) return null
            if (primitive.isString) return Text(primitive.content)
            if (primitive.booleanOrNull != null) return null
            primitive.intOrNull?.let { return Integer(it) }
            val number: Double = primitive.doubleOrNull ?: return null
            val whole: Int = number.toInt()
            return if (whole.toDouble() == number) Integer(whole) else null
        }
    }
}

/** Writes a [ClaimLiteral] as the bare JSON primitive it is — `"Lucioles"` or `256` — and reads it back. */
object ClaimLiteralSerializer : KSerializer<ClaimLiteral> {
    override val descriptor: SerialDescriptor = JsonPrimitive.serializer().descriptor

    override fun serialize(encoder: Encoder, value: ClaimLiteral) {
        val primitive: JsonPrimitive = when (value) {
            is ClaimLiteral.Text -> JsonPrimitive(value.value)
            is ClaimLiteral.Integer -> JsonPrimitive(value.value)
        }
        encoder.encodeSerializableValue(JsonPrimitive.serializer(), primitive)
    }

    override fun deserialize(decoder: Decoder): ClaimLiteral {
        val primitive: JsonPrimitive = decoder.decodeSerializableValue(JsonPrimitive.serializer())
        return ClaimLiteral.from(primitive) ?: ClaimLiteral.Text(primitive.content)
    }
}
