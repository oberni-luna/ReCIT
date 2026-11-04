package studio.lunabee.nouveaurecit.e2e

import android.app.Instrumentation
import android.graphics.Point
import android.graphics.Rect
import android.os.SystemClock
import android.view.InputDevice
import android.view.MotionEvent
import androidx.test.uiautomator.By
import androidx.test.uiautomator.BySelector
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.UiObject2
import androidx.test.uiautomator.Until
import java.io.File

/** A step's way of saying it could not do its job, in a sentence that goes straight into the report. */
class E2EFailure(message: String) : Exception(message)

/**
 * `E2EDriver`, Android side: the vocabulary the scenario is written in — [step], [waitFor], [tap],
 * [type], [scrollTo], [longPressDrag], [launch], [restartKeepingSession].
 *
 * **Nothing here fails the JUnit test.** A step that throws is recorded KO with its reason and the
 * run carries on, because the deliverable is a compte-rendu of the whole journey. `step(critical = true)`
 * marks the failures that make what follows meaningless — no session, no scanner — after which the
 * remaining steps are recorded `SKIP` rather than attempted against the wrong screen.
 *
 * The app is driven from outside, by UI Automator, the way XCUITest drives the iOS one: a Compose
 * `testTag` reaches it as a resource id (`testTagsAsResourceId` in `MainActivity`), and everything else
 * is found by the French the screen shows — the app has no other locale.
 */
class E2EDriver(private val instrumentation: Instrumentation, val report: E2EReport) {
    val device: UiDevice = UiDevice.getInstance(instrumentation)
    private var abandonedBecause: String? = null

    /** The barcodes handed to the scanner seam (`E2EHooks` in the app) at every launch. */
    var barcodes: List<String> = emptyList()

    val hasFailed: Boolean get() = abandonedBecause != null

    /** For working on the scenario: only the steps whose title holds this text are played, the others left out of the report. */
    var onlyStepsContaining: String? = null

    // ------------------------------------------------------------------------------------- steps

    /**
     * Runs one line of the report. [body] returns the detail — what it acted on — or throws
     * [E2EFailure] with the reason. Returns whether the step passed.
     */
    fun step(title: String, critical: Boolean = true, body: () -> String): Boolean {
        onlyStepsContaining?.let { only -> if (!title.contains(only)) return true }
        abandonedBecause?.let { reason ->
            report.record(title, "", E2EStatus.Skipped, "Non joué : $reason", 0.0, null)
            return false
        }
        val start: Long = SystemClock.elapsedRealtime()
        var detail = ""
        var message: String? = null
        try {
            detail = body()
        } catch (failure: E2EFailure) {
            message = failure.message
        } catch (error: Throwable) {
            message = "${error::class.simpleName} : ${error.message}"
        }
        // The app gone from the screen, or frozen, is the one thing worth saying over whatever the step thought.
        if (message != null && isNotResponding()) {
            message += " — l'app ne répond plus (ANR) : Android propose de la fermer."
        } else if (message != null && !isAppInForeground()) {
            message += " — l'app n'est plus à l'écran : elle a sans doute planté pendant cette étape."
        }
        val shot: File = report.screenshotFile(title)
        runCatching { device.waitForIdle(2_000) }
        val took: Boolean = runCatching { device.takeScreenshot(shot) }.getOrDefault(false)
        val seconds: Double = (SystemClock.elapsedRealtime() - start) / 1000.0
        report.record(title, detail, if (message == null) E2EStatus.Ok else E2EStatus.Ko, message, seconds, shot.takeIf { took })

        if (message != null) {
            if (critical) abandonedBecause = "« $title » a échoué"
            // A dead or frozen app is brought back on the session it saved, so the steps behind are played for real.
            if (isNotResponding()) runCatching { device.executeShellCommand("am force-stop $APP_PACKAGE") }
            if (!isAppInForeground()) runCatching { launch(reset = false) }
        }
        return message == null
    }

