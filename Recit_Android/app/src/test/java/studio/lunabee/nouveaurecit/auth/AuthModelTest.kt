package studio.lunabee.nouveaurecit.auth

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import studio.lunabee.nouveaurecit.auth.model.AuthFailure
import studio.lunabee.nouveaurecit.auth.model.FieldAvailability
import studio.lunabee.nouveaurecit.auth.model.PasswordResetOutcome
import studio.lunabee.nouveaurecit.auth.model.PostSignupSession
import studio.lunabee.nouveaurecit.auth.model.SessionCookie
import studio.lunabee.nouveaurecit.auth.model.SessionExpiry
import studio.lunabee.nouveaurecit.network.NetworkError
import java.util.Base64

class AuthFailureTest {
    @Test
    fun success_is_no_failure() {
        assertNull(AuthFailure.classify(200, null))
        assertNull(AuthFailure.classifySignup(201, null, null))
    }

    @Test
    fun refused_credentials_are_401_and_403() {
        assertEquals(AuthFailure.InvalidCredentials, AuthFailure.classify(401, "unauthorized"))
        assertEquals(AuthFailure.InvalidCredentials, AuthFailure.classify(403, null))
        assertEquals(AuthFailure.Server(500, "boom"), AuthFailure.classify(500, "boom"))
    }

    @Test
    fun signup_reads_the_error_name_first_then_the_message() {
        assertEquals(AuthFailure.UsernameInvalid, AuthFailure.classifySignup(400, "invalid_username", null))
        assertEquals(AuthFailure.EmailInvalid, AuthFailure.classifySignup(400, "invalid_email", null))
        assertEquals(AuthFailure.PasswordRejected, AuthFailure.classifySignup(400, "invalid_password", null))
        assertEquals(AuthFailure.UsernameTaken, AuthFailure.classifySignup(400, null, "this username is already used"))
        assertEquals(AuthFailure.EmailTaken, AuthFailure.classifySignup(400, null, "this email is already used"))
        assertEquals(AuthFailure.UsernameInvalid, AuthFailure.classifySignup(400, null, "reserved word"))
        assertEquals(AuthFailure.Server(400, "other"), AuthFailure.classifySignup(400, null, "other"))
        assertEquals(AuthFailure.InvalidCredentials, AuthFailure.classifySignup(403, null, null))
    }

    @Test
    fun each_signup_failure_names_its_field() {
        assertEquals(AuthFailure.SignupField.Username, AuthFailure.UsernameTaken.signupField)
        assertEquals(AuthFailure.SignupField.Email, AuthFailure.EmailInvalid.signupField)
        assertEquals(AuthFailure.SignupField.Password, AuthFailure.PasswordRejected.signupField)
        assertNull(AuthFailure.Network.signupField)
    }
}

class FieldAvailabilityTest {
    @Test
    fun outcome_from_the_server() {
        assertEquals(FieldAvailability.Outcome.Available, FieldAvailability.Outcome.from(200, null, null))
        assertEquals(FieldAvailability.Outcome.Invalid, FieldAvailability.Outcome.from(400, "invalid_username", null))
        assertEquals(FieldAvailability.Outcome.Taken, FieldAvailability.Outcome.from(400, null, "this username is already used"))
        assertEquals(FieldAvailability.Outcome.Invalid, FieldAvailability.Outcome.from(400, null, "reserved word"))
        assertEquals(FieldAvailability.Outcome.Invalid, FieldAvailability.Outcome.from(400, null, "invalid email"))
        assertEquals(FieldAvailability.Outcome.Undetermined, FieldAvailability.Outcome.from(500, null, null))
        assertEquals(FieldAvailability.Outcome.Undetermined, FieldAvailability.Outcome.from(400, null, null))
    }

    @Test
    fun typing_checks_and_blank_empties() {
        val field = FieldAvailability(FieldAvailability.Field.Username).edited("olive")
        assertEquals(FieldAvailability.State.Checking, field.state)
        assertEquals("olive", field.pendingQuery)
        assertEquals(FieldAvailability.State.Empty, field.edited("   ").state)
    }

    @Test
    fun a_stale_answer_is_dropped() {
        val field = FieldAvailability(FieldAvailability.Field.Email).edited("a@b.c").edited("a@b.co")
        assertEquals(FieldAvailability.State.Checking, field.apply(FieldAvailability.Outcome.Taken, "a@b.c").state)
        val answered = field.apply(FieldAvailability.Outcome.Taken, "a@b.co")
        assertEquals(FieldAvailability.State.Taken, answered.state)
        assertEquals(AuthFailure.EmailTaken, answered.failure)
        assertTrue(answered.isRefused)
    }
}

class SessionCookieTest {
    private fun encode(json: String): String = Base64.getUrlEncoder().withoutPadding().encodeToString(json.toByteArray())

    @Test
    fun a_signed_in_payload_names_its_user() {
        val value: String = encode("""{"user":"36829e21389c27c629a3181e31c36301","timestamp":1787493340761}""")
        assertEquals(SessionCookie.Owner.User("36829e21389c27c629a3181e31c36301"), SessionCookie.owner(value))
        assertTrue(SessionCookie.namesAUser(listOf("signature", value)))
    }

    @Test
    fun a_public_endpoint_payload_is_anonymous() {
        assertEquals(SessionCookie.Owner.Anonymous, SessionCookie.owner(encode("""{"timestamp":1788900010063}""")))
        assertFalse(SessionCookie.namesAUser(listOf(encode("""{"timestamp":1788900010063}"""))))
    }

    @Test
    fun a_signature_is_unreadable_and_names_nobody() {
        assertEquals(SessionCookie.Owner.Unreadable, SessionCookie.owner("cuCMaGQD6PYluiHJ7c-oZdxJG39Xgf1twwkbtjFOIrE"))
    }
}

class SmallAuthTypesTest {
    @Test
    fun every_reset_answer_is_the_same_confirmation() {
        assertEquals(PasswordResetOutcome.Submitted, PasswordResetOutcome.fromServer(400, "email not found"))
        assertEquals(PasswordResetOutcome.Submitted, PasswordResetOutcome.fromServer(200, null))
        assertEquals(AuthFailure.Network, PasswordResetOutcome.transportFailure.failure)
    }

    @Test
    fun signup_chains_a_login_only_without_a_session() {
        assertEquals(PostSignupSession.Established, PostSignupSession.next(true))
        assertEquals(PostSignupSession.ChainSignIn, PostSignupSession.next(false))
    }

    @Test
    fun only_a_401_means_the_session_is_gone() {
        assertTrue(SessionExpiry.isSessionGone(NetworkError.BadStatus(401, "")))
        assertFalse(SessionExpiry.isSessionGone(NetworkError.BadStatus(403, "")))
        assertFalse(SessionExpiry.isSessionGone(IllegalStateException()))
    }
}
