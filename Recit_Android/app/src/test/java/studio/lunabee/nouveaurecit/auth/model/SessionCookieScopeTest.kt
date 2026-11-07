package studio.lunabee.nouveaurecit.auth.model

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SessionCookieScopeTest {
    @Test
    fun inventaire_cookies_belong_to_inventaire_with_or_without_the_leading_dot() {
        assertTrue(SessionCookieScope.covers("inventaire.io", "inventaire.io"))
        assertTrue(SessionCookieScope.covers(".inventaire.io", "inventaire.io"))
        assertTrue(SessionCookieScope.covers(".Inventaire.IO", "inventaire.io"))
    }

    @Test
    fun the_local_backend_cookies_belong_to_it_and_not_to_inventaire() {
        assertTrue(SessionCookieScope.covers("10.0.2.2", "10.0.2.2"))
        assertFalse(SessionCookieScope.covers("10.0.2.2", "inventaire.io"))
        assertFalse(SessionCookieScope.covers("inventaire.io", "10.0.2.2"))
    }

    @Test
    fun a_parent_domain_covers_its_subdomains_never_the_reverse_nor_a_lookalike() {
        assertTrue(SessionCookieScope.covers(".inventaire.io", "api.inventaire.io"))
        assertFalse(SessionCookieScope.covers("api.inventaire.io", "inventaire.io"))
        assertFalse(SessionCookieScope.covers("inventaire.io", "notinventaire.io"))
        assertFalse(SessionCookieScope.covers("", "inventaire.io"))
    }
}