    /** A step the scenario chose not to play, for a reason worth reading. */
    fun skip(title: String, because: String) {
        report.record(title, "", E2EStatus.Skipped, because, 0.0, null)
    }

    // ------------------------------------------------------------------------------- the app itself

    /**
     * Starts the app. [reset] wipes its data first (`pm clear`): the session, the Room store, the
     * preferences — what an uninstall does on iOS, without the reinstall.
     */
    fun launch(reset: Boolean) {
        if (reset) {
            device.executeShellCommand("pm clear $APP_PACKAGE")
            // The scanner asks for the camera on entry even when it reads the seam's barcodes.
            device.executeShellCommand("pm grant $APP_PACKAGE android.permission.CAMERA")
        }
        // Through the shell: a runner in the background is not allowed to start another app's activity.
        val extras: String = if (barcodes.isEmpty()) "" else " --es $EXTRA_BARCODES ${barcodes.joinToString(",")}"
        val answer: String = device.executeShellCommand("am start -W --activity-clear-task -n $APP_PACKAGE/$APP_ACTIVITY$extras")
        if (answer.contains("Error")) throw E2EFailure("L'app n'a pas pu être lancée : ${answer.trim()}")
        if (!device.wait(Until.hasObject(By.pkg(APP_PACKAGE).depth(0)), LAUNCH_TIMEOUT)) {
            throw E2EFailure("L'app ne s'est pas affichée dans les ${LAUNCH_TIMEOUT / 1000} s après son lancement.")
        }
    }

    /** Kills the process — not a background, a kill — and starts it again on what it left on disk. */
    fun restartKeepingSession() {
        device.executeShellCommand("am force-stop $APP_PACKAGE")
        SystemClock.sleep(1_000)
        launch(reset = false)
    }

    fun isAppInForeground(): Boolean = runCatching { device.currentPackageName == APP_PACKAGE }.getOrDefault(false)

    /** Whether Android has put up « Ex-libris isn't responding » over the app. */
    fun isNotResponding(): Boolean =
        device.executeShellCommand("dumpsys window windows").lines()
            .any { it.contains("mCurrentFocus") && it.contains("Not Responding") && it.contains(APP_PACKAGE) }

    // ------------------------------------------------------------------------------------- finding

    fun find(selector: BySelector): UiObject2? = device.findObject(selector)

    fun findAll(selector: BySelector): List<UiObject2> = device.findObjects(selector)

    fun exists(selector: BySelector): Boolean = device.hasObject(selector)

    /** Waits for [selector] and returns it, or fails the step saying [what] never showed. */
    fun waitFor(selector: BySelector, what: String, timeout: Long = DEFAULT_TIMEOUT): UiObject2 =
        device.wait(Until.findObject(selector), timeout)
            ?: throw E2EFailure("« $what » n'est pas apparu en ${timeout / 1000} s.")

    /** Waits for whichever of [selectors] shows first and returns its index, or fails naming [what]. */
    fun waitForAny(what: String, timeout: Long = DEFAULT_TIMEOUT, vararg selectors: BySelector): Int {
        val deadline: Long = SystemClock.elapsedRealtime() + timeout
        while (SystemClock.elapsedRealtime() < deadline) {
            selectors.forEachIndexed { index, selector -> if (device.hasObject(selector)) return index }
            SystemClock.sleep(POLL_INTERVAL)
        }
        throw E2EFailure("$what : rien de ce qui était attendu n'est apparu en ${timeout / 1000} s.")
    }

    fun waitUntil(what: String, timeout: Long = DEFAULT_TIMEOUT, condition: () -> Boolean) {
        val deadline: Long = SystemClock.elapsedRealtime() + timeout
        while (SystemClock.elapsedRealtime() < deadline) {
            if (runCatching(condition).getOrDefault(false)) return
            SystemClock.sleep(POLL_INTERVAL)
        }
        throw E2EFailure("$what — toujours pas au bout de ${timeout / 1000} s.")
    }

