package studio.lunabee.nouveaurecit.data.inventory

import kotlinx.coroutines.Job
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import studio.lunabee.nouveaurecit.data.OptimisticRunner
import studio.lunabee.nouveaurecit.network.ApiService
import java.util.concurrent.ConcurrentHashMap

/**
 * `InventoryModel.updateItemTextOptimistic(item:attribute:text:modelContext:)`: the Commentaire and the
 * Note privée, written the same way — stored at once, sent through `bulk-update`, put back on a refusal.
 *
 * Writes of one text on one book leave one after the other (`lastTextWrites`): each request waits for
 * the previous one's answer, so an older text never lands last. Only the request waits; the store
 * takes the new text at once. A refusal puts back the last text the server accepted, and only while the
 * stored text is still the refused one — autosave queues several writes, and a newer text must survive an
 * older failure.
 */
class InventoryItemTextWriter(
    private val api: ApiService,
    private val store: InventoryItemTextStore,
    private val runner: OptimisticRunner,
) {
    private val lastWrites: MutableMap<TextWrite, Job> = mutableMapOf()
    private val lastWritesLock: Mutex = Mutex()
    private val acceptedTexts: MutableMap<TextWrite, String> = ConcurrentHashMap()

    /**
     * The request's job, or `null` when nothing was written: [text] already stored, or the item gone
     * from the store.
     */
    suspend fun write(itemId: String, attribute: InventoryItemTextAttribute, text: String): Job? =
        lastWritesLock.withLock {
            val previous: String = store.text(itemId, attribute) ?: return null
            if (previous == text) return null
            val key: TextWrite = TextWrite(itemId, attribute)
            val earlierWrite: Job? = lastWrites[key]
            if (earlierWrite?.isActive != true) acceptedTexts[key] = previous
            val job: Job = runner.run(
                apply = { store.setText(itemId, attribute, text) },
                revert = {
                    if (store.text(itemId, attribute) == text) store.setText(itemId, attribute, acceptedTexts.getValue(key))
                },
                request = {
                    earlierWrite?.join()
                    api.bulkUpdateItem(itemId, attribute.raw, text)
                },
                reconcile = { acceptedTexts[key] = text },
                stillThere = { store.text(itemId, attribute) != null },
            )
            lastWrites[key] = job
            job
        }

    private data class TextWrite(val itemId: String, val attribute: InventoryItemTextAttribute)
}
