package studio.lunabee.nouveaurecit.data.user

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Locale

/** The languages « Langue du compte » offers: the 29 `PUT /api/user` accepts, named in the app's language. */
class AccountLanguageTest {
    @Test
    fun everyLanguageTheServerAcceptsIsOfferedOnce() {
        val all: List<AccountLanguage> = AccountLanguage.all(Locale.FRENCH)

        assertEquals(29, all.size)
        assertEquals(29, all.map { it.code }.toSet().size)
        assertTrue(all.contains(AccountLanguage("fr", "Français")))
    }

    @Test
    fun languagesAreSortedByTheirName() {
        val names: List<String> = AccountLanguage.all(Locale.FRENCH).map { it.name }

        assertEquals(names.sortedWith(String.CASE_INSENSITIVE_ORDER), names)
    }

    @Test
    fun languagesAreNamedInTheAppsLanguageWhateverThePhonesIs() {
        val phone: Locale = Locale.getDefault()
        Locale.setDefault(Locale.US)
        try {
            assertEquals("Français", AccountLanguage.name("fr"))
            assertTrue(AccountLanguage.all().contains(AccountLanguage("en", "Anglais")))
        } finally {
            Locale.setDefault(phone)
        }
    }
}