    fun waitGone(selector: BySelector, what: String, timeout: Long = DEFAULT_TIMEOUT) {
        if (!device.wait(Until.gone(selector), timeout)) throw E2EFailure("« $what » est toujours là au bout de ${timeout / 1000} s.")
        // Everything is gone from a screen the app has left: that is no answer.
        if (!isAppInForeground()) throw E2EFailure("L'app a quitté l'écran au lieu de faire disparaître « $what ».")
    }

    /**
     * Whether something the system back would close — the keyboard, a menu, a dialog, a sheet — covers
     * the screen. Asked before pressing back to uncover a screen: a back with nothing to close, at a
     * tab's root, leaves the app.
     */
    fun isCovered(): Boolean {
        if (device.executeShellCommand("dumpsys input_method").contains("mInputShown=true")) return true
        if (exists(By.desc(SHEET_SCRIM))) return true
        // A menu or a dialog is a window of its own, smaller than the screen, and the only one UI Automator then reads.
        val root: Rect = find(By.pkg(APP_PACKAGE).depth(0))?.visibleBounds ?: return false
        return root.height() < device.displayHeight * 9 / 10
    }

    // ------------------------------------------------------------------------------------- acting

    fun tap(selector: BySelector, what: String, timeout: Long = DEFAULT_TIMEOUT) {
        waitFor(selector, what, timeout).click()
        device.waitForIdle(IDLE_TIMEOUT)
    }

    /**
     * Taps until [until] holds: a tap that lands while a screen is still settling is sometimes
     * swallowed, and the step would otherwise wait on a screen that is never coming.
     */
    fun tapUntil(selector: BySelector, what: String, timeout: Long = DEFAULT_TIMEOUT, until: () -> Boolean) {
        repeat(TAP_ATTEMPTS) {
            find(selector)?.let { runCatching { it.click() } } ?: waitFor(selector, what, timeout).click()
            val deadline: Long = SystemClock.elapsedRealtime() + timeout / TAP_ATTEMPTS
            while (SystemClock.elapsedRealtime() < deadline) {
                if (runCatching(until).getOrDefault(false)) return
                SystemClock.sleep(POLL_INTERVAL)
            }
        }
        throw E2EFailure("« $what » a été touché $TAP_ATTEMPTS fois, sans effet.")
    }

    /**
     * Replaces a field's text, through accessibility rather than the keyboard — which is never brought
     * up, so it never hides what the next tap is aimed at. Refuses anything that is not a field.
     */
    fun type(field: UiObject2, text: String, what: String) {
        if (field.className != EDIT_TEXT) throw E2EFailure("« $what » n'est pas un champ de saisie (${field.className}).")
        field.text = text
        device.waitForIdle(IDLE_TIMEOUT)
    }

    /** The [index]-th text field on screen, top to bottom. */
    fun textField(index: Int, what: String, timeout: Long = DEFAULT_TIMEOUT): UiObject2 {
        waitUntil("Le champ « $what »", timeout) { findAll(By.clazz(EDIT_TEXT)).size > index }
        return findAll(By.clazz(EDIT_TEXT)).sortedBy { it.visibleBounds.top }[index]
    }

    /** Swipes the screen's middle up until [selector] shows, at most [maxSwipes] times. */
    fun scrollTo(selector: BySelector, what: String, maxSwipes: Int = 8, area: Rect? = null): UiObject2 {
        repeat(maxSwipes + 1) {
            find(selector)?.let { return it }
            swipeUp(area)
        }
        throw E2EFailure("« $what » est introuvable, même en faisant défiler l'écran.")
    }

