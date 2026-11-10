package studio.lunabee.nouveaurecit.ui.createbook

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.designsystem.WithLabel

/**
 * `CreateBookISBNField` (iOS feature 0087): the ISBN of a book created from Recherche, where no barcode was
 * read — typed, or left empty. A wrong check digit is said under the field once the reader has left it, or
 * as soon as the thirteen digits are in, not while a number is still being typed.
 */
@Composable
fun CreateBookIsbnField(isbn: String, isValid: Boolean, onIsbnChange: (String) -> Unit, modifier: Modifier = Modifier) {
    var isFocused: Boolean by remember { mutableStateOf(false) }
    val showsError: Boolean = !isValid && (!isFocused || isbn.count(Char::isDigit) >= ISBN_13_LENGTH)
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(Spacing.xSmall)) {
        WithLabel(label = stringResource(R.string.edit_edition_isbn)) {
            BasicTextField(
                value = isbn,
                onValueChange = onIsbnChange,
                singleLine = true,
                textStyle = RecitTheme.typography.content300.copy(color = RecitTheme.colors.foregroundDefault),
                cursorBrush = SolidColor(RecitTheme.colors.foregroundTinted),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number, autoCorrectEnabled = false),
                modifier = Modifier
                    .fillMaxWidth()
                    .onFocusChanged { isFocused = it.isFocused }
                    .testTag("e2e.createBook.isbnField"),
                decorationBox = { field ->
                    Box {
                        if (isbn.isEmpty()) {
                            Text(
                                text = stringResource(R.string.create_book_isbn_placeholder),
                                style = RecitTheme.typography.content300,
                                color = RecitTheme.colors.foregroundPlaceholder,
                            )
                        }
                        field()
                    }
                },
            )
        }
        if (showsError) {
            Text(
                text = stringResource(R.string.create_book_isbn_invalid),
                style = RecitTheme.typography.caption200,
                color = RecitTheme.colors.foregroundError,
                modifier = Modifier.testTag("e2e.createBook.isbnError"),
            )
        }
    }
}

private const val ISBN_13_LENGTH: Int = 13
