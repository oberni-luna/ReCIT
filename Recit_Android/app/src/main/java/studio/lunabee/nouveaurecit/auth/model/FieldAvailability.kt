package studio.lunabee.nouveaurecit.auth.model

/**
 * `Model/Authentication/FieldAvailability.swift`: what a sign-up field may be while it is typed,
 * including dropping an answer that arrives for text the user has already changed.
 */
data class FieldAvailability(
    val field: Field,
    val text: String = "",
    val state: State = State.Empty,
) {
    enum class Field { Username, Email }

    enum class State { Empty, Checking, Available, Taken, Invalid, Undetermined }

    enum class Outcome {
        Available,
        Taken,
        Invalid,
        Undetermined,
        ;

        companion object {
            fun from(status: Int, errorName: String?, serverMessage: String?): Outcome {
                if (status in 200..299) return Available
                if (status != 400) return Undetermined
                if (errorName != null && errorName.startsWith("invalid_")) return Invalid
                if (serverMessage == null) return Undetermined
                if ("already used" in serverMessage) return Taken
                if ("reserved word" in serverMessage) return Invalid
                if (serverMessage.startsWith("invalid ")) return Invalid
                return Undetermined
            }
        }
    }

    val pendingQuery: String? get() = if (state == State.Checking) text else null
    val isAvailable: Boolean get() = state == State.Available
    val isRefused: Boolean get() = state == State.Taken || state == State.Invalid
    val isFilled: Boolean get() = state != State.Empty

    val failure: AuthFailure?
        get() = when {
            this.field == Field.Username && state == State.Taken -> AuthFailure.UsernameTaken
            this.field == Field.Username && state == State.Invalid -> AuthFailure.UsernameInvalid
            this.field == Field.Email && state == State.Taken -> AuthFailure.EmailTaken
            this.field == Field.Email && state == State.Invalid -> AuthFailure.EmailInvalid
            else -> null
        }

    fun edited(newText: String): FieldAvailability {
        if (newText == text) return this
        return copy(text = newText, state = if (newText.isBlank()) State.Empty else State.Checking)
    }

    fun apply(outcome: Outcome, query: String): FieldAvailability {
        if (query != text || state == State.Empty) return this
        val newState: State = when (outcome) {
            Outcome.Available -> State.Available
            Outcome.Taken -> State.Taken
            Outcome.Invalid -> State.Invalid
            Outcome.Undetermined -> State.Undetermined
        }
        return copy(state = newState)
    }
}
