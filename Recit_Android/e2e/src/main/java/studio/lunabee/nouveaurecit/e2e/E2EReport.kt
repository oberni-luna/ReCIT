package studio.lunabee.nouveaurecit.e2e

import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.Normalizer
import java.time.Instant
import java.time.temporal.ChronoUnit

/** How a step ended — the same three words as iOS, so `scripts/e2e_report.py` reads both. */
enum class E2EStatus(val wire: String) {
    Ok("OK"),
    Ko("KO"),

    /** Never attempted, because something it depended on failed. Reported rather than dropped. */
    Skipped("SKIP"),
}

/** One line of the report. */
data class E2EStep(
    val index: Int,
    val title: String,
    /** What the step acted on, in the user's terms — the book that was added, the shelf that was named. */
    val detail: String,
    val status: E2EStatus,
    val message: String?,
    val screenshot: String?,
    val durationSeconds: Double,
)

/**
 * `E2EReport`, Android side: `report.json` and one PNG per step, in the shape the iOS scenario writes,
 * so the same `scripts/e2e_report.py` renders both.
 *
 * **It is rewritten after every step**, not at the end: a run against the real server can hang or
 * crash halfway, and the runs that do are the ones whose report is most wanted.
 *
 * It lands in the runner's external files directory — `/sdcard/Android/data/<runner>/files/e2e-report`
 * — which `scripts/e2e-android.sh` pulls with `adb pull`.
 */
class E2EReport(
    val directory: File,
    private val scenario: String,
    private val device: String,
    private val account: String,
) {
    private val startedAt: Instant = Instant.now()
    private val steps: MutableList<E2EStep> = mutableListOf()

    init {
        // Cleared rather than added to: yesterday's screenshots between today's steps would be read as today's.
        directory.deleteRecursively()
        directory.mkdirs()
    }

    val nextIndex: Int get() = steps.size + 1

    fun screenshotFile(title: String): File = File(directory, "%02d-%s.png".format(nextIndex, slug(title)))

    fun record(title: String, detail: String, status: E2EStatus, message: String?, durationSeconds: Double, screenshot: File?) {
        steps += E2EStep(
            index = nextIndex,
            title = title,
            detail = detail,
            status = status,
            message = message,
            screenshot = screenshot?.takeIf(File::exists)?.name,
            durationSeconds = Math.round(durationSeconds * 100) / 100.0,
        )
        flush(finished = false)
    }

    fun finish() = flush(finished = true)

    private fun flush(finished: Boolean) {
        val json: JSONObject = JSONObject()
            .put("scenario", scenario)
            .put("startedAt", startedAt.truncatedTo(ChronoUnit.SECONDS).toString())
            .put("finishedAt", if (finished) Instant.now().truncatedTo(ChronoUnit.SECONDS).toString() else JSONObject.NULL)
            .put("device", device)
            .put("account", account)
            .put("okCount", steps.count { it.status == E2EStatus.Ok })
            .put("koCount", steps.count { it.status == E2EStatus.Ko })
            .put("skippedCount", steps.count { it.status == E2EStatus.Skipped })
            .put(
                "steps",
                JSONArray(
                    steps.map { step ->
                        JSONObject()
                            .put("index", step.index)
                            .put("title", step.title)
                            .put("detail", step.detail)
                            .put("status", step.status.wire)
                            .put("message", step.message ?: JSONObject.NULL)
                            .put("screenshot", step.screenshot ?: JSONObject.NULL)
                            .put("durationSeconds", step.durationSeconds)
                    },
                ),
            )
        File(directory, "report.json").writeText(json.toString(2))
    }

    private fun slug(title: String): String = Normalizer.normalize(title, Normalizer.Form.NFD)
        .replace(Regex("\\p{M}"), "")
        .lowercase()
        .split(Regex("[^a-z0-9]+"))
        .filter(String::isNotEmpty)
        .take(6)
        .joinToString("-")
}
