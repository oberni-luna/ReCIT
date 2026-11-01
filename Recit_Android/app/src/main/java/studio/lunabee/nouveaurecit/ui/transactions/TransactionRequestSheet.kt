package studio.lunabee.nouveaurecit.ui.transactions

import android.content.res.Resources
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.SheetState
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalResources
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import studio.lunabee.nouveaurecit.AppContainer
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.ItemRow
import studio.lunabee.nouveaurecit.data.transactions.TransactionRequestFailure
import studio.lunabee.nouveaurecit.data.transactions.TransactionRequestWording
import studio.lunabee.nouveaurecit.designsystem.FormTextField
import studio.lunabee.nouveaurecit.designsystem.PrimaryButton
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.designsystem.SheetHeader
import studio.lunabee.nouveaurecit.designsystem.Spacing
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.common.LocalMessenger
import studio.lunabee.nouveaurecit.ui.common.Messenger

/**
 * `TransactionFormView` for a new request, full height: « Emprunter Dune à Anne », the sentence
 * « Vous souhaitez l'emprunter à **Anne** » where iOS had a « Type » picker the server ignored, the
 * required message with a hint for the type, and « Demander à l'emprunter ».
 *
 * The copy is read from the store by [itemId], so the sheet survives a configuration change with
 * only an id saved. A copy gone, or made inventoried by a sync while the sheet is open, closes it.
 *
 * Server-first, in the application scope: closing the sheet mid-request stops the waiting, not the
 * request. A refusal the server explains (already asked, held by someone else, no longer offered)
 * closes the sheet with the reason; any other failure keeps it open with the message typed.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransactionRequestSheet(itemId: String, onDismiss: () -> Unit) {
    val container: AppContainer = LocalAppContainer.current
    val messenger: Messenger = LocalMessenger.current
    val resources: Resources = LocalResources.current
    val scope: CoroutineScope = rememberCoroutineScope()
    val sheetState: SheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val currentOnDismiss: () -> Unit by rememberUpdatedState(onDismiss)
    var copy: RequestedCopy? by remember(itemId) { mutableStateOf(null) }
    var message: String by rememberSaveable { mutableStateOf("") }
    var isSubmitting: Boolean by remember { mutableStateOf(false) }

    // Room answers with the row as it stands: `null` there means the copy is gone, not "not yet".
    LaunchedEffect(itemId) {
        container.inventory.observeItem(itemId).collect { row: ItemRow? ->
            val next: RequestedCopy? = row?.let(::RequestedCopy)
            if (next?.wording == null) currentOnDismiss() else copy = next
        }
    }

    val shown: RequestedCopy = copy ?: return
    val wording: TransactionRequestWording = shown.wording ?: return

    fun submit() {
        if (isSubmitting) return
        isSubmitting = true
        val ownerName: String = shown.ownerName
        val text: String = message
        // The outcome is said from the application scope, so it is said even once the sheet is gone.
        val sending: Deferred<Boolean> = container.applicationScope.async {
            try {
                container.transactions.request(itemId, text)
                messenger.show(resources.getString(R.string.transaction_request_sent, ownerName))
                true
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (error: Exception) {
                val explained: Int? = TransactionRequestFailure.from(error).message
                if (explained != null) {
                    messenger.showError(resources.getString(explained))
                } else {
                    messenger.showError(resources.getString(R.string.error_generic), error.localizedMessage)
                }
                // A refusal the server explained will not change on a retry: the sheet closes.
                explained != null
            }
        }
        scope.launch {
            val closes: Boolean = sending.await()
            isSubmitting = false
            if (closes) currentOnDismiss()
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = RecitTheme.colors.backgroundRaised,
        modifier = Modifier.testTag("e2e.transactionRequest"),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .imePadding()
                .padding(horizontal = Spacing.medium)
                .padding(bottom = Spacing.large),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium),
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(Spacing.medium),
            ) {
                SheetHeader(
                    title = stringResource(wording.title, shown.title, shown.ownerName),
                    closeLabel = stringResource(R.string.action_close),
                    onClose = onDismiss,
                )
                Text(
                    text = boldName(stringResource(wording.sentence, shown.ownerName), shown.ownerName),
                    style = RecitTheme.typography.content300,
                    color = RecitTheme.colors.foregroundDefault,
                )
                FormTextField(
                    value = message,
                    onValueChange = { message = it },
                    label = stringResource(R.string.transaction_form_your_message_required),
                    singleLine = false,
                    minLines = 4,
                    modifier = Modifier.testTag("e2e.transactionRequest.message"),
                )
                Text(
                    text = stringResource(wording.messageHint),
                    style = RecitTheme.typography.footnote200,
                    color = RecitTheme.colors.foregroundSecondary,
                    modifier = Modifier.padding(horizontal = Spacing.small),
                )
            }
            PrimaryButton(
                text = stringResource(wording.submit),
                onClick = ::submit,
                enabled = TransactionRequestWording.canSubmit(message),
                isLoading = isSubmitting,
                modifier = Modifier.fillMaxWidth().testTag("e2e.transactionRequest.submit"),
            )
        }
    }
}

/** What the sheet reads of the copy: its title, its owner's name, and the wording of its type. */
private class RequestedCopy(row: ItemRow) {
    val title: String = row.title
    val ownerName: String = row.owner?.username.orEmpty()
    val wording: TransactionRequestWording? = TransactionRequestWording.of(row.item.transaction)
}

/** The sentence with the owner's name in bold, as iOS's `**%@**`. */
private fun boldName(sentence: String, name: String): AnnotatedString = buildAnnotatedString {
    val start: Int = sentence.lastIndexOf(name)
    if (name.isEmpty() || start < 0) {
        append(sentence)
        return@buildAnnotatedString
    }
    append(sentence.substring(0, start))
    withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(name) }
    append(sentence.substring(start + name.length))
}