    fun swipeUp(area: Rect? = null) {
        val bounds: Rect = area ?: Rect(0, 0, device.displayWidth, device.displayHeight)
        val x: Int = bounds.centerX()
        device.swipe(x, bounds.top + bounds.height() * 3 / 4, x, bounds.top + bounds.height() / 3, SWIPE_STEPS)
        device.waitForIdle(IDLE_TIMEOUT)
    }

    fun swipeDown() {
        val x: Int = device.displayWidth / 2
        device.swipe(x, device.displayHeight / 3, x, device.displayHeight * 3 / 4, SWIPE_STEPS)
        device.waitForIdle(IDLE_TIMEOUT)
    }

    /**
     * The system back, then the time for the screen to go: Navigation 3 keeps the screen being left in
     * the tree for as long as its exit runs, and a check made meanwhile still finds its « Retour » —
     * one back too many, at a tab's root, leaves the app.
     */
    fun back() {
        device.pressBack()
        device.waitForIdle(IDLE_TIMEOUT)
        SystemClock.sleep(TRANSITION_MILLIS)
    }

    /**
     * Presses, holds still for [holdMillis] — long enough for `detectDragGesturesAfterLongPress` —
     * moves slowly to [to], holds again so the drop target registers the hover, and lets go. A plain
     * swipe would be read as a scroll and the book would never leave its panel.
     */
    fun longPressDrag(from: Point, to: Point, holdMillis: Long = 1_200, moveMillis: Long = 1_500, dropHoldMillis: Long = 1_000) {
        val downTime: Long = SystemClock.uptimeMillis()
        fun inject(action: Int, x: Float, y: Float) {
            val event: MotionEvent = MotionEvent.obtain(downTime, SystemClock.uptimeMillis(), action, x, y, 0)
            event.source = InputDevice.SOURCE_TOUCHSCREEN
            instrumentation.uiAutomation.injectInputEvent(event, true)
            event.recycle()
        }
        fun hold(x: Float, y: Float, millis: Long) {
            val end: Long = SystemClock.uptimeMillis() + millis
            while (SystemClock.uptimeMillis() < end) {
                SystemClock.sleep(FRAME_MILLIS)
                inject(MotionEvent.ACTION_MOVE, x, y)
            }
        }
        inject(MotionEvent.ACTION_DOWN, from.x.toFloat(), from.y.toFloat())
        hold(from.x.toFloat(), from.y.toFloat(), holdMillis)
        val frames: Int = (moveMillis / FRAME_MILLIS).toInt().coerceAtLeast(1)
        for (frame in 1..frames) {
            val progress: Float = frame.toFloat() / frames
            inject(
                MotionEvent.ACTION_MOVE,
                from.x + (to.x - from.x) * progress,
                from.y + (to.y - from.y) * progress,
            )
            SystemClock.sleep(FRAME_MILLIS)
        }
        hold(to.x.toFloat(), to.y.toFloat(), dropHoldMillis)
        inject(MotionEvent.ACTION_UP, to.x.toFloat(), to.y.toFloat())
        device.waitForIdle(IDLE_TIMEOUT)
    }

    companion object {
        const val APP_PACKAGE: String = "studio.lunabee.exlibris.android.dev"
        const val APP_ACTIVITY: String = "studio.lunabee.nouveaurecit.MainActivity"
        const val EXTRA_BARCODES: String = "e2e.barcodes"
        const val EDIT_TEXT: String = "android.widget.EditText"
        const val SHEET_SCRIM: String = "Close sheet"

        const val DEFAULT_TIMEOUT: Long = 15_000
        const val NETWORK_TIMEOUT: Long = 30_000
        private const val LAUNCH_TIMEOUT: Long = 20_000
        private const val IDLE_TIMEOUT: Long = 1_500
        private const val POLL_INTERVAL: Long = 250
        private const val TAP_ATTEMPTS: Int = 3
        private const val SWIPE_STEPS: Int = 25
        private const val FRAME_MILLIS: Long = 16
        private const val TRANSITION_MILLIS: Long = 1_000
    }
}
